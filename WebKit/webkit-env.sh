#!/bin/bash
# webkit-env.sh - Source this to set up environment for building WebKit applications
# 
# Usage: source ./webkit-env.sh
#   or:  . ./webkit-env.sh
#
# This sets up LD_LIBRARY_PATH and other variables needed for WebKit apps

WEBKIT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CEF_PATH="${WEBKIT_DIR}/cef_build/cef-project"

# Find CEF binary directory
CEF_BINARY_PATH=$(find "$CEF_PATH/third_party/cef" -maxdepth 1 -type d -name "cef_binary_*" | head -1)

if [ -n "$CEF_BINARY_PATH" ]; then
    # Try Release directory first
    if [ -d "$CEF_BINARY_PATH/Release" ]; then
        export LD_LIBRARY_PATH="$CEF_BINARY_PATH/Release:$LD_LIBRARY_PATH"
        echo "✓ CEF Release libraries: $CEF_BINARY_PATH/Release"
    fi
    
    # Try Debug directory
    if [ -d "$CEF_BINARY_PATH/Debug" ]; then
        export LD_LIBRARY_PATH="$CEF_BINARY_PATH/Debug:$LD_LIBRARY_PATH"
        echo "✓ CEF Debug libraries: $CEF_BINARY_PATH/Debug"
    fi
fi

# Also check for system-installed libraries
if [ -d "/usr/local/lib" ]; then
    export LD_LIBRARY_PATH="/usr/local/lib:$LD_LIBRARY_PATH"
fi

# Print summary
echo ""
echo "WebKit environment configured"
echo "LD_LIBRARY_PATH=$LD_LIBRARY_PATH"
echo ""
