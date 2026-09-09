---
name: flutter-gitea-apk-release
description: Use when a Flutter repo needs installable signed Android builds - setting up release signing, a keystore, product flavours, 1Password-sourced build config, local run and build-and-install scripts, or a Gitea Actions workflow that publishes an APK on a version tag.
---

# Flutter signed APK releases via Gitea Actions and 1Password

## Overview

Pushing a `v*` tag builds a signed release APK and attaches it to a Gitea release. Secrets never enter the repo or the Gitea secret store beyond one token.

Architecture:

- Gradle reads signing credentials from `android/key.properties`.
- Committed `*.tpl` files hold `op://` paths, never values. `op inject` materialises the real files identically on your machine and on the runner.
- One Gitea repository secret, `OP_SERVICE_ACCOUNT_TOKEN`, lets the runner reach the vault. `GITEA_TOKEN` is injected by the runner already.
- `pubspec.yaml`'s `version:` is the source of truth. The local build script writes it and tags it, and the workflow refuses to build a tag that disagrees.

Reference implementations: `uprise-budget-tracker/everything_app`, spec and plan under `docs/superpowers/specs/2026-07-28-gitea-apk-release-pipeline-design.md`, and `paperlist`, which carries the same `scripts/` plus a notarised macOS release.

## Substitute these per project

| Placeholder | Uprise value | Where it appears |
| --- | --- | --- |
| `<app>` | `everything-app` | vault item prefix, APK filename |
| `<App>` | `Uprise` | launcher name per flavour |
| `<vault>` | `infra-ci` | every `op://` reference |
| `<flavour>` | `production` | build args, APK output path |
| `<env keys>` | six keys in `env/example.json` | both templates, both vault items |

## Decide before you start

**Flavours.** A repo straight off the brick template has none. Step 1 adds `staging`, `profiling` and `production`, matching the reference. Skip it only if the app will never carry two installs side by side, in which case drop `--flavor` from every command below and read the APK at `build/app/outputs/flutter-apk/app-release.apk`.

