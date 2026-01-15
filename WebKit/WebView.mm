/* WebView
 *
 * This class is WebView
 *
 * Copyright (C) 2025 Free Software Foundation, Inc.
 *
 * Author:      Gregory John Casamento <greg.casamento@gmail.com>
 * Date:        2025
 *
 * This file is part of GNUstep.
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 3 of the License, or
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02111 USA.
 */

/* This is under the LGPL */

#include <iostream>
#include <map>
#include <memory>

#include "include/cef_app.h"
#include "include/cef_browser.h"
#include "include/cef_command_line.h"
#include "include/cef_client.h"
#include "include/cef_render_handler.h"
#include "include/cef_v8.h"
#include "include/cef_values.h"
#include "include/wrapper/cef_message_router.h"
#include "include/cef_browser_process_handler.h"
#include "include/cef_parser.h"

#import "WebView.h"

// Global CEF state
static bool g_cef_initialized = false;
static int g_browser_count = 0;

// JavaScript result callback structure
class JavaScriptResultCallback {
 public:
  typedef void (^CompletionHandler)(NSString* result);
  
  JavaScriptResultCallback(CompletionHandler handler) 
    : handler_([handler copy]) {}
  
  ~JavaScriptResultCallback() {
    if (handler_) {
      [handler_ release];
    }
  }
  
  void Execute(const CefString& result) {
    if (handler_) {
      NSString* resultStr = [NSString stringWithUTF8String:result.c_str()];
      dispatch_async(dispatch_get_main_queue(), ^{
        handler_(resultStr);
      });
    }
  }
  
 private:
  CompletionHandler handler_;
};

// Custom V8 handler for JavaScript to native callbacks
class GSV8Handler : public CefV8Handler {
 public:
  explicit GSV8Handler(WebView* view) : web_view_(view) {}
  
  bool Execute(const CefString& name,
               CefRefPtr<CefV8Value> object,
               const CefV8ValueList& arguments,
               CefRefPtr<CefV8Value>& retval,
               CefString& exception) override {
    // Handle native JavaScript callbacks if needed
    return true;
  }
  
 private:
  WebView* web_view_;
  IMPLEMENT_REFCOUNTING(GSV8Handler);
};

