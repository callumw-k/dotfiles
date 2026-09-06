#!/usr/bin/env bash
set -euo pipefail

flavour="${1:-production}"
cd "$(dirname "$0")/.."

# Wireless adb reports an ip:port that changes per connection.
serial=$(adb devices | awk '$2=="device"{print $1; exit}')
if [ -z "$serial" ]; then
  echo "No adb device attached. Connect first:" >&2
  echo "  adb pair <ip>:<port>" >&2
  echo "  adb connect <ip>:<port>" >&2
  exit 1
fi

gradle=android/app/build.gradle.kts
base_id=$(awk -F'"' '/^[[:space:]]*applicationId[[:space:]]*=/{print $2; exit}' "$gradle")
if [ -z "$base_id" ]; then
  echo "No applicationId found in $gradle." >&2
  exit 1
fi
# Step 1 sets applicationIdSuffix to "." plus the flavour name.
app_id="$base_id.$flavour"

current=$(awk '/^version:/{print $2; exit}' pubspec.yaml)
current_name="${current%+*}"
current_number="${current#*+}"
build_name="${2:-$current_name}"

# Android refuses a downgrade install, so start from whichever is further ahead.
installed=$(adb -s "$serial" shell dumpsys package "$app_id" 2>/dev/null \
  | sed -n 's/.*versionCode=\([0-9][0-9]*\).*/\1/p' | head -1 || true)
installed="${installed:-0}"
build_number=$((current_number > installed ? current_number : installed))
build_number=$((build_number + 1))

printf 'Overwrite env/env.json, android/key.properties, android/app/upload-keystore.jks if they exist? [y/N] '
read -r overwrite
case "$overwrite" in
  [yY]) rm -f env/env.json android/key.properties android/app/upload-keystore.jks ;;
esac

# Reuse key.properties.tpl's vault item so it cannot drift from a second copy.
keystore_item=$(sed -n 's|^storePassword=\(op://[^/]*/[^/]*\)/.*|\1|p' android/key.properties.tpl)
if [ -z "$keystore_item" ]; then
  echo "No op:// storePassword in android/key.properties.tpl." >&2
  exit 1
fi

op inject -i "env/$flavour.tpl.json" -o env/env.json
op inject -i android/key.properties.tpl -o android/key.properties
op read "$keystore_item/upload-keystore.jks" --out-file android/app/upload-keystore.jks

fvm flutter build apk --flavor "$flavour" --release \
  --build-name="$build_name" --build-number="$build_number" \
  --dart-define-from-file=env/env.json

apk="build/app/outputs/flutter-apk/app-$flavour-release.apk"
adb -s "$serial" install -r "$apk"

# Bumped only after build and install both succeed, so a failure records nothing.
sed "s/^version: .*/version: $build_name+$build_number/" pubspec.yaml > pubspec.yaml.tmp
mv pubspec.yaml.tmp pubspec.yaml
git commit --quiet pubspec.yaml -m "Release $build_name+$build_number"
echo "Committed version $build_name+$build_number"

echo "Signed with:"
keytool -printcert -jarfile "$apk" | grep -m1 'Owner:'
