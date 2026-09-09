#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
source scripts/lib.sh

usage() { echo "usage: $0 <staging|profiling|production> [version-name] [--no-install]" >&2; exit 1; }

install=1
args=()
for arg in "$@"; do
  case "$arg" in
    --no-install) install=0 ;;
    *) args+=("$arg") ;;
  esac
done

case "${args[0]:-}" in
  staging) flavour=staging; mode=debug; env=staging ;;
  profiling) flavour=profiling; mode=profile; env=staging ;;
  production) flavour=production; mode=release; env=production ;;
  *) usage ;;
esac

version=$(pubspec_version)
# Only the build number moves on its own. Pass a version to change that too.
build_name="${args[1]:-${version%+*}}"
pubspec_number="${version#*+}"

serial=$(adb_serial)
[[ -n "$serial" || "$install" == 0 ]] || die_no_device

# Android refuses a downgrade install, so take whichever count is further along.
device_number=0
if [[ -n "$serial" ]]; then
  device_number=$(installed_version_code "$serial" "$flavour")
  device_number="${device_number:-0}"
fi
build_number=$(( (pubspec_number > device_number ? pubspec_number : device_number) + 1 ))

op inject -f -i "env/$env.tpl.json" -o env/env.json

# Only the release build type reads a signing config, so the rest need no keystore.
if [[ "$flavour" == production ]]; then
  [[ -n "$OP_SIGNING_ITEM" ]] || { echo "No op:// storePassword in android/key.properties.tpl." >&2; exit 1; }
  op inject -f -i android/key.properties.tpl -o android/key.properties
  op read -f "$OP_SIGNING_ITEM/upload-keystore.jks" --out-file android/app/upload-keystore.jks
fi

fvm flutter build apk --flavor "$flavour" "--$mode" \
  --build-name="$build_name" --build-number="$build_number" \
  --dart-define-from-file=env/env.json

apk="build/app/outputs/flutter-apk/app-$flavour-$mode.apk"
[[ "$install" == 0 ]] || adb -s "$serial" install -r "$apk"

copy_artifact "$apk" "$flavour"

if [[ "$flavour" != production ]]; then
  echo "$flavour is debug-signed and unreleased, so pubspec is untouched."
  exit 0
fi

verify_signature "$apk"

if [[ "$install" == 0 ]]; then
  echo "Not installed, so pubspec is untouched and nothing was tagged."
  exit 0
fi

# Path-limited, and last, so a failed run records no version and unrelated working changes stay out.
sed "s/^version: .*/version: $build_name+$build_number/" pubspec.yaml >pubspec.yaml.tmp
mv pubspec.yaml.tmp pubspec.yaml
git commit --quiet pubspec.yaml -m "Release $build_name+$build_number"
# The release workflow asserts tag == pubspec, keeping the published APK identical to this one.
git tag "v$build_name+$build_number"
echo "Committed and tagged v$build_name+$build_number — push with: git push --follow-tags"