// Enhanced CEF Client with proper event handling
class GSCefClient : public CefClient,
                   public CefDisplayHandler,
                   public CefLifeSpanHandler,
                   public CefLoadHandler {
 public:
  explicit GSCefClient(WebView* view) 
    : web_view_(view), 
      browser_(nullptr),
      js_result_callbacks_() {
  }

  // CefClient methods
  CefRefPtr<CefDisplayHandler> GetDisplayHandler() override {
    return this;
  }

  CefRefPtr<CefLifeSpanHandler> GetLifeSpanHandler() override {
    return this;
  }

  CefRefPtr<CefLoadHandler> GetLoadHandler() override {
    return this;
  }

  // CefDisplayHandler methods
  void OnTitleChange(CefRefPtr<CefBrowser> browser,
                     const CefString& title) override {
    if (web_view_) {
      NSString* titleStr = [NSString stringWithUTF8String:title.c_str()];
      dispatch_async(dispatch_get_main_queue(), ^{
        // Update view if needed
      });
    }
  }

  // CefLifeSpanHandler methods
  void OnAfterCreated(CefRefPtr<CefBrowser> browser) override {
    browser_ = browser;
    g_browser_count++;
    
    if (web_view_) {
      dispatch_async(dispatch_get_main_queue(), ^{
        [web_view_ browserCreated:browser_];
      });
    }
  }

  bool DoClose(CefRefPtr<CefBrowser> browser) override {
    return false;
  }

  void OnBeforeClose(CefRefPtr<CefBrowser> browser) override {
    if (browser_->GetIdentifier() == browser->GetIdentifier()) {
      browser_ = nullptr;
      g_browser_count--;
      
      if (g_browser_count == 0) {
        CefQuitMessageLoop();
      }
    }
  }

  // CefLoadHandler methods
  void OnLoadStart(CefRefPtr<CefBrowser> browser,
                   CefRefPtr<CefFrame> frame,
                   TransitionType transition_type) override {
    if (web_view_ && frame->IsMain()) {
      dispatch_async(dispatch_get_main_queue(), ^{
        [web_view_ loadingStarted];
      });
    }
  }

  void OnLoadEnd(CefRefPtr<CefBrowser> browser,
                 CefRefPtr<CefFrame> frame,
                 int httpStatusCode) override {
    if (web_view_ && frame->IsMain()) {
      dispatch_async(dispatch_get_main_queue(), ^{
        [web_view_ loadingEnded];
      });
    }
  }

  void OnLoadError(CefRefPtr<CefBrowser> browser,
                   CefRefPtr<CefFrame> frame,
                   ErrorCode errorCode,
                   const CefString& errorText,
                   const CefString& failedUrl) override {
    if (web_view_ && frame->IsMain()) {
      NSString* errorTextStr = [NSString stringWithUTF8String:errorText.c_str()];
      dispatch_async(dispatch_get_main_queue(), ^{
        [web_view_ loadingFailed:errorTextStr];
      });
    }
  }

  CefRefPtr<CefBrowser> GetBrowser() const {
    return browser_;
  }

  void StoreJavaScriptResult(int callback_id, 
                             JavaScriptResultCallback::CompletionHandler handler) {
    js_result_callbacks_[callback_id] = 
      std::make_unique<JavaScriptResultCallback>(handler);
  }

  IMPLEMENT_REFCOUNTING(GSCefClient);

 private:
  WebView* web_view_;
  CefRefPtr<CefBrowser> browser_;
  std::map<int, std::unique_ptr<JavaScriptResultCallback>> js_result_callbacks_;
};

// Render handler for off-screen rendering (OSR)
class GSRenderHandler : public CefRenderHandler {
 public:
  explicit GSRenderHandler(WebView* view) : web_view_(view) {}

  bool GetViewRect(CefRefPtr<CefBrowser> browser, CefRect& rect) override {
    // Return the viewport rectangle
    if (web_view_) {
      NSRect nsRect = [web_view_ bounds];
      rect = CefRect(0, 0, (int)nsRect.size.width, (int)nsRect.size.height);
      return true;
    }
    return false;
  }

  void OnPaint(CefRefPtr<CefBrowser> browser,
               PaintElementType type,
               const RectList& dirtyRects,
               const void* buffer,
               int width,
               int height) override {
    // Handle paint events if using off-screen rendering
    // This can be implemented for custom rendering
  }

  void OnCursorChange(CefRefPtr<CefBrowser> browser,
                      CefCursorHandle cursor,
                      CursorType type,
                      const CefCursorInfo& custom_cursor_info) override {
    // Update cursor if needed
  }

  bool OnConsoleMessage(CefRefPtr<CefBrowser> browser,
                        cef_log_severity_t level,
                        const CefString& message,
                        const CefString& source,
                        int line) override {
    // Log console messages from the page
    NSString* msg = [NSString stringWithUTF8String:message.c_str()];
    NSString* src = [NSString stringWithUTF8String:source.c_str()];
    NSLog(@"[CEF Console] %s:%d - %@", src.UTF8String, line, msg);
    return false;
  }

  IMPLEMENT_REFCOUNTING(GSRenderHandler);

 private:
  WebView* web_view_;
};

// CEF App implementation with proper initialization
class GSCefApp : public CefApp, public CefBrowserProcessHandler {
 public:
  GSCefApp() {}

  CefRefPtr<CefBrowserProcessHandler> GetBrowserProcessHandler() override {
    return this;
  }

  void OnBeforeChildProcessLaunch(
      CefRefPtr<CefCommandLine> command_line) override {
    // Configure child process command line
  }

  void OnContextInitialized() override {
    // Called after the context is initialized
  }

