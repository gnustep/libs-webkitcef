# Building Applications Against WebKit

This guide covers building apps that link to the WebKit framework in this repo,
including full CEF runtime support.

## 1) Build WebKit

```sh
cd /Volumes/heron/Development/libs-webkitcef/WebKit
make clean
make
```

## 2) Download and Build CEF (Full Runtime)

If you need real browser rendering, run:

```sh
cd /Volumes/heron/Development/libs-webkitcef/WebKit
./bin/download_cef.sh
cd cef_build/cef-project/build
cmake -G "Unix Makefiles" -DCMAKE_BUILD_TYPE=Release ..
make -j4
cd ../../..
make clean
make
```

For additional details, see [BUILD_CEF_OPTIONAL.md](BUILD_CEF_OPTIONAL.md).

## 3) Build the Sample App

```sh
cd /Volumes/heron/Development/libs-webkitcef/Applications/WebBrowser
make clean
make
```

## 4) Integrate WebKit into Your App

To use this WebKit implementation in your own GNUstep app, add the following
pieces.

### 4.1 GNUmakefile

Keep the standard GNUstep application makefile structure and include your
`GNUmakefile.preamble` before `application.make`:

```make
include $(GNUSTEP_MAKEFILES)/common.make

APP_NAME = MyApp

MyApp_OBJC_FILES = \
  AppController.m \
  main.m

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/aggregate.make
include $(GNUSTEP_MAKEFILES)/application.make
-include GNUmakefile.postamble
```

### 4.2 GNUmakefile.preamble

Add WebKit and CEF include/library paths and link flags (adapt paths as
needed):

```make
WEBKIT_DIR = ../../WebKit
CEF_PATH = $(WEBKIT_DIR)/cef_build/cef-project
CEF_BINARY_CANDIDATES = $(filter-out %.tar.bz2 %.tar.bz2.sha1,$(wildcard $(CEF_PATH)/third_party/cef/cef_binary_*))
CEF_BINARY_PATH = $(firstword $(CEF_BINARY_CANDIDATES))
CEF_LIB_DIR = $(CEF_BINARY_PATH)/Release
WEBKIT_LIB_DIR = $(abspath $(WEBKIT_DIR)/WebKit.framework)
WEBKIT_VERSION_LIB_DIR = $(WEBKIT_LIB_DIR)/Versions/Current
CEF_ABS_LIB_DIR = $(abspath $(CEF_LIB_DIR))

ADDITIONAL_CPPFLAGS += -I../.. -I$(WEBKIT_DIR) -I$(CEF_BINARY_PATH)/include -DCEF_DISABLE_TRIVIAL_ABI=1
ADDITIONAL_GUI_LIBS += -lWebKit -lcef -lEGL -lGLESv2 -lvk_swiftshader -lstdc++
ADDITIONAL_LDFLAGS += -L$(WEBKIT_VERSION_LIB_DIR) -L$(WEBKIT_LIB_DIR) -L$(CEF_ABS_LIB_DIR)
ADDITIONAL_LDFLAGS += -Wl,-rpath,$(WEBKIT_VERSION_LIB_DIR):$(WEBKIT_LIB_DIR):$(CEF_ABS_LIB_DIR)
```

If you want behavior identical to the sample app, also keep:

```make
ADDITIONAL_LDFLAGS += -Wl,--no-as-needed -Wl,--allow-shlib-undefined -Wl,--unresolved-symbols=ignore-all
```

### 4.3 main.m

Your `main.m` should call `WebKitCEFHandleProcess` before starting AppKit,
so CEF child/helper processes exit correctly.

```objc
#import <AppKit/AppKit.h>
#import <WebKit/WebKit.h>

int main(int argc, const char *argv[])
{
  int cefExitCode = WebKitCEFHandleProcess(argc, argv);
  if (cefExitCode >= 0)
    {
      return cefExitCode;
    }

  return NSApplicationMain(argc, argv);
}
```

## 5) Runtime Library Resolution

If the app fails to start due to missing CEF shared libraries, choose one:

Option A: source environment helper

```sh
source /Volumes/heron/Development/libs-webkitcef/WebKit/webkit-env.sh
```

Option B: install CEF libs system-wide

```sh
cd /Volumes/heron/Development/libs-webkitcef/WebKit
./bin/install_cef_libs.sh
```

## Troubleshooting

### Linker cannot find `-lcef`

- Verify `libcef.so` exists under `WebKit/cef_build/cef-project/third_party/cef/cef_binary_*/Release/`
- Rebuild `WebKit` after CEF build completes
- Use `source WebKit/webkit-env.sh` before launching the app

### App launches but browser surface is blank

- Confirm app has access to CEF resources and locales in the CEF binary tree
- Confirm runtime library path includes the CEF `Release` directory

### You only need compile-time API checks

Building without CEF is supported via stubs, but runtime browser functionality is not available in that mode.
