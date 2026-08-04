---
name: flutter-gitea-apk-release
description: Use when a Flutter repo needs installable signed Android builds out of CI - setting up release signing, a keystore, 1Password-sourced build config, or a Gitea Actions workflow that publishes an APK on a version tag.
---

# Flutter signed APK releases via Gitea Actions and 1Password

## Overview

Pushing a `v*` tag builds a signed release APK and attaches it to a Gitea release. Secrets never enter the repo or the Gitea secret store beyond one token.

Architecture:

- Gradle reads signing credentials from `android/key.properties`.
- Committed `*.tpl` files hold `op://` paths, never values. `op inject` materialises the real files identically on your machine and on the runner.
- One Gitea repository secret, `OP_SERVICE_ACCOUNT_TOKEN`, lets the runner reach the vault. `GITEA_TOKEN` is injected by the runner already.
- Version name comes from the tag, version code from `gitea.run_number`. `pubspec.yaml` never changes for a release.

Reference implementation: `uprise-budget-tracker/everything_app`, spec and plan under `docs/superpowers/specs/2026-07-28-gitea-apk-release-pipeline-design.md`.

## Substitute these per project

| Placeholder | Uprise value | Where it appears |
| --- | --- | --- |
| `<app>` | `everything-app` | vault item prefix, APK filename |
| `<App>` | `Uprise` | launcher name per flavour |
| `<vault>` | `infra-ci` | every `op://` reference |
| `<flutter>` | `3.44.6` | workflow, must match `.fvmrc` |
| `<flavour>` | `production` | build args, APK output path |
| `<env keys>` | six keys in `env/example.json` | both templates, both vault items |

## Decide before you start

**Flavours.** A repo straight off the brick template has none. Step 1 adds `staging` and `production`, matching the reference. Skip it only if the app will never carry two installs side by side, in which case drop `--flavor` from every command below and read the APK at `build/app/outputs/flutter-apk/app-release.apk`.

**Application ID.** The flavour suffix appends to whatever `applicationId` is already set. Check it reads the way you want before a keystore signs anything, because the ID is locked once you publish. A brick-scaffolded repo can carry a doubled name like `dev.calcode.paperlist.paperlist`.

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

In `android/app/build.gradle.kts`, inside the `android` block after `defaultConfig`:

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

The suffixes are what let both builds sit on one device. The `resValue` entries give each a distinct launcher name, so you can tell them apart.

In `android/app/src/main/AndroidManifest.xml`, swap the hardcoded label:

```xml
        android:label="@string/app_name"
```

`resValue` generates that string resource per flavour. If `android/app/src/main/res/values/strings.xml` already defines `app_name`, delete that entry or the build fails on a duplicate resource.

Both flavours still declare the same auth callback scheme in the manifest, so a device carrying both shows a chooser when the OAuth redirect fires. The reference app lives with it. Splitting the scheme means a per-flavour manifest and matching redirect URIs in both vault items.

From here every `flutter run` and `flutter build` needs `--flavor staging` or `--flavor production`. Without one, Gradle fails with no default variant. Update `CLAUDE.md` so nobody rediscovers that.

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

`.gitignore` carries `/env/*.json`, which swallows `env/production.tpl.json` with no error. Add one line:

```
!/env/*.tpl.json
```

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

Record the CN you enter. Step 9 checks the APK certificate against it.

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
      - name: Install Node.js
        run: |
          curl -fsSL https://deb.nodesource.com/setup_24.x | bash -
          apt-get install -y nodejs

      - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1

      - uses: subosito/flutter-action@1a449444c387b1966244ae4d4f8c696479add0b2 # v2.23.0
        with:
          flutter-version: "<flutter>"
          channel: stable
          cache: true

      - name: Trust Flutter SDK git directory
        run: git config --global --add safe.directory /opt/hostedtoolcache/flutter/stable-<flutter>-x64/flutter

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
        env:
          TAG: ${{ gitea.ref_name }}
        run: |
          flutter build apk --release \
            --flavor <flavour> \
            --dart-define-from-file=env/env.json \
            --build-name="${TAG#v}" \
            --build-number="${{ gitea.run_number }}"

      - name: Name the artifact
        env:
          TAG: ${{ gitea.ref_name }}
        run: |
          mv build/app/outputs/flutter-apk/app-<flavour>-release.apk \
             "<app>-${TAG}.apk"

      - uses: akkuman/gitea-release-action@b8d9144f302c68610911db1aaf722708d5c02d94 # v1.3.6
        with:
          token: ${{ secrets.GITEA_TOKEN }}
          files: <app>-*.apk
```

Why each odd bit is there, all of it learned from failed runs:

| Line | Reason |
| --- | --- |
| Node.js install, before checkout | The android-sdk image ships no Node. Gitea runs JavaScript actions with it, so `actions/checkout` fails without this step. |
| `safe.directory` for the Flutter SDK | The SDK is installed as a different user than the one running the build. Git refuses to read it and `flutter` fails on version detection. |
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

These use your desktop 1Password session. No service account token involved.

### 9. Tag and verify

```fish
git tag v0.1.0
git push origin v0.1.0
```

Then download the APK from the release page and read its certificate:

```fish
keytool -printcert -jarfile <app>-v0.1.0.apk
```

Without a JDK:

```fish
unzip -p <app>-v0.1.0.apk 'META-INF/*.RSA' | openssl pkcs7 -inform DER -print_certs -text -noout | grep -A1 'Subject:'
```

Expected: the CN from step 5. `CN=Android Debug` means Gradle took the fallback path and `key.properties` was never written.

Install it and confirm it reaches the sign-in screen. That proves `env/env.json` carried real values rather than empty strings.

## Failure symptoms

| Symptom | Cause |
| --- | --- |
| Gradle picks no variant | A `flutter` command is missing `--flavor` |
| Duplicate resource `app_name` | `strings.xml` still defines it alongside the `resValue` entries |
| Job never starts, `container:` unsupported | act_runner is not Docker-backed |
| `actions/checkout` fails immediately | Node install step missing or ordered after checkout |
| `flutter` fails on version detection | `safe.directory` step missing |
| Cannot resolve an action | Gitea's action mirror does not carry it |
| `op` authentication error | Wrong token, expired token, or the vault sits outside the service account's scope |
| `op inject` leaves `op://` strings | Field label mismatch, which step 6's `grep` should have caught |
| Gradle `Keystore file not found` | Attachment filename is not exactly `upload-keystore.jks` |
| APK reports `CN=Android Debug` | `key.properties` absent and the Gradle fallback swallowed it |

## Out of scope

iOS builds and signing, staging APKs from CI, Play Store upload, a codegen-drift check.