  IMPLEMENT_REFCOUNTING(GSCefApp);
};


std::string GetExecutablePath() {
  NSString *path = [[NSBundle mainBundle] executablePath];

  if (path == nil) {
    NSString *arg0 = [[NSProcessInfo processInfo] arguments][0];
    path = [[NSURL fileURLWithPath:arg0] URLByResolvingSymlinksInPath].path;
  }

  NSLog(@"CEF Executable path: %@", path);
  return [path UTF8String];
}

std::string GetCachePath() {
  NSArray *cachePaths = NSSearchPathForDirectoriesInDomains(
      NSCachesDirectory, NSUserDomainMask, YES);
  NSString *cachePath = [cachePaths objectAtIndex:0];
  return [cachePath UTF8String];
}

std::string GetCEFPath() {
  // Look for CEF framework in the main bundle's Frameworks directory
  NSString *frameworkPath = [[NSBundle mainBundle] 
    pathForResource:@"cef" ofType:@"framework"];
  
  if (!frameworkPath) {
    // Fall back to standard framework location
    frameworkPath = @"/Library/Frameworks/cef.framework";
  }
  
  NSLog(@"CEF Framework path: %@", frameworkPath);
  return [frameworkPath UTF8String];
}

void LoadHTML(CefRefPtr<CefFrame> frame, const std::string& html) {
  if (!frame) return;

  // For HTML content, use data: URL with proper encoding
  CefString encoded = CefURIEncode(CefString(html), false);
  std::string data_url = "data:text/html;charset=utf-8," + encoded.ToString();
  frame->LoadURL(data_url);
}

CefMainArgs GetMainArgsFromNSProcessInfo() {
  NSArray<NSString *> *args = [[NSProcessInfo processInfo] arguments];
  int argc = (int)[args count];

  // Allocate argv array
  char** argv = new char*[argc];
  for (int i = 0; i < argc; ++i) {
    const char* utf8 = [args[i] UTF8String];
    argv[i] = strdup(utf8);
  }

  // Return CefMainArgs
  return CefMainArgs(argc, argv);
}

@interface GSWebView : WebView
{
  CefRefPtr<CefBrowser> browser_;
  CefRefPtr<GSCefClient> client_;
  BOOL isInitialized_;
  BOOL isLoading_;
  NSString* currentURL_;
  NSString* pageTitle_;
}
@end

@implementation WebView

+ (void)initialize {
  // Initialize CEF once when the class is first used
  static BOOL initialized = NO;
  if (!initialized) {
    initialized = YES;
    
    if (!g_cef_initialized) {
      CefMainArgs main_args = GetMainArgsFromNSProcessInfo();
      CefSettings settings;
      
      // Set CEF paths
      CefString(&settings.browser_subprocess_path).FromString(GetExecutablePath());
      CefString(&settings.cache_path).FromString(GetCachePath());
      
      // Initialize CEF
      if (CefInitialize(main_args, settings, new GSCefApp(), nullptr)) {
        g_cef_initialized = true;
        NSLog(@"CEF initialized successfully");
      } else {
        NSLog(@"Failed to initialize CEF");
      }
    }
  }
}

+ (id) allocWithZone: (NSZone *)zone {
  if (self == [WebView class]) {
    return [GSWebView allocWithZone: zone];
  }
  return [super allocWithZone: zone];
}

- (void)loadRequest: (NSURLRequest*)request {
  // Base implementation - overridden in GSWebView
}

- (void)loadHTMLString: (NSString*)string baseURL: (NSURL*)baseURL {
  // Base implementation - overridden in GSWebView
}

- (void)reload {
  // Base implementation - overridden in GSWebView
}

- (void)stopLoading {
  // Base implementation - overridden in GSWebView
}

- (void)goBack {
  // Base implementation - overridden in GSWebView
}

- (void)goForward {
  // Base implementation - overridden in GSWebView
}

- (BOOL)canGoBack {
  return NO;
}

