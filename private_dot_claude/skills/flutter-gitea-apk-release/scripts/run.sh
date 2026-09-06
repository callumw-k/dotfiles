#!/usr/bin/env bash
set -euo pipefail

flavour="${1:-staging}"
cd "${2:-$(dirname "$0")/..}"

# Wireless adb reports an ip:port that changes per connection.
serial=$(adb devices | awk '$2=="device"{print $1; exit}')
if [ -z "$serial" ]; then
  echo "No adb device attached. Connect first:" >&2
  echo "  adb pair <ip>:<port>" >&2
  echo "  adb connect <ip>:<port>" >&2
  exit 1
fi

tpl="env/$flavour.tpl.json"
if [ ! -f "$tpl" ]; then
  echo "No $tpl, so flavour '$flavour' has no env template." >&2
  exit 1
fi

# Generated once and reused: delete env/env.json to pull fresh values.
if [ ! -f env/env.json ]; then
  op inject -i "$tpl" -o env/env.json
fi

fvm flutter run -d "$serial" --flavor "$flavour" --dart-define-from-file=env/env.json
