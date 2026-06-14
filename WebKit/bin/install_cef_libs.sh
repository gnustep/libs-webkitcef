#!/bin/bash
# Install CEF libraries to /usr/local/lib for WebKit applications

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CEF_PATH="${SCRIPT_DIR}/cef_build/cef-project"
CEF_BINARY_PATH=$(find "$CEF_PATH/third_party/cef" -maxdepth 1 -type d -name "cef_binary_*" | head -1)

if [ -z "$CEF_BINARY_PATH" ]; then
    echo "ERROR: CEF binary not found at $CEF_PATH/third_party/cef/"
    echo "Please download CEF first: ./bin/download_cef.sh"
    exit 1
fi

CEF_LIB_DIR="$CEF_BINARY_PATH/Release"
CEF_DLL_WRAPPER_DIR="$CEF_PATH/build/libcef_dll_wrapper"

if [ ! -d "$CEF_LIB_DIR" ]; then
    echo "ERROR: CEF libraries not built at $CEF_LIB_DIR"
    echo "Please build CEF first:"
    echo "  cd $CEF_PATH/build"
    echo "  cmake .."
    echo "  make -j\$(nproc)"
    exit 1
fi

echo "Installing CEF libraries to /usr/local/lib..."

# Create destination directory
sudo mkdir -p /usr/local/lib

# Copy CEF libraries
for lib in libcef.so libcef_dll_wrapper.a libEGL.so libGLESv2.so libvk_swiftshader.so libcef.so.so; do
    if [ -f "$CEF_LIB_DIR/$lib" ]; then
        echo "  Installing $lib..."
        sudo cp "$CEF_LIB_DIR/$lib" /usr/local/lib/
        sudo chmod 644 "/usr/local/lib/$lib"
    fi
done

# Also copy from dll_wrapper directory
if [ -f "$CEF_DLL_WRAPPER_DIR/libcef_dll_wrapper.a" ]; then
    echo "  Installing libcef_dll_wrapper.a (dll_wrapper)..."
    sudo cp "$CEF_DLL_WRAPPER_DIR/libcef_dll_wrapper.a" /usr/local/lib/
    sudo chmod 644 "/usr/local/lib/libcef_dll_wrapper.a"
fi

# Update library cache
echo "Updating library cache..."
sudo ldconfig

echo ""
echo "✅ CEF libraries installed to /usr/local/lib"
echo ""
echo "WebKit applications should now compile without linker errors."
echo ""
echo "If you still get 'cannot find -lcef', set LD_LIBRARY_PATH:"
echo "  export LD_LIBRARY_PATH=/usr/local/lib:\$LD_LIBRARY_PATH"
echo ""
