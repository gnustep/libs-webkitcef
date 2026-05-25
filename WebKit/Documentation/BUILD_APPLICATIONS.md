# WebKit Application Build Guide

## Issue: "cannot find -lcef" when building WebBrowser

This happens when CEF libraries haven't been built yet. You have several options:

## Option 1: Source the Environment Script (Easiest)

Before building your WebBrowser application, source the webkit environment script:

```bash
cd /path/to/WebKit
source ./webkit-env.sh
cd /path/to/WebBrowser
make
```

This sets `LD_LIBRARY_PATH` to include potential CEF library locations.

## Option 2: Install CEF Libraries to System Location

If you've built CEF and want to avoid `LD_LIBRARY_PATH` hacks:

```bash
cd /path/to/WebKit
./bin/install_cef_libs.sh
```

This copies CEF libraries to `/usr/local/lib` where the linker can find them. Then rebuild your application:

```bash
cd /path/to/WebBrowser
make clean
make
```

## Option 3: Build CEF First (Recommended for Production)

For production use, build CEF with full functionality:

```bash
cd /path/to/WebKit/cef_build/cef-project/build
cmake ..
make -j$(nproc)
```

This takes 10-30 minutes. After it completes:

1. Rebuild WebKit to link CEF libraries:

   ```bash
   cd /path/to/WebKit
   make clean
   make install
   ```

2. Rebuild your WebBrowser application:

   ```bash
   cd /path/to/WebBrowser
   make clean
   make install
   ```

## Option 4: Modify Your WebBrowser GNUmakefile

If you want more control over linking, add this to your WebBrowser's GNUmakefile.preamble:

```makefile
# Optional CEF libraries - only link if available
CEF_PATH ?= ../WebKit/cef_build/cef-project
CEF_BINARY_PATH = $(wildcard $(CEF_PATH)/third_party/cef/cef_binary_*)
CEF_LIB_DIR = $(wildcard $(CEF_PATH)/third_party/cef/cef_binary_*/Release)

ifneq ($(wildcard $(CEF_LIB_DIR)/libcef.so),)
  # CEF libraries exist - link them
  WebBrowser_LIBS += -L$(CEF_LIB_DIR) -lcef -lvk_swiftshader
  # Also try /usr/local/lib
else ifneq ($(wildcard /usr/local/lib/libcef.so),)
  # System-installed CEF
  WebBrowser_LIBS += -L/usr/local/lib -lcef -lvk_swiftshader
else
  # CEF not available - build without it
  $(warning CEF libraries not found. WebView will compile without CEF runtime.)
endif
```

## Current Status

- ✅ WebKit compiles successfully
- ⏳ CEF libraries not built (optional step)
- ⚠️ Applications linking WebKit need CEF libraries available

## Next Steps

### For Immediate Use (Without CEF Runtime)

```bash
source ./webkit-env.sh
cd ../WebBrowser
make
./WebBrowser.app/WebBrowser
```

### For Full CEF Functionality

```bash
# Build CEF (takes time)
cd ./cef_build/cef-project/build && cmake .. && make -j$(nproc)

# Install CEF libraries
cd ../../.. && ./bin/install_cef_libs.sh

# Rebuild everything
make clean && make install
cd ../WebBrowser && make clean && make install
```

## Troubleshooting

### Still getting "cannot find -lcef"?

1. Check if CEF was built:

   ```bash
   find ./cef_build -name "libcef.so" -o -name "libcef.a"
   ```

2. Check if libraries are in /usr/local/lib:

   ```bash
   ls -la /usr/local/lib/libcef*
   ```

3. Set LD_LIBRARY_PATH manually:

   ```bash
   export LD_LIBRARY_PATH=/usr/local/lib:$(find ./cef_build -type d -name Release | head -1):$LD_LIBRARY_PATH
   ```

4. Check linker configuration:

   ```bash
   ldconfig -p | grep libcef
   ```

### "undefined reference to `CefInitialize'"?

This means WebKit was compiled with CEF headers (HAVE_CEF=1) but CEF libraries aren't available. Either:

1. Build CEF libraries (see "For Full CEF Functionality" above)
2. Rebuild WebKit without CEF headers:

   ```bash
   cd WebKit
   rm -rf obj/
   make clean
   make
   ```

### Runtime error about missing libcef.so?

Set `LD_LIBRARY_PATH` when running:

```bash
export LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH
./WebBrowser.app/WebBrowser
```

Or use the environment script:

```bash
source ./webkit-env.sh
./WebBrowser.app/WebBrowser
```
