#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
source scripts/lib.sh

case "${1:-staging}" in
  staging) flavour=staging; mode=debug ;;
  profiling) flavour=profiling; mode=profile ;;
  *) echo "usage: $0 [staging|profiling]" >&2; exit 1 ;;
esac

op inject -f -i env/staging.tpl.json -o env/env.json

serial=$(adb_serial)
[[ -n "$serial" ]] || die_no_device

exec fvm flutter run -d "$serial" --flavor "$flavour" "--$mode" --dart-define-from-file=env/env.json
