#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WEBKIT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
CEF_PATH="${CEF_PATH:-$WEBKIT_DIR/cef_build/cef-project}"

patched_any=0

for header in "$CEF_PATH"/third_party/cef/cef_binary_*/include/base/cef_compiler_specific.h; do
    [ -f "$header" ] || continue
    patched_any=1

    if grep -q "CEF_DISABLE_TRIVIAL_ABI" "$header"; then
        continue
    fi

    python3 - "$header" <<'PY'
import pathlib
import sys

path = pathlib.Path(sys.argv[1])
text = path.read_text()
old = "#if defined(__clang__) && __has_attribute(trivial_abi)\n#define TRIVIAL_ABI [[clang::trivial_abi]]"
new = (
    "#if defined(__clang__) && __has_attribute(trivial_abi) && \\\n"
    "    !defined(CEF_DISABLE_TRIVIAL_ABI)\n"
    "#define TRIVIAL_ABI [[clang::trivial_abi]]"
)
if old not in text:
    raise SystemExit(f"ERROR: expected TRIVIAL_ABI block not found in {path}")
path.write_text(text.replace(old, new, 1))
PY
done

if [ "$patched_any" -eq 0 ]; then
    echo "ERROR: no CEF headers found under $CEF_PATH" >&2
    exit 1
fi
