# Building CEF (Download + Build + Runtime Setup)

This project supports two modes:

- Stub mode: compiles without CEF binaries (no real browser runtime)
- Full mode: uses Chromium Embedded Framework (CEF) for actual rendering

Use this guide to enable full mode.

## Prerequisites

- `git`
- `python3`
- `cmake`
- `make`
- GNUstep development environment (`gnustep-make`)

## 1) Download and Prepare CEF

From the repository root:

```sh
./build.sh
```

What this script does:

- creates `WebKit/cef_build/`
- clones `cef-project` from GitHub
- checks out pinned `cef-project` commit `3aec7049cf63a36876d7a6ef538842d6af314482`
- configures CMake in `WebKit/cef_build/cef-project/build`
- builds `cefsimple` to fetch and unpack CEF binaries and produce initial artifacts
- builds the WebKit framework and applications

To prepare only CEF, run:

```sh
WebKit/bin/download_cef.sh
```

To test a different `cef-project` release or commit without changing the
default pin, set `CEF_PROJECT_REF`:

```sh
CEF_PROJECT_REF=<tag-or-commit> WebKit/bin/download_cef.sh
```

## 2) Build CEF Libraries

If you want full runtime support, build the CEF project artifacts in Release mode:

```sh
cd WebKit/cef_build/cef-project/build
cmake -G "Unix Makefiles" -DCMAKE_BUILD_TYPE=Release ..
make -j4
```

Expected key output locations:

- `WebKit/cef_build/cef-project/third_party/cef/cef_binary_*/include`
- `WebKit/cef_build/cef-project/third_party/cef/cef_binary_*/Release/libcef.so`
- `WebKit/cef_build/cef-project/build/libcef_dll_wrapper/`

## 3) Rebuild the Framework with CEF Enabled

```sh
./build.sh --skip-cef --clean
```

The makefiles auto-detect CEF headers/libraries and switch from stub mode to
full CEF mode.

## 4) Make Libraries Available at Runtime

Option A (session-local):

```sh
source WebKit/webkit-env.sh
```

Option B (system install):

```sh
WebKit/bin/install_cef_libs.sh
```

## 5) Verify Your Build Mode

When CEF is missing, build output warns that stubs are being used.
When CEF is found, the framework links against CEF libraries and provides real
browser functionality.

## Troubleshooting

### CEF binary folder not found

Run the download step again:

```sh
WebKit/bin/download_cef.sh
```

### Framework builds but app cannot load `libcef.so`

Use one of:

- `source WebKit/webkit-env.sh`
- `WebKit/bin/install_cef_libs.sh`

### Build is too slow

Use fewer jobs for low-memory systems (for example `make -j2`) or higher jobs
on larger machines.
