#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 3 ]]; then
  printf 'usage: create-release-dmg.sh <app-path> <output-dmg> <volume-name>\n' >&2
  exit 64
fi

APP_PATH="$1"
OUTPUT_DMG="$2"
VOLUME_NAME="$3"

if [[ ! -d "$APP_PATH" ]]; then
  printf 'app bundle not found: %s\n' "$APP_PATH" >&2
  exit 66
fi

if [[ -e "$OUTPUT_DMG" ]]; then
  printf 'output dmg already exists: %s\n' "$OUTPUT_DMG" >&2
  exit 73
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORK_DIR="$(mktemp -d)"
DMG_ROOT="$WORK_DIR/root"
BACKGROUND_PATH="$WORK_DIR/dmg-background.png"
CREATE_DMG_DIR="$WORK_DIR/create-dmg"

cleanup() {
  rm -rf "$WORK_DIR"
}

trap cleanup EXIT

mkdir -p "$DMG_ROOT"
ditto "$APP_PATH" "$DMG_ROOT/$(basename "$APP_PATH")"
swift "$SCRIPT_DIR/create-dmg-background.swift" "$BACKGROUND_PATH"

git -c advice.detachedHead=false clone \
  --quiet \
  --depth 1 \
  --branch v1.2.3 \
  --single-branch \
  https://github.com/create-dmg/create-dmg.git \
  "$CREATE_DMG_DIR"

"$CREATE_DMG_DIR/create-dmg" \
  --volname "$VOLUME_NAME" \
  --background "$BACKGROUND_PATH" \
  --window-pos 200 120 \
  --window-size 660 420 \
  --icon-size 112 \
  --icon "$(basename "$APP_PATH")" 200 172 \
  --hide-extension "$(basename "$APP_PATH")" \
  --app-drop-link 460 172 \
  --format UDZO \
  --filesystem HFS+ \
  --hdiutil-retries 8 \
  "$OUTPUT_DMG" \
  "$DMG_ROOT"
