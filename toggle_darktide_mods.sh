#!/bin/sh

set -e

PATCHER_START="Starting Darktide patcher..."
PATCHER_FAIL="Error patching the Darktide bundle database. See logs."

CLEANUP_PATCHER=0

FORCE_NATIVE=1
[ "$1" = "-f" ] || [ "$1" = "--force" ] || FORCE_NATIVE=0

HAS_WINE=1
command -v wine >/dev/null 2>&1 || HAS_WINE=0


build_native_patcher() {
    if [ -e ./tools/dtkit-patch ]
    then
        read -p "Are you trying to update or remove the mod loader (y/n)? " RESPONSE
        case "$RESPONSE" in
            y|Y ) CLEANUP_PATCHER=1;;
        esac
        return 0
    fi

    if ! command -v cargo >/dev/null 2>&1; then
        echo >&2 "cargo not found, please install the cargo package, e.g. \"sudo apt install cargo\""
        exit 1
    fi
    if ! command -v git >/dev/null 2>&1; then
        echo >&2 "git not found, please install the git package, e.g. \"sudo apt install git\""
        exit 1
    fi
    echo "Building database patcher"
    rm -rf __dtkit 2>&1 || true
    mkdir __dtkit
    cd __dtkit
    git clone https://github.com/ManShanko/dtkit-patch.git .
    cargo build
    cp ./target/debug/dtkit-patch ../tools/
    cd ..
    rm -rf __dtkit
    echo "Database patcher built"
}


if [ "$FORCE_NATIVE" != 1 ] && [ "$HAS_WINE" = 1 ]
then
    echo $PATCHER_START
    wine ./tools/__dtkit-patch.exe --toggle ./bundle || echo >&2 $PATCHER_FAIL
    exit 0
fi

if [ "$FORCE_NATIVE" = 1 ]; then
    echo "Using native patcher due to user override"
else
    echo "Wine not found in path, falling back to native patcher"
fi

build_native_patcher

echo $PATCHER_START
./tools/dtkit-patch --toggle ./bundle || echo >&2 $PATCHER_FAIL

if [ "$CLEANUP_PATCHER" = 1 ] && [ -e ./tools/dtkit-patch ]
then
    rm ./tools/dtkit-patch
fi

