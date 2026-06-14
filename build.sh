#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WEBKIT_DIR="$ROOT_DIR/WebKit"
JOBS="${JOBS:-$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 4)}"

usage() {
    cat <<USAGE
Usage: ./build.sh [--skip-cef] [--clean] [--debug]

Builds CEF when needed, then builds the WebKit framework and applications.

Options:
  --skip-cef   Do not download or build CEF first.
  --clean      Run make clean before building the repository.
  --debug      Pass debug=yes to GNUstep make.
USAGE
}

SKIP_CEF=0
CLEAN=0
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

if [ -z "${GNUSTEP_MAKEFILES:-}" ]; then
    GNUSTEP_MAKEFILES="$(gnustep-config --variable=GNUSTEP_MAKEFILES 2>/dev/null || true)"
    export GNUSTEP_MAKEFILES
fi

if [ -z "${GNUSTEP_MAKEFILES:-}" ]; then
    echo "ERROR: GNUSTEP_MAKEFILES is not set and gnustep-config could not provide it." >&2
    exit 1
fi

if [ "$SKIP_CEF" -eq 0 ]; then
    "$WEBKIT_DIR/bin/download_cef.sh"
fi

if [ "$CLEAN" -eq 1 ]; then
    make -C "$ROOT_DIR" clean "${MAKE_ARGS[@]}"
fi

make -C "$ROOT_DIR" -j"$JOBS" "${MAKE_ARGS[@]}"