- (BOOL)canGoForward {
  return NO;
}

- (NSString*)stringByEvaluatingJavaScriptFromString:(NSString*)script {
  return @"";
}

- (NSURL*)mainFrameURL {
  return nil;
}

- (NSString*)mainFrameTitle {
  return @"";
}

@end

- (BOOL)canGoForward
{
  return NO;
}

- (NSString*) stringByEvaluatingJavaScriptFromString: (NSString*)script
{
  return @"";
}

- (NSURL*)mainFrameURL
{
  return nil;
}

- (NSString*)mainFrameTitle
{
  return @"";
}

@end

@implementation GSWebView

- (id)initWithFrame:(NSRect)frameRect {
  self = [super initWithFrame:frameRect];
  if (self) {
    isInitialized_ = NO;
    isLoading_ = NO;
    currentURL_ = nil;
    pageTitle_ = nil;
  }
  return self;
}

- (void)awakeFromNib {
  [super awakeFromNib];
  
  if (isInitialized_) {
    return;  // Already initialized
  }
  
  NSLog(@"GSWebView: Initializing CEF browser");
  
  // Ensure CEF is initialized
  [WebView initialize];
  
  NSRect frameRect = [self frame];
  NSWindow *window = [self window];
  
  if (!window) {
    NSLog(@"Warning: WebView not in a window yet");
    return;
  }
  
  // Create CEF window info
  CefWindowInfo window_info;
  
  // Convert view coordinates to window coordinates
  NSRect windowRect = [self convertRect:frameRect toView:nil];
  
  // For macOS, set the parent view
  window_info.SetAsChild(
    (CefWindowHandle)[window contentView],
    {
      (int)windowRect.origin.x,
      (int)windowRect.origin.y,
      (int)windowRect.size.width,
      (int)windowRect.size.height
    }
  );
  
  // Create the CEF client
  client_ = new GSCefClient(self);
  
  // Configure browser settings
  CefBrowserSettings browser_settings;
  browser_settings.web_security_disabled = false;
  browser_settings.file_access_from_file_urls_allowed = true;
  browser_settings.universal_access_from_file_urls_allowed = true;
  
  // Default URL
  CefString start_url = "about:blank";
  
  // Create the browser
  browser_ = CefBrowserHost::CreateBrowserSync(
    window_info,
    client_,
    start_url,
    browser_settings,
    nullptr,
    nullptr
  );
  
  if (browser_) {
    NSLog(@"CEF browser created successfully");
    isInitialized_ = YES;
  } else {
    NSLog(@"Failed to create CEF browser");
  }
}

- (void)browserCreated:(CefRefPtr<CefBrowser>)browser {
  NSLog(@"Browser created callback");
}

- (void)loadingStarted {
  isLoading_ = YES;
  NSLog(@"Page loading started");
}

- (void)loadingEnded {
  isLoading_ = NO;
  NSLog(@"Page loading ended");
}

- (void)loadingFailed:(NSString*)error {
  isLoading_ = NO;
  NSLog(@"Page loading failed: %@", error);
}

- (void)dealloc {
  if (browser_) {
    CefRefPtr<CefBrowserHost> host = browser_->GetHost();
    if (host) {
      host->CloseBrowser(true);
    }
    browser_ = nullptr;
  }
  
  client_ = nullptr;
  
  if (currentURL_) {
    [currentURL_ release];
  }
  
  if (pageTitle_) {
    [pageTitle_ release];
  }
  
  [super dealloc];
}

- (void)resizeSubviewsWithOldSize:(NSSize)oldSize {
  [super resizeSubviewsWithOldSize:oldSize];
  
  if (!browser_ || !isInitialized_) {
    return;
  }
  
  NSRect rect = [self frame];
  CefRefPtr<CefBrowserHost> host = browser_->GetHost();
  if (host) {
    // Notify CEF of the resize
    host->WasResized();
  }
}

