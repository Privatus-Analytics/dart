#!/bin/sh
# Runs the formatter check, the analyzer, the tests, a web build check and a
# publish dry run in the official Dart image, so your local Dart does not
# matter. Usage: ./run-docker.sh
set -e
docker run --rm -v "$PWD":/app -w /app dart:stable sh -c '
  set -e
  dart pub get
  dart format --output=none --set-exit-if-changed .
  dart analyze --fatal-infos
  dart test
  dart compile js -o /tmp/web_check.js example/web/main.dart
  dart pub publish --dry-run
  rm -rf .dart_tool pubspec.lock
  echo "All checks passed."
'
