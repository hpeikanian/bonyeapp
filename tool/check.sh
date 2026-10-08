#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
export ANALYZER_STATE_LOCATION_OVERRIDE=/workspace/toolchains/analyzer-state
python3 tool/check_contract.py
flutter pub get --enforce-lockfile
flutter --suppress-analytics analyze
flutter --suppress-analytics test
flutter build apk --debug
