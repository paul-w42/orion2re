#!/usr/bin/env bash
# Copy this script into the directory containing the original game's .lbx files.
# Override ORION2RE_BUILD_DIR to use a different build.
set -euo pipefail

ASSET_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
BUILD_DIR=${ORION2RE_BUILD_DIR:-/home/paul/Data/Git/orion2re/out/build/test-debug}
BUILD_DIR=$(cd -- "$BUILD_DIR" && pwd)
GAME_EXE="$BUILD_DIR/orion2re"

fail() {
    printf 'ERROR: %s\n' "$*" >&2
    exit 1
}

[[ -x "$GAME_EXE" ]] || fail "Executable not found: $GAME_EXE"
[[ -f "$BUILD_DIR/data/base.zip" ]] || fail "Runtime archive not found: $BUILD_DIR/data/base.zip"
[[ -f "$BUILD_DIR/data/orion2re.cfg" ]] || fail "Default configuration not found in $BUILD_DIR/data"
compgen -G "$ASSET_DIR/*.[lL][bB][xX]" >/dev/null ||
    fail "Copy this launcher into the directory containing the original .lbx files."

mkdir -p -- "$ASSET_DIR/data/mods"

# Install the build's setup-screen content, preserving any previous archive.
base_archive="$ASSET_DIR/data/base.zip"
if ! cmp -s -- "$BUILD_DIR/data/base.zip" "$base_archive"; then
    if [[ -e "$base_archive" || -L "$base_archive" ]]; then
        backup_path=$(mktemp "$ASSET_DIR/data/base.zip.backup.XXXXXX")
        cp -pL -- "$base_archive" "$backup_path"
        printf 'Previous runtime archive backed up to %s\n' "$backup_path"
    fi
    cp --remove-destination -- "$BUILD_DIR/data/base.zip" "$base_archive"
fi

# Keep the player's configuration and existing mods; add missing build defaults.
if [[ ! -e "$ASSET_DIR/data/orion2re.cfg" ]]; then
    cp -- "$BUILD_DIR/data/orion2re.cfg" "$ASSET_DIR/data/orion2re.cfg"
fi
for mod_archive in "$BUILD_DIR"/data/mods/*.zip; do
    [[ -f "$mod_archive" ]] || continue
    mod_destination="$ASSET_DIR/data/mods/${mod_archive##*/}"
    if [[ ! -e "$mod_destination" ]]; then
        cp -- "$mod_archive" "$mod_destination"
    fi
done

cd -- "$ASSET_DIR"
printf 'Starting %s\nUsing assets in %s\n' "$GAME_EXE" "$ASSET_DIR"
exec "$GAME_EXE" "$@"