**Application ID.** The flavour suffix appends to whatever `applicationId` is already set. Check it reads the way you want before a keystore signs anything, because the ID is locked once you publish. A repo can carry a doubled name like `dev.calcode.paperlist.paperlist`, which comes from answering a scaffolder's organisation prompt with a full bundle id rather than the reverse-domain prefix alone: `flutter create` composes the id as `<org>.<project-name>`. The `based_flutter` brick warns when it spots this, but only warns, so read the generated `applicationId` yourself before step 5. The keystore's certificate subject (step 5's `-genkey` prompts) is unrelated to `applicationId` — Android never checks it, so a mismatched or generic CN there is cosmetic, not a reason to regenerate.

**Signing fallback.** Two options in `buildTypes`:

```kotlin
signingConfig = signingConfigs.findByName("release") ?: signingConfigs.getByName("debug")
```

falls back to the debug key so `flutter run --release` works on a machine with no keystore. The cost is a silent failure mode: a missing `key.properties` in CI yields a debug-signed APK instead of an error. Uprise shipped the strict form instead:

```kotlin
signingConfig = signingConfigs.getByName("release")
```

which fails the build loudly when the keystore is absent. Pick the strict form unless someone needs local release builds.

## Steps

### 1. Product flavours

Flavours are Android-only here. The Dart side reads its config from `--dart-define-from-file`, so no second `main_*.dart` entrypoint and no `dart-define` of a flavour name.

AGP 9 disables `resValue` generation by default, and the flavours below fail Gradle sync with "contains custom resource values, but the feature is disabled" without this opt-in. AGP 8 needs nothing: `everything_app` runs 8.11 with three `resValue` flavours and no opt-in, while `paperlist` runs 9.0 and needs it. Adding it on 8 is harmless, so add it either way. In `android/app/build.gradle.kts`, inside the `android` block:

```kotlin
    buildFeatures {
        resValues = true
    }
```

Then, inside the `android` block after `defaultConfig`:

```kotlin
    flavorDimensions += "default"

    productFlavors {
        create("staging") {
            dimension = "default"
            resValue(
                type = "string",
                name = "app_name",
                value = "<App> (staging)"
            )
            applicationIdSuffix = ".staging"
        }
        // Named "profiling" because a flavour name cannot collide with a build
        // type, and Flutter defines a `profile` type.
        create("profiling") {
            dimension = "default"
            resValue(
                type = "string",
                name = "app_name",
                value = "<App> (profiling)"
            )
            applicationIdSuffix = ".profiling"
        }
        create("production") {
            dimension = "default"
            resValue(
                type = "string",
                name = "app_name",
                value = "<App>"
            )
            applicationIdSuffix = ".production"
        }
    }
```

The suffixes are what let all three builds sit on one device at once. The `resValue` entries give each a distinct launcher name, so you can tell them apart. `profiling` runs off the staging backend and exists so a profile-mode build can sit beside the debug one rather than replacing it.

In `android/app/src/main/AndroidManifest.xml`, swap the hardcoded label:

```xml
        android:label="@string/app_name"
```

`resValue` generates that string resource per flavour. If `android/app/src/main/res/values/strings.xml` already defines `app_name`, delete that entry or the build fails on a duplicate resource.

The flavours all declare the same auth callback scheme in the manifest, so a device carrying more than one shows a chooser when the OAuth redirect fires. The reference app lives with it. Splitting the scheme means a per-flavour manifest and matching redirect URIs in both vault items.

From here every `flutter run` and `flutter build` needs a `--flavor`. Without one, Gradle fails with no default variant. Update `CLAUDE.md` so nobody rediscovers that — create the file if the repo doesn't have one yet.

Verify:

```fish
fvm flutter build apk --debug --flavor staging
```

The APK lands at `build/app/outputs/flutter-apk/app-staging-debug.apk`. Sideload it alongside a production build if you want to confirm the suffixes hold.

### 2. Gradle signing config

In `android/app/build.gradle.kts`, add the import above `plugins` (Kotlin DSL requires imports at the very top):

```kotlin
import java.util.Properties
```

Above the `android` block:

```kotlin
val keystoreProperties = Properties().apply {
    val f = rootProject.file("key.properties")
    if (f.exists()) f.inputStream().use { load(it) }
}
```

`rootProject` here is `android/`, so this reads `android/key.properties`.

Replace the stock `buildTypes` block, TODO comments and all:

```kotlin
    signingConfigs {
        if (keystoreProperties.containsKey("storeFile")) {
            create("release") {
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
```

`file()` inside the app module resolves against `android/app/`, so `storeFile=upload-keystore.jks` finds `android/app/upload-keystore.jks`.

### 3. Gitignore negation

`.gitignore` carries `/env/*.json`, which swallows `env/production.tpl.json` with no error. One line fixes it:

```
!/env/*.tpl.json
```

Recent `based_flutter` scaffolds already ship that line. Read the file before adding a duplicate.

Add nothing for `key.properties` or `*.jks`. Flutter's stock `android/.gitignore` already covers `key.properties`, `**/*.keystore` and `**/*.jks`, and a nested `.gitignore` outranks the root one. Its `key.properties` pattern matches that basename only, so `android/key.properties.tpl` stays tracked.

Verify:

```fish
git check-ignore -v env/production.tpl.json android/key.properties android/app/upload-keystore.jks
```

All three paths print a line. The first must carry the leading `!`, which is what marks it kept. An empty result is a failure, not a pass: `check-ignore -v` reports negations too.

### 4. Templates

`env/production.tpl.json`, one line per key in `env/example.json`:

```json
{
  "API_BASE_URL": "op://<vault>/<app>-env-production/API_BASE_URL",
  "LOGTO_ENDPOINT": "op://<vault>/<app>-env-production/LOGTO_ENDPOINT"
}
```

`env/staging.tpl.json` is identical but for the item segment. It exists so a fresh worktree can generate its own `env/env.json` instead of symlinking one in.

`android/key.properties.tpl`:

```
storeFile=upload-keystore.jks
storePassword=op://<vault>/<app>-android-signing/store_password
keyAlias=op://<vault>/<app>-android-signing/key_alias
keyPassword=op://<vault>/<app>-android-signing/key_password
```

`op inject` passes non-reference lines through untouched, so `storeFile` needs no vault field.

Verify the templates are tracked and the keys line up:

```fish
git status --porcelain env/ android/key.properties.tpl
diff (python3 -c "import json;print('\n'.join(sorted(json.load(open('env/example.json')))))" | psub) (python3 -c "import json;print('\n'.join(sorted(json.load(open('env/production.tpl.json')))))" | psub)
```

Three `??` lines, then no diff output. A mistyped key surfaces at runtime as a missing `--dart-define`, not as a build error.

### 5. Keystore

Run once, on a machine with a JDK:

```fish
mkdir -p ~/.config/keystores/<app>
keytool -genkey -v -keystore ~/.config/keystores/<app>/upload-keystore.jks -storetype JKS \
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Record the CN you enter. Step 10 checks the APK certificate against it.

### 6. Vault

Create a vault holding only these three items. Give the service account read-only access to this vault and nothing else: anyone who can push a workflow file to the repo can print whatever that token reads.

`<app>-android-signing`:

| Field label | Type | Value |
| --- | --- | --- |
| `store_password` | password | from step 5 |
| `key_alias` | text | `upload` |
| `key_password` | password | from step 5 |

Attach the `.jks` to the same item. The attachment filename must be exactly `upload-keystore.jks`, because that string is the last segment of the `op://` reference in the workflow.

`<app>-env-production` and `<app>-env-staging`: one text field per env key, labels matching `env/example.json` exactly.

Then add `OP_SERVICE_ACCOUNT_TOKEN` under repository Settings, Actions, Secrets in Gitea.

Verify every reference resolves before you go near CI:

```fish
op read "op://<vault>/<app>-android-signing/key_alias"
op inject -i env/production.tpl.json -o /tmp/prod-check.json
op inject -i env/staging.tpl.json -o /tmp/stg-check.json
op inject -i android/key.properties.tpl -o /tmp/key-check.properties
grep -l 'op://' /tmp/prod-check.json /tmp/stg-check.json /tmp/key-check.properties
op read "op://<vault>/<app>-android-signing/upload-keystore.jks" --out-file /tmp/ks-check.jks
keytool -list -keystore /tmp/ks-check.jks
rm /tmp/prod-check.json /tmp/stg-check.json /tmp/key-check.properties /tmp/ks-check.jks
```

Expected: `upload`, no output from `grep`, one keystore entry aliased `upload`. A file listed by `grep` still holds an unresolved reference, meaning a field label does not match.

Delete the local keystore only after both checks pass. The vault becomes the only copy, so confirm your 1Password account recovery covers it first. Losing this key after a store release means no update can ever ship under that application ID.

### 7. Workflow

`.gitea/workflows/release-apk.yaml`:

```yaml
name: Release APK

on:
  push:
    tags: ["v*"]

env:
  OP_CLI_VERSION: "2.38.1"

jobs:
  build:
    runs-on: ubuntu-latest
    timeout-minutes: 30
    container:
      image: ghcr.io/cirruslabs/android-sdk:36-ndk

    steps:
      - name: Install Node.js and jq
        run: |
          curl -fsSL https://deb.nodesource.com/setup_24.x | bash -
          apt-get install -y nodejs jq

      - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1

      - name: Resolve version
        env:
          TAG: ${{ gitea.ref_name }}
        run: |
          VERSION=$(awk '/^version:/{print $2; exit}' pubspec.yaml)
          if [ "$VERSION" != "${TAG#v}" ]; then
            echo "Tag ${TAG} does not match pubspec version ${VERSION}" >&2
            exit 1
          fi
          echo "BUILD_NAME=${VERSION%+*}" >> "$GITHUB_ENV"
          echo "BUILD_NUMBER=${VERSION#*+}" >> "$GITHUB_ENV"
          echo "APK_NAME=<app>-v${VERSION/+/-}.apk" >> "$GITHUB_ENV"

      - uses: subosito/flutter-action@1a449444c387b1966244ae4d4f8c696479add0b2 # v2.23.0
        id: flutter
        with:
          flutter-version-file: .fvmrc
          channel: stable
          cache: true

      - name: Trust Flutter SDK git directory
        env:
          SDK: ${{ steps.flutter.outputs.CACHE-PATH }}
        run: git config --global --add safe.directory "$SDK/flutter"

      - name: Install 1Password CLI
        run: |
          curl -sSfLo /tmp/op.zip \
            "https://cache.agilebits.com/dist/1P/op2/pkg/v${OP_CLI_VERSION}/op_linux_amd64_v${OP_CLI_VERSION}.zip"
          unzip -o /tmp/op.zip op -d /usr/local/bin
          op --version

      - name: Materialise secrets
        env:
          OP_SERVICE_ACCOUNT_TOKEN: ${{ secrets.OP_SERVICE_ACCOUNT_TOKEN }}
        run: |
          op inject -i env/production.tpl.json -o env/env.json
          op inject -i android/key.properties.tpl -o android/key.properties
          op read "op://<vault>/<app>-android-signing/upload-keystore.jks" \
            --out-file android/app/upload-keystore.jks

      - run: flutter pub get
      - run: flutter analyze
      - run: flutter test

      - name: Build APK
        run: |
          flutter build apk --release \
            --flavor <flavour> \
            --dart-define-from-file=env/env.json \
            --build-name="${BUILD_NAME}" \
            --build-number="${BUILD_NUMBER}"

      - name: Name the artifact
        run: |
          mv build/app/outputs/flutter-apk/app-<flavour>-release.apk "${APK_NAME}"

      - uses: akkuman/gitea-release-action@b8d9144f302c68610911db1aaf722708d5c02d94 # v1.3.6
        with:
          token: ${{ secrets.GITEA_TOKEN }}
          files: <app>-*.apk
```

Why each odd bit is there, all of it learned from failed runs:

| Line | Reason |
| --- | --- |
| Resolve version, before the SDK setup | A tag that disagrees with `pubspec.yaml` fails in seconds rather than after a full build. `${VERSION/+/-}` because a `+` in a filename becomes a space in the download URL. |
| Node.js install, before checkout | The android-sdk image ships no Node. Gitea runs JavaScript actions with it, so `actions/checkout` fails without this step. |
| `jq` alongside Node | flutter-action's `setup.sh` parses `.fvmrc` with `jq` and aborts with "jq not found" if it is absent. The image ships none. |
| `flutter-version-file: .fvmrc` | A hardcoded `flutter-version` drifts from `.fvmrc` the moment either moves, and nothing catches it: CI keeps building green against an SDK the project no longer pins. Reading the file makes drift impossible. |
| `safe.directory` for the Flutter SDK | The SDK is installed as a different user than the one running the build. Git refuses to read it and `flutter` fails on version detection. The path comes from the action's `CACHE-PATH` output, which is the only version-independent way to name it. |
| Pinned action SHAs | Gitea resolves actions through a mirror. A moving tag can hand you a different action than the one you reviewed. |
| `timeout-minutes: 30` | A hung Gradle download otherwise burns runner time until the default cap. |
| `op` CLI pinned | Only some versions resolve at the `cache.agilebits.com` zip path. 2.38.1 works; check the URL yourself before choosing another. |
| Flutter installed separately, not baked into the image | `ghcr.io/cirruslabs/flutter` publishes no tag for every patch. Installing the SDK keeps `.fvmrc` authoritative. |
| Token via `env:`, never inline `${{ }}` in `run:` | Inline interpolation splices the value into script text, where a stray character breaks parsing or injects shell. |
| NDK image variant | `build.gradle.kts` references `flutter.ndkVersion`. |
| No `build_runner` step | Generated `.g.dart`, `.freezed.dart` and `.gr.dart` files are committed. Add a codegen step only if that stops being true. |

### 8. Local usage

Replace any "symlink `env/env.json` into the worktree" instruction in `CLAUDE.md` with:

```fish
op inject -i env/staging.tpl.json -o env/env.json
```

A local signed release build also needs:

```fish
op read "op://<vault>/<app>-android-signing/upload-keystore.jks" --out-file android/app/upload-keystore.jks
op inject -i android/key.properties.tpl -o android/key.properties
```

These use your desktop 1Password session. No service account token involved. Step 9 wraps all of it in three files, which is what you want day to day.

### 9. Local scripts

Three files ship alongside this skill, in its `scripts/` directory. Copy all three in **unedited**. They name no app, vault or flavour, because `lib.sh` derives those at runtime:

```fish
mkdir -p scripts
cp ~/.claude/skills/flutter-gitea-apk-release/scripts/{lib.sh,run.sh,build-apk.sh} scripts/
chmod +x scripts/run.sh scripts/build-apk.sh
```

The split is long-lived against one-shot, which keeps `run.sh` off limits to an agent as a whole file rather than depending on an argument:

| Command | Mode | Env | Signing | Version and tag |
| --- | --- | --- | --- | --- |
| `run.sh` or `run.sh staging` | debug | staging | debug | no |
| `run.sh profiling` | profile | staging | debug | no |
| `build-apk.sh staging` | debug | staging | debug | no |
| `build-apk.sh profiling` | profile | staging | debug | no |
| `build-apk.sh production` | release | production | upload key | yes |

Each flavour has one build mode worth shipping, so the mode follows the flavour and never needs a flag of its own. Only `production` reads the keystore, because the `release` build type is the only one carrying a signing config. Every `build-apk.sh` run copies its APK to `<share>/<app>/<flavour>` when the share is mounted, and installs unless you pass `--no-install`.

`lib.sh` is sourced by the other two and holds what they share. What it derives, and from where:

| Value | Source |
| --- | --- |
| App name | `name:` in `pubspec.yaml`, underscores to hyphens, which is what the vault items and APK filenames use. A macOS build needs `PRODUCT_NAME` in `AppInfo.xcconfig` to match that converted form |
| Base `applicationId` | `applicationId` in `android/app/build.gradle.kts`, plus `.<flavour>` per step 1's suffix convention |
| Keystore vault item | the `op://` path already in `android/key.properties.tpl` |
| Artifacts share | hardcoded `/mnt/code-artifacts`, since the share belongs to the machine |

`run.sh [staging|profiling]` regenerates `env/env.json`, resolves the attached adb device and runs. `build-apk.sh <flavour> [version-name] [--no-install]` materialises the secrets that flavour needs, builds, installs, copies the APK to the share, and for production prints the signing certificate and records the version.

**One version scheme, local and CI.** `pubspec.yaml` is the record of the last release. `build-apk.sh production` reads it, reads the `versionCode` already installed on the device, takes whichever is further ahead and adds one, then writes the result back to pubspec, commits it and tags `v<name>+<number>`. All of that runs after the build and the install have both succeeded, so a failed run records nothing. It consults the device because Android refuses to install a downgrade. Push with `git push --follow-tags`. `--no-install` skips the pubspec write and the tag, since a build nobody installed is not a release.

The scripts keep to POSIX flags (`awk` and `sed -n` over `grep -oP`, a temp file over `sed -i`), so they run on macOS as well as Linux. `verify_signature` needs `ANDROID_HOME` pointing at an SDK with build-tools, because `apksigner` reads the v2 and v3 signatures that `keytool -printcert -jarfile` cannot see.

### 10. First release and verify

The first release comes from the script rather than a hand-cut tag, because step 7 checks the tag against `pubspec.yaml`:

```fish
./scripts/build-apk.sh production 0.1.0
git push --follow-tags
```

The build number lands one above whatever `flutter create` left in pubspec, so the tag reads `v0.1.0+2` and the release asset carries the same pair with the `+` swapped for a `-`.

Then download the APK from the release page and read its certificate:

```fish
keytool -printcert -jarfile <app>-v0.1.0-*.apk
```

Without a JDK:

```fish
unzip -p <app>-v0.1.0-*.apk 'META-INF/*.RSA' | openssl pkcs7 -inform DER -print_certs -text -noout | grep -A1 'Subject:'
```

Expected: the CN from step 5. `CN=Android Debug` means Gradle took the fallback path and `key.properties` was never written.

Install it and confirm it reaches the sign-in screen. That proves `env/env.json` carried real values rather than empty strings.

## Failure symptoms

| Symptom | Cause |
| --- | --- |
| Gradle picks no variant | A `flutter` command is missing `--flavor` |
| Duplicate resource `app_name` | `strings.xml` still defines it alongside the `resValue` entries |
| Job never starts, `container:` unsupported | act_runner is not Docker-backed |
| flutter-action prints "jq not found" | The jq install is missing from the Node step |
| `actions/checkout` fails immediately | Node install step missing or ordered after checkout |
| `flutter` fails on version detection | `safe.directory` step missing |
| Cannot resolve an action | Gitea's action mirror does not carry it |
| `op` authentication error | Wrong token, expired token, or the vault sits outside the service account's scope |
| `op inject` leaves `op://` strings | Field label mismatch, which step 6's `grep` should have caught |
| Gradle `Keystore file not found` | Attachment filename is not exactly `upload-keystore.jks` |
| APK reports `CN=Android Debug` | `key.properties` absent and the Gradle fallback swallowed it |
| Workflow fails on "does not match pubspec version" | A tag was cut by hand rather than by `build-apk.sh production`, or the pubspec commit was never pushed |
| `build-apk.sh` restarts the version code at 1 | `applicationId` in Gradle no longer matches the installed package, so the `dumpsys` lookup returns nothing |
| `lib.sh` says "No pubspec name or applicationId" | It ran outside the repo root, or `applicationId` is assigned through a variable rather than a literal string |

## Out of scope

iOS builds and signing, staging APKs from CI, Play Store upload, a codegen-drift check.
