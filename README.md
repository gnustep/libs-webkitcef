# libs-webkitcef

`libs-webkitcef` is a GNUstep WebKit-compatible framework backed by the
Chromium Embedded Framework (CEF). It provides a `WebView` Objective-C API for
loading web pages, navigating browser history, and evaluating JavaScript from
GNUstep applications.

The repository also includes a small `NetStep` application that uses the
framework.

## Screenshot

This is an early version of the WebBrowser demo (replaced by NetStep) running on Linux using GNUstep...

<img width="906" height="705" alt="webpage_demo" src="https://github.com/user-attachments/assets/e38b0241-555c-4b08-9f2c-6b3e0b68f7f6" />

Showing GNUstep

<img width="1125" height="1105" alt="webkit_gnustep" src="https://github.com/user-attachments/assets/77eca8e5-1920-4bf1-a432-add9e1ed24cd" />

## Repository Layout

- `WebKit/` - GNUstep framework sources, public headers, CEF integration, and
  helper scripts.
- `Applications/WebBrowser/` - sample GNUstep application using `WebView`.
- `WebKit/Documentation/` - detailed notes about the build, CEF integration,
  linker fixes, and application setup.
- `build.sh` - one-command build script that fetches/builds CEF, then builds
  the framework and applications.
- `WebKit/bin/download_cef.sh` - fetches and builds the CEF sample project used
  by this framework.
- `WebKit/bin/install_cef_libs.sh` - installs built CEF libraries into
  `/usr/local/lib`.

## Next steps (no pun intended)

- A palette for Gorm so that this can be wired into a `.gorm` (or other model) file
  for easy re-use.  It might not be necessary to do this as there are no "actions" or "outlets" declared in
  the WebView.h.  The workaround is to make a WebView using the CustomView in Gorm.

## Generative AI disclosure

This project was started about 1-2 years ago, but there were issues I couldn't figure out so it stalled.  As it turns out
codex (OpenAI's tool) was instrumental in helping me to figure out how to fix some of the issues that were responsible for
causing a difficult to find crash.

## Requirements

- GNUstep development environment with `gnustep-make`
- Objective-C and Objective-C++ compiler support
- `git`, `python3`, `cmake`, and `make`
- CEF libraries for runtime browser functionality

The framework can compile without CEF libraries by using local stubs, but the
actual browser runtime requires CEF to be downloaded and built.

## Quick Start

Set `GNUSTEP_MAKEFILES` if it is not already available in your environment:

```sh
export GNUSTEP_MAKEFILES="$(gnustep-config --variable=GNUSTEP_MAKEFILES)"
```

Build CEF, the framework, and the demo application:

```sh
./build.sh
```

Use `./build.sh --skip-cef` to rebuild only this repository after CEF has
already been prepared.

Install the built framework and applications into the GNUstep SYSTEM domain:

```sh
./build.sh --install
```

If the repository has not been built yet, `--install` builds it first and then
prompts for root privileges through `sudo` when needed.

Build only the framework:

```sh
cd WebKit
make
```

Build only the demo application:

```sh
cd Applications/WebBrowser
make
```

Install the framework with the normal GNUstep make target:

```sh
cd WebKit
make install
```

## CEF Setup

The top-level script downloads `cef-project` from GitHub, checks out pinned
commit `3aec7049cf63a36876d7a6ef538842d6af314482`, and builds the CEF artifacts
expected by the GNUstep makefiles:

```sh
./build.sh
```

To test another `cef-project` release or commit, override the pin for that run:

```sh
CEF_PROJECT_REF=<tag-or-commit> ./build.sh
```

The build system looks for CEF under:

```text
WebKit/cef_build/cef-project
```

After CEF is available, rebuild the framework:

```sh
./build.sh --skip-cef --clean
```

The lower-level compatibility entry points still work:

```sh
WebKit/bin/download_cef.sh
WebKit/bin/build.sh
```

If applications cannot locate the CEF shared libraries at runtime, source the
environment helper before running them:

```sh
source WebKit/webkit-env.sh
```

Alternatively, install the built CEF libraries into `/usr/local/lib`:

```sh
cd WebKit
./bin/install_cef_libs.sh
```

## Using `WebView`

Import the public header and add a `WebView` to an AppKit view hierarchy:

```objc
#import <WebKit/WebView.h>

WebView *webView = [[WebView alloc] initWithFrame:NSMakeRect(0, 0, 800, 600)];
[windowContentView addSubview:webView];
[webView loadURL:@"https://www.gnu.org"];
```

The public API includes:

- `loadURL:`
- `loadRequest:`
- `loadHTMLString:baseURL:`
- `reload`
- `stopLoading`
- `goBack` / `goForward`
- `canGoBack` / `canGoForward`
- `stringByEvaluatingJavaScriptFromString:`
- `evaluateJavaScript:completionHandler:`
- `mainFrameURL`
- `mainFrameTitle`

## Advantages

- Familiar Objective-C `WebView` API surface for GNUstep applications.
- Chromium rendering engine via CEF when available, enabling modern web compatibility.
- Dual-mode build: compiles with CEF when present and falls back to local stubs when not.
- Lazy CEF initialization at first use, reducing startup work for apps that do not immediately load web content.
- Simple GNUstep build integration (`make`, framework target, sample app target).
- Includes a working sample browser app (`Applications/WebBrowser`) that can be used as a reference.

## Caveats

- Full runtime browsing requires CEF binaries/libraries; stub mode compiles but does not provide a real browser engine.
- CEF setup and build can take significant time and disk space compared to pure Objective-C frameworks.
- Runtime linking may require environment setup (for example `LD_LIBRARY_PATH`) or installing CEF libs system-wide.
- Current integration is primarily tuned for GNUstep/Linux workflows; behavior and packaging on other platforms may need additional adjustments.
- JavaScript evaluation is currently execute-first; synchronous return values are limited and async completion behavior is basic.
- Popup/new-window behavior is framework-managed and may differ from desktop browsers depending on app policy.

## Documentation

Start with these files for more detail:

- `WebKit/Documentation/QUICK_START.md`
- `WebKit/Documentation/BUILD_CEF_OPTIONAL.md`
- `WebKit/Documentation/BUILD_APPLICATIONS.md`
- `WebKit/Documentation/CEF_INTEGRATION_GUIDE.md`

## Troubleshooting

If `make` reports that `GNUSTEP_MAKEFILES` is missing, install or initialize
GNUstep make support and export the value from `gnustep-config`.

If the framework builds but the demo application fails to link or run, verify
that CEF was built and that the CEF `Release` directory is available through the
framework rpath, `LD_LIBRARY_PATH`, or `/usr/local/lib`.

If CEF headers or libraries are not present, the framework build falls back to
stub compilation. This is useful for validating the Objective-C API but does not
provide an embedded browser at runtime.

## License

Source files in this repository are licensed under the GNU General Public
License, version 3 or later. See the notices in individual source files for
details.
