ARTIFACT_ROOT=/mnt/code-artifacts # machine-level, so scripts/ copies in unedited

APP_NAME=$(awk '/^name:/{gsub(/_/,"-",$2); print $2; exit}' pubspec.yaml)
APP_ID=$(awk -F'"' '/^[[:space:]]*applicationId[[:space:]]*=/{print $2; exit}' android/app/build.gradle.kts)
[[ -n "$APP_NAME" && -n "$APP_ID" ]] || { echo "No pubspec name or applicationId to work from." >&2; exit 1; }

# Read from the template, so the vault item has one home rather than two.
OP_SIGNING_ITEM=$(sed -n 's|^storePassword=\(op://[^/]*/[^/]*\)/.*|\1|p' android/key.properties.tpl 2>/dev/null)

# Wireless adb reports a per-connection ip:port, so resolve rather than hardcode.
adb_serial() { adb devices | awk '$2=="device"{print $1; exit}'; }

die_no_device() {
  echo "No adb device attached. Connect first:" >&2
  echo "  adb pair <ip>:<port>" >&2
  echo "  adb connect <ip>:<port>" >&2
  exit 1
}

pubspec_version() { awk '/^version:/{print $2; exit}' pubspec.yaml; }

# `|| true` because not installed is the first-install case, not a failure.
installed_version_code() {
  adb -s "$1" shell dumpsys package "$APP_ID.$2" 2>/dev/null \
    | sed -n 's/.*versionCode=\([0-9][0-9]*\).*/\1/p' | head -1 || true
}

# The artifacts share only exists on the server, so a laptop build leaves the APK put.
copy_artifact() {
  local apk=$1 flavour=$2 dest
  if [[ ! -d "$ARTIFACT_ROOT" ]]; then
    echo "No $ARTIFACT_ROOT here, APK left at $apk"
    return
  fi
  dest="$ARTIFACT_ROOT/$APP_NAME/$flavour"
  mkdir -p "$dest"
  cp "$apk" "$dest"/
  echo "Copied to $dest/$(basename "$apk")"
}

verify_signature() {
  local apksigner
  apksigner=$(ls -d "${ANDROID_HOME:?}"/build-tools/*/ | sort -V | tail -1)apksigner
  echo "Signed with:"
  "$apksigner" verify --print-certs "$1" | grep 'certificate DN'
}
