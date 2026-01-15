# CEF WebView Integration Guide

## Overview

This document describes the full integration of Chromium Embedded Framework (CEF) with the WebView component, providing a functional webview using CEF for GNUstep applications on macOS.

## Architecture

### Key Components

1. **WebView.h** - Public API interface for the webview
2. **WebView.mm** - Core implementation with CEF integration
3. **GNUmakefile.preamble** - Build configuration with CEF linking

### Class Hierarchy

```
WebView (Base Class)
└── GSWebView (Concrete Implementation)
    └── Uses GSCefClient (Event Handler)
        └── Uses GSCefApp (CEF Application)
        └── Uses GSRenderHandler (Graphics)
```

## Features Implemented

### 1. CEF Initialization

- **Global CEF setup** in `WebView.initialize`
- **Lazy initialization** - CEF initializes on first WebView creation
- **Proper configuration** of browser processes and cache paths
- **Automatic cleanup** on deallocation

### 2. Browser Creation

- **Synchronous browser creation** via `CefBrowserHost::CreateBrowserSync`
- **Window integration** with AppKit's NSView hierarchy
- **Coordinate translation** from view to window coordinates
- **Browser settings** for JavaScript and file access control

### 3. Navigation

- `loadRequest:` - Load from NSURLRequest
- `loadURL:` - Direct URL loading
- `loadHTMLString:baseURL:` - HTML content loading with data: URLs
- `reload` - Refresh current page
- `stopLoading` - Cancel loading
- `goBack` / `goForward` - Navigation history
- `canGoBack` / `canGoForward` - History availability checks

### 4. JavaScript Execution

- `stringByEvaluatingJavaScriptFromString:` - Fire-and-forget execution
- `evaluateJavaScript:completionHandler:` - Callback-based execution
- Asynchronous execution model with main thread callbacks
- Console message logging

### 5. Event Handling

- **Load events**: `OnLoadStart`, `OnLoadEnd`, `OnLoadError`
- **Display events**: Title changes
- **Lifecycle events**: Browser creation and cleanup
- **Main thread marshalling** via Grand Central Dispatch

### 6. Graphics Rendering

- **GSRenderHandler** for custom paint operations
- **Console logging** from JavaScript
- **Cursor management** capabilities

## Usage Example

```objc
#import "WebKit/WebView.h"

// Create a WebView programmatically
WebView *webView = [[WebView alloc] initWithFrame:CGRectMake(0, 0, 800, 600)];
[window addSubview:webView];

// Load a URL
[webView loadURL:@"https://www.example.com"];

// Load HTML
[webView loadHTMLString:@"<h1>Hello</h1>" baseURL:nil];

// JavaScript execution
[webView evaluateJavaScript:@"document.title" 
           completionHandler:^(NSString *result, NSError *error) {
    NSLog(@"Title: %@", result);
}];

// Navigation
[webView reload];
[webView goBack];
```

## Build Configuration

### GNUmakefile Setup

The build system is configured to:

- Include CEF headers from `cef_build/cef-project`
- Link against `libcef` and `libcef_dll_wrapper`
- Enable C++17 standard for Objective-C++ files
- Include necessary system libraries (-lpthread, -ldl, -lm)

### Building

```bash
cd /Volumes/heron/Development/libs-webkitcef/WebKit
make GNUSTEP_MAKEFILES=/path/to/gnustep-make/share/GNUstep/Makefiles
```

## Implementation Details

### Thread Safety

- All callbacks are marshalled to the main thread via GCD
- C++ CEF objects use reference counting (IMPLEMENT_REFCOUNTING)
- NSObject references are properly retained/released

### Memory Management

- Browser instances are properly closed in dealloc
- CEF shutdown handled by framework cleanup
- Callback handlers stored in std::map for lifecycle management

### CEF Client Handlers

**GSCefClient** implements:

- `CefDisplayHandler` - Title and display changes
- `CefLifeSpanHandler` - Browser lifecycle
- `CefLoadHandler` - Page loading events
- JavaScript result callbacks

**GSCefApp** implements:

- `CefBrowserProcessHandler` - Main process configuration
- `CefApp` - Application-level CEF integration

**GSRenderHandler** (optional):

- Custom paint operations
- Cursor management
- Console message logging

## Performance Considerations

1. **Lazy Initialization** - CEF initializes only when needed
2. **Browser Pooling** - Global browser count tracked for shutdown
3. **Synchronous Creation** - `CreateBrowserSync` ensures immediate browser availability
4. **Efficient Event Dispatching** - GCD for background-to-main-thread marshalling

## Known Limitations

1. **JavaScript Return Values** - `stringByEvaluatingJavaScriptFromString:` doesn't return actual results (fires asynchronously)
2. **Full return values** available through `evaluateJavaScript:completionHandler:` (basic implementation)
3. **Off-screen Rendering** - GSRenderHandler skeleton provided but not actively used
4. **Process Management** - Uses CEF's default process model

## Future Enhancements

1. Implement full JavaScript-to-native result bridge
2. Add message routing for bidirectional communication
3. Implement screenshot/PDF generation
4. Add full console API integration
5. Support for custom schemes and protocols
6. Implement WebViewDelegate pattern for callbacks

## Debugging

Enable CEF logging by setting environment variables:

```bash
export CEF_DEBUG=1
export CEF_LOG_SEVERITY=0  # LOGSEVERITY_VERBOSE
```

Console messages appear in NSLog output.

## References

- CEF Documentation: <https://magpcss.org/ceforum/viewtopic.php?f=6&t=11057>
- CEF API Headers: cef_build/cef-project/include/cef_*.h
- GNUstep Build System: <https://gnustep.github.io/>

## License

This integration maintains compatibility with:

- GNU General Public License v3+ (WebView wrapper)
- BSD License (CEF - Chromium Embedded Framework)