- (void)loadRequest:(NSURLRequest*)request {
  if (!browser_ || !isInitialized_) {
    NSLog(@"Warning: Cannot load request - browser not initialized");
    return;
  }
  
  NSString* urlString = [[request URL] absoluteString];
  [self loadURL:urlString];
}

- (void)loadHTMLString:(NSString*)string baseURL:(NSURL*)baseURL {
  if (!browser_ || !isInitialized_) {
    NSLog(@"Warning: Cannot load HTML - browser not initialized");
    return;
  }
  
  std::string html = [string UTF8String];
  CefRefPtr<CefFrame> frame = browser_->GetMainFrame();
  
  if (frame) {
    LoadHTML(frame, html);
  }
}

- (void)loadURL:(NSString*)url {
  if (!browser_ || !isInitialized_) {
    NSLog(@"Warning: Cannot load URL - browser not initialized");
    return;
  }
  
  std::string urlStr = [url UTF8String];
  CefRefPtr<CefFrame> frame = browser_->GetMainFrame();
  
  if (frame) {
    frame->LoadURL(urlStr);
  }
  
  if (currentURL_) {
    [currentURL_ release];
  }
  currentURL_ = [url retain];
}

- (void)reload {
  if (browser_ && isInitialized_) {
    browser_->Reload();
  }
}

- (void)stopLoading {
  if (browser_ && isInitialized_) {
    browser_->StopLoad();
  }
}

- (void)goBack {
  if (browser_ && isInitialized_) {
    browser_->GoBack();
  }
}

- (void)goForward {
  if (browser_ && isInitialized_) {
    browser_->GoForward();
  }
}

- (BOOL)canGoBack {
  return (browser_ && isInitialized_) ? browser_->CanGoBack() : NO;
}

- (BOOL)canGoForward {
  return (browser_ && isInitialized_) ? browser_->CanGoForward() : NO;
}

- (NSString*)stringByEvaluatingJavaScriptFromString:(NSString*)script {
  if (!browser_ || !isInitialized_) {
    return @"";
  }
  
  std::string jsCode = [script UTF8String];
  CefRefPtr<CefFrame> frame = browser_->GetMainFrame();
  
  if (frame) {
    frame->ExecuteJavaScript(jsCode, frame->GetURL(), 0);
  }
  
  // Note: This is asynchronous - results require a callback mechanism
  return @"";
}

- (void)evaluateJavaScript:(NSString*)script 
           completionHandler:(WebViewJavaScriptCompletionHandler)completionHandler {
  if (!browser_ || !isInitialized_) {
    if (completionHandler) {
      NSError* error = [NSError errorWithDomain:@"WebView" 
                                           code:-1 
                                       userInfo:@{NSLocalizedDescriptionKey: @"Browser not initialized"}];
      dispatch_async(dispatch_get_main_queue(), ^{
        completionHandler(nil, error);
      });
    }
    return;
  }
  
  // For now, we execute without waiting for result
  // Full implementation would require a visit to the renderer process
  std::string jsCode = [script UTF8String];
  CefRefPtr<CefFrame> frame = browser_->GetMainFrame();
  
  if (frame) {
    frame->ExecuteJavaScript(jsCode, frame->GetURL(), 0);
  }
  
  if (completionHandler) {
    dispatch_async(dispatch_get_main_queue(), ^{
      completionHandler(@"", nil);
    });
  }
}

- (NSURL*)mainFrameURL {
  if (!browser_ || !isInitialized_) {
    return nil;
  }
  
  CefRefPtr<CefFrame> frame = browser_->GetMainFrame();
  if (!frame) {
    return nil;
  }
  
  std::string url = frame->GetURL().ToString();
  NSString* urlStr = [NSString stringWithUTF8String:url.c_str()];
  return [NSURL URLWithString:urlStr];
}

- (NSString*)mainFrameTitle {
  if (!browser_ || !isInitialized_) {
    return @"";
  }
  
  if (pageTitle_) {
    return pageTitle_;
  }
  
  return @"CEF WebView";
}

@end
