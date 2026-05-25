# Quick Fix for WebBrowser Linker Errors

## Problem

```
/usr/bin/ld: cannot find -lcef
/usr/bin/ld: cannot find -lvk_swiftshader
```

## Quick Solution - 3 Steps

### Step 1: Update WebBrowser's GNUmakefile.preamble

Add this line at the top of `WebBrowser/GNUmakefile.preamble`:

```makefile
-include ../WebKit/GNUmakefile.webkit-helper
```

This automatically handles CEF library linking.

### Step 2: Rebuild WebBrowser

```bash
cd WebBrowser
make clean
make
```

### Step 3: Run with Environment Script (if needed)

If you still get linker errors:

```bash
source ../WebKit/webkit-env.sh
make clean
make
```

## Why This Works

- `GNUmakefile.webkit-helper` checks if CEF libraries are available
- If found, it links them properly
- If not found, it sets up the framework to compile without them
- The environment script ensures `LD_LIBRARY_PATH` is set correctly

## Building CEF (Optional, for Full Functionality)

To get full CEF browser functionality:

```bash
cd WebKit/cef_build/cef-project/build
cmake ..
make -j$(nproc)
# Then rebuild WebBrowser - it will auto-detect CEF libraries
```

## Advanced: Manual Library Installation

If you have built CEF and want it system-wide:

```bash
cd WebKit
./bin/install_cef_libs.sh
# Libraries now at /usr/local/lib - no LD_LIBRARY_PATH needed
```

## Files Reference

- **webkit-env.sh** - Source this to set LD_LIBRARY_PATH
- **GNUmakefile.webkit-helper** - Include in your app's preamble  
- **bin/install_cef_libs.sh** - Install CEF to /usr/local/lib
- **Documentation/BUILD_APPLICATIONS.md** - Full build guide
