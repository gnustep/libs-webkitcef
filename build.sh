#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WEBKIT_DIR="$ROOT_DIR/WebKit"
JOBS="${JOBS:-$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 4)}"

usage() {
    cat <<USAGE
Usage: ./build.sh [--skip-cef] [--clean] [--debug] [--install]

Builds CEF when needed, then builds the WebKit framework and applications.
Use --install to install in the GNUstep SYSTEM domain after building.

Options:
  --skip-cef   Do not download or build CEF first.
  --clean      Run make clean before building the repository.
  --debug      Pass debug=yes to GNUstep make.
  --install    Install after building. If already built, install without rebuilding.
USAGE
}

SKIP_CEF=0
CLEAN=0
INSTALL=0
MAKE_ARGS=()

while [ "$#" -gt 0 ]; do
    case "$1" in
        --skip-cef)
            SKIP_CEF=1
            ;;
        --clean)
            CLEAN=1
            ;;
        --debug)
            MAKE_ARGS+=(debug=yes)
            ;;
        --install)
            INSTALL=1
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "ERROR: unknown option: $1" >&2
            usage >&2
            exit 2
            ;;
    esac
    shift
done

is_built() {
    [ -f "$WEBKIT_DIR/WebKit.framework/Versions/0.1/libWebKit.so.0.1" ] &&
        [ -x "$ROOT_DIR/Applications/NetStep/NetStep.app/NetStep" ]
}

build_repo() {
    if [ "$SKIP_CEF" -eq 0 ]; then
        "$WEBKIT_DIR/bin/download_cef.sh"
    fi

    if [ "$CLEAN" -eq 1 ]; then
        make -C "$ROOT_DIR" clean "${MAKE_ARGS[@]}"
    fi

    make -C "$ROOT_DIR" -j"$JOBS" "${MAKE_ARGS[@]}"
}

install_repo() {
    if [ "$(id -u)" -eq 0 ]; then
        make -C "$ROOT_DIR" install GNUSTEP_INSTALLATION_DOMAIN=SYSTEM "${MAKE_ARGS[@]}"
        return
    fi

    if ! command -v sudo >/dev/null 2>&1; then
        echo "ERROR: install requires root privileges or sudo." >&2
        exit 1
    fi

    echo "Install requires sudo privileges."
    sudo -v
    sudo env GNUSTEP_MAKEFILES="$GNUSTEP_MAKEFILES" \
        make -C "$ROOT_DIR" install GNUSTEP_INSTALLATION_DOMAIN=SYSTEM "${MAKE_ARGS[@]}"
}

if [ -z "${GNUSTEP_MAKEFILES:-}" ]; then
    GNUSTEP_MAKEFILES="$(gnustep-config --variable=GNUSTEP_MAKEFILES 2>/dev/null || true)"
    export GNUSTEP_MAKEFILES
fi

if [ -z "${GNUSTEP_MAKEFILES:-}" ]; then
    echo "ERROR: GNUSTEP_MAKEFILES is not set and gnustep-config could not provide it." >&2
    exit 1
fi

if [ "$INSTALL" -eq 1 ]; then
    if [ "$CLEAN" -eq 1 ] || ! is_built; then
        build_repo
    fi
    install_repo
else
    build_repo
fi
