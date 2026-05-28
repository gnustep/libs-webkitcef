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

## 4) Runtime Library Resolution

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
