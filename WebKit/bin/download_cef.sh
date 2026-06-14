#!/usr/bin/env bash
set -euo pipefail

# Ensure necessary tools
command -v git >/dev/null 2>&1 || { echo >&2 "git is required."; exit 1; }
command -v python3 >/dev/null 2>&1 || { echo >&2 "python3 is required."; exit 1; }
command -v cmake >/dev/null 2>&1 || { echo >&2 "cmake is required."; exit 1; }

sha1_file_hash() {
    if command -v sha1sum >/dev/null 2>&1; then
        sha1sum "$1" | awk '{print $1}'
    else
        shasum -a 1 "$1" | awk '{print $1}'
    fi
}

download_file() {
    local url="$1"
    local output="$2"

    if command -v curl >/dev/null 2>&1; then
        curl -fL "$url" -o "$output"
    else
        python3 - "$url" "$output" <<'PY'
import sys
import urllib.request

url, output = sys.argv[1], sys.argv[2]
with urllib.request.urlopen(url) as response, open(output, "wb") as handle:
    handle.write(response.read())
PY
    fi
}

prefetch_clang_format() {
    local hash_path
    local out_path
    local sha_file
    local output
    local expected_sha
    local tmp_output
    local actual_sha

    case "$(uname -s)" in
        Linux)
            hash_path="linux64/clang-format.sha1"
            out_path="linux64/clang-format"
            ;;
        Darwin)
            if [ "$(uname -m)" = "arm64" ]; then
                hash_path="mac/clang-format.arm64.sha1"
            else
                hash_path="mac/clang-format.x64.sha1"
            fi
            out_path="mac/clang-format"
            ;;
        *)
            return 0
            ;;
    esac

    sha_file="$PROJECT_DIR/tools/buildtools/$hash_path"
    output="$PROJECT_DIR/tools/buildtools/$out_path"

    [ -f "$sha_file" ] || return 0

    expected_sha="$(tr -d '[:space:]' < "$sha_file")"
    if [ -f "$output" ] && [ "$(sha1_file_hash "$output")" = "$expected_sha" ]; then
        chmod +x "$output" 2>/dev/null || true
        return 0
    fi

    echo "Prefetching clang-format from Google Storage..."
    mkdir -p "$(dirname "$output")"
    tmp_output="$output.tmp"
    download_file "https://storage.googleapis.com/chromium-clang-format/$expected_sha" "$tmp_output"

    actual_sha="$(sha1_file_hash "$tmp_output")"
    if [ "$actual_sha" != "$expected_sha" ]; then
        rm -f "$tmp_output"
        echo "ERROR: clang-format checksum mismatch: expected $expected_sha, got $actual_sha" >&2
        exit 1
    fi

    mv "$tmp_output" "$output"
    chmod +x "$output"
}

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WEBKIT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
WORKDIR="${CEF_WORKDIR:-$WEBKIT_DIR/cef_build}"
PROJECT_DIR="$WORKDIR/cef-project"
BUILD_DIR="$PROJECT_DIR/build"
REPO_URL="${CEF_PROJECT_REPO:-https://github.com/chromiumembedded/cef-project.git}"
PINNED_CEF_PROJECT_REF="3aec7049cf63a36876d7a6ef538842d6af314482"
PROJECT_REF="${CEF_PROJECT_REF:-$PINNED_CEF_PROJECT_REF}"
BUILD_TYPE="${CEF_BUILD_TYPE:-Release}"
JOBS="${JOBS:-$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 4)}"

mkdir -p "$WORKDIR"

if [ -d "$PROJECT_DIR/.git" ]; then
    echo "Updating cef-project from $REPO_URL..."
    git -C "$PROJECT_DIR" remote set-url origin "$REPO_URL"
    if git -C "$PROJECT_DIR" diff --quiet && git -C "$PROJECT_DIR" diff --cached --quiet; then
        git -C "$PROJECT_DIR" fetch --tags origin
        git -C "$PROJECT_DIR" checkout --detach "$PROJECT_REF"
    else
        echo "cef-project has local changes; leaving checkout as-is after updating origin URL."
        echo "Requested cef-project ref: $PROJECT_REF"
    fi
elif [ -e "$PROJECT_DIR" ]; then
    echo "ERROR: $PROJECT_DIR exists but is not a git checkout." >&2
    exit 1
else
    echo "Cloning cef-project from $REPO_URL..."
    git clone "$REPO_URL" "$PROJECT_DIR"
    git -C "$PROJECT_DIR" checkout --detach "$PROJECT_REF"
fi

prefetch_clang_format
ACTIVE_PROJECT_REF="$(git -C "$PROJECT_DIR" rev-parse HEAD)"

# Configure CMake to fetch the selected CEF binary and build sample
cmake -S "$PROJECT_DIR" -B "$BUILD_DIR" -G "Unix Makefiles" -DCMAKE_BUILD_TYPE="$BUILD_TYPE"
cmake --build "$BUILD_DIR" --target cefsimple --parallel "$JOBS"

echo "Downloaded and unpacked CEF binaries from cef-project ref $ACTIVE_PROJECT_REF."
echo "Build output in: $BUILD_DIR"

exit 0
