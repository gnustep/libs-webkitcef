# Quick Start

This guide gets you from source checkout to a running demo quickly.

For full CEF setup details, use [BUILD_CEF_OPTIONAL.md](BUILD_CEF_OPTIONAL.md).

## 1) Build Framework and Demo

```sh
cd /Volumes/heron/Development/libs-webkitcef
make
```

Build only the framework:

```sh
cd /Volumes/heron/Development/libs-webkitcef/WebKit
make
```

Build only the demo app:

```sh
cd /Volumes/heron/Development/libs-webkitcef/Applications/WebBrowser
make
```

## 2) Enable Full Browser Runtime (CEF)

From the `WebKit` directory:

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

## 3) Runtime Library Setup

Use either:

```sh
source /Volumes/heron/Development/libs-webkitcef/WebKit/webkit-env.sh
```

or:

```sh
cd /Volumes/heron/Development/libs-webkitcef/WebKit
./bin/install_cef_libs.sh
```

## 4) Minimal Usage Example

```objc
#import <WebKit/WebView.h>

WebView *webView = [[WebView alloc] initWithFrame:NSMakeRect(0, 0, 800, 600)];
[windowContentView addSubview:webView];
[webView loadURL:@"https://www.gnu.org"];
```

## 5) Build API Documentation

```sh
cd /Volumes/heron/Development/libs-webkitcef/WebKit/Documentation
make
```

## Notes

- If CEF is not present, the framework builds in stub mode.
- Stub mode is useful for API-level development but does not provide real web rendering.
