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

#ifndef HAVE_CEF
  // Use CEF stubs when full CEF is not available
  #include "cef_stubs.h"
#else
  // Use real CEF headers when available
  // CEF binary root is in include path, so use relative includes
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
#endif

#if defined(HAVE_CEF) && defined(__linux__)
  #include <X11/Xlib.h>
  #ifdef Success
    #undef Success
  #endif
#endif

#import "WebView.h"

NSString *WebViewURLDidChangeNotification = @"WebViewURLDidChangeNotification";
NSString *WebViewURLKey = @"WebViewURL";

// Global CEF state
static bool g_cef_initialized = false;
static int g_browser_count = 0;
static NSTimer *g_cef_message_loop_timer = nil;
#if defined(HAVE_CEF) && defined(__linux__)
static Display *g_x_display = NULL;
#endif

// Custom V8 handler for JavaScript to native callbacks
class GSV8Handler : public CefV8Handler {
 public:
  explicit GSV8Handler(WebView* view) {}
  
  bool Execute(const CefString& name,
               CefRefPtr<CefV8Value> object,
               const CefV8ValueList& arguments,
               CefRefPtr<CefV8Value>& retval,
               CefString& exception) override {
    // Handle native JavaScript callbacks if needed
    return true;
  }
  
 private:
  IMPLEMENT_REFCOUNTING(GSV8Handler);
};

// Enhanced CEF Client with proper event handling
class GSCefClient : public CefClient,
                   public CefDisplayHandler,
                   public CefLifeSpanHandler,
                   public CefLoadHandler {
 public:
  using CefLifeSpanHandler::OnBeforePopup;

  explicit GSCefClient(WebView* view) 
    : web_view_(view), 
      browser_(),
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
    // Update view if needed - title available from browser
  }

  void OnAddressChange(CefRefPtr<CefBrowser> browser,
                       CefRefPtr<CefFrame> frame,
                       const CefString& url) override {
    if (web_view_ && frame->IsMain()) {
      std::string utf8_url = url.ToString();
      NSString* urlString = [NSString stringWithUTF8String:utf8_url.c_str()];
      [web_view_ performSelectorOnMainThread: @selector(urlChanged:)
                                  withObject: urlString
                               waitUntilDone: NO];
    }
  }

  // CefLifeSpanHandler methods
  void OnAfterCreated(CefRefPtr<CefBrowser> browser) override {
    browser_ = browser;
    g_browser_count++;
    
    if (web_view_) {
      [web_view_ performSelectorOnMainThread: @selector(browserCreated:)
                                  withObject: nil
                               waitUntilDone: NO];
    }
  }

  bool OnBeforePopup(CefRefPtr<CefBrowser> browser,
                     CefRefPtr<CefFrame> frame,
                     const CefString& target_url,
                     const CefString& target_frame_name,
                     WindowOpenDisposition target_disposition,
                     bool user_gesture,
                     const CefPopupFeatures& popupFeatures,
                     CefWindowInfo& windowInfo,
                     CefRefPtr<CefClient>& client,
                     CefBrowserSettings& settings,
                     CefRefPtr<CefDictionaryValue>& extra_info,
                     bool* no_javascript_access) {
    return HandlePopupInCurrentView(browser, target_url);
  }

  bool OnBeforePopup(CefRefPtr<CefBrowser> browser,
                     CefRefPtr<CefFrame> frame,
                     int popup_id,
                     const CefString& target_url,
                     const CefString& target_frame_name,
                     WindowOpenDisposition target_disposition,
                     bool user_gesture,
                     const CefPopupFeatures& popupFeatures,
                     CefWindowInfo& windowInfo,
                     CefRefPtr<CefClient>& client,
                     CefBrowserSettings& settings,
                     CefRefPtr<CefDictionaryValue>& extra_info,
                     bool* no_javascript_access) {
    return HandlePopupInCurrentView(browser, target_url);
  }

  bool HandlePopupInCurrentView(CefRefPtr<CefBrowser> browser,
                                const CefString& target_url) {
    // Keep target=_blank and window.open() navigation in the same browser.
    std::string url = target_url.ToString();
    if (!url.empty() && browser) {
      CefRefPtr<CefFrame> mainFrame = browser->GetMainFrame();
      if (mainFrame) {
        mainFrame->LoadURL(target_url);
      }
    }

    // Return true to cancel popup creation.
    return true;
  }

  bool DoClose(CefRefPtr<CefBrowser> browser) override {
    return false;
  }

  void OnBeforeClose(CefRefPtr<CefBrowser> browser) override {
    if (browser_->GetIdentifier() == browser->GetIdentifier()) {
      browser_ = CefRefPtr<CefBrowser>();
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
      [web_view_ performSelectorOnMainThread: @selector(loadingStarted)
                                  withObject: nil
                               waitUntilDone: NO];
    }
  }

  void OnLoadEnd(CefRefPtr<CefBrowser> browser,
                 CefRefPtr<CefFrame> frame,
                 int httpStatusCode) override {
    if (web_view_ && frame->IsMain()) {
      [web_view_ performSelectorOnMainThread: @selector(loadingEnded)
                                  withObject: nil
                               waitUntilDone: NO];
    }
  }

  void OnLoadError(CefRefPtr<CefBrowser> browser,
                   CefRefPtr<CefFrame> frame,
                   ErrorCode errorCode,
                   const CefString& errorText,
                   const CefString& failedUrl) override {
    if (web_view_ && frame->IsMain()) {
      std::string utf8_error = errorText.ToString();
      NSString* errorTextStr = [NSString stringWithUTF8String:utf8_error.c_str()];
      [web_view_ performSelectorOnMainThread: @selector(loadingFailed:)
                                  withObject: errorTextStr
                               waitUntilDone: NO];
    }
  }

  CefRefPtr<CefBrowser> GetBrowser() const {
    return browser_;
  }

  void StoreJavaScriptResult(int callback_id,
                             WebViewJavaScriptCompletionHandler handler) {
    js_result_callbacks_[callback_id] = handler;
  }

  IMPLEMENT_REFCOUNTING(GSCefClient);

 private:
  WebView* web_view_;
  CefRefPtr<CefBrowser> browser_;
  std::map<int, WebViewJavaScriptCompletionHandler> js_result_callbacks_;
};

// Render handler for off-screen rendering (OSR)
class GSRenderHandler : public CefRenderHandler {
 public:
  explicit GSRenderHandler(WebView* view) : web_view_(view) {}

  void GetViewRect(CefRefPtr<CefBrowser> browser, CefRect& rect) override {
    // Return the viewport rectangle
    if (web_view_) {
      NSRect nsRect = [web_view_ bounds];
      rect = CefRect(0, 0, (int)nsRect.size.width, (int)nsRect.size.height);
    }
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
                      cef_cursor_type_t type,
                      const CefCursorInfo& custom_cursor_info) {
    // Update cursor if needed
  }

  bool OnConsoleMessage(CefRefPtr<CefBrowser> browser,
                        cef_log_severity_t level,
                        const CefString& message,
                        const CefString& source,
                        int line) {
    // Log console messages from the page
    std::string utf8_msg = message.ToString();
    std::string utf8_src = source.ToString();
    NSString* msg = [NSString stringWithUTF8String:utf8_msg.c_str()];
    NSString* src = [NSString stringWithUTF8String:utf8_src.c_str()];
    NSLog(@"[CEF Console] %s:%d - %@", [src UTF8String], line, msg);
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

  void OnBeforeCommandLineProcessing(
      const CefString& process_type,
      CefRefPtr<CefCommandLine> command_line) override {
    command_line->AppendSwitch("disable-gpu");
    command_line->AppendSwitch("disable-gpu-compositing");
    command_line->AppendSwitch("no-sandbox");
  }

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

@interface GSCEFMessagePump : NSObject
+ (void)doMessageLoopWork:(NSTimer *)timer;
@end

@implementation GSCEFMessagePump
+ (void)doMessageLoopWork:(NSTimer *)timer {
  CefDoMessageLoopWork();
}
@end

extern "C" int WebKitCEFExecuteProcess(int argc, const char **argv);

extern "C" int WebKitCEFHandleProcess(int argc, const char **argv) {
  int i;

  for (i = 1; i < argc; i++) {
    if (strncmp(argv[i], "--type=", 7) == 0) {
      return WebKitCEFExecuteProcess(argc, argv);
    }
  }

  return -1;
}

extern "C" int WebKitCEFExecuteProcess(int argc, const char **argv) {
  CefMainArgs main_args(argc, const_cast<char**>(argv));
  CefRefPtr<CefApp> app = new GSCefApp();
  return CefExecuteProcess(main_args, app, NULL);
}

std::string GetExecutablePath() {
  NSString *path = [[NSBundle mainBundle] executablePath];

  if (path == nil) {
    NSString *arg0 = [[[NSProcessInfo processInfo] arguments] objectAtIndex: 0];
    path = [[[NSURL fileURLWithPath:arg0] URLByResolvingSymlinksInPath] path];
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

std::string GetCEFResourcePath() {
#ifdef WEBKIT_CEF_BINARY_PATH
  return std::string(WEBKIT_CEF_BINARY_PATH) + "/Resources";
#else
  return GetCEFPath();
#endif
}

std::string GetCEFLocalesPath() {
  return GetCEFResourcePath() + "/locales";
}

std::string DataURLForHTML(const std::string& html) {
  CefString encoded = CefURIEncode(CefString(html), false);
  return "data:text/html;charset=utf-8," + encoded.ToString();
}

void LoadHTML(CefRefPtr<CefFrame> frame, const std::string& html) {
  if (!frame) return;

  frame->LoadURL(DataURLForHTML(html));
}

CefMainArgs GetMainArgsFromNSProcessInfo() {
  NSArray *args = [[NSProcessInfo processInfo] arguments];
  int argc = (int)[args count];

  // Allocate argv array
  char** argv = new char*[argc + 1];
  for (int i = 0; i < argc; ++i) {
    const char* utf8 = [[args objectAtIndex: i] UTF8String];
    argv[i] = strdup(utf8);
  }
  argv[argc] = NULL;

  // Return CefMainArgs
  return CefMainArgs(argc, argv);
}

static void InitializeCEFIfNeeded(void) {
  if (!g_cef_initialized) {
    CefMainArgs main_args = GetMainArgsFromNSProcessInfo();
    CefSettings settings;

    CefString(&settings.browser_subprocess_path).FromString(GetExecutablePath());
    CefString(&settings.cache_path).FromString(GetCachePath());
    CefString(&settings.resources_dir_path).FromString(GetCEFResourcePath());
    CefString(&settings.locales_dir_path).FromString(GetCEFLocalesPath());
    settings.no_sandbox = true;

    CefRefPtr<CefApp> app = new GSCefApp();
    if (CefInitialize(main_args, settings, app, NULL)) {
      g_cef_initialized = true;
      if (g_cef_message_loop_timer == nil) {
        g_cef_message_loop_timer =
          [[NSTimer scheduledTimerWithTimeInterval: 0.01
                                           target: [GSCEFMessagePump class]
                                         selector: @selector(doMessageLoopWork:)
                                         userInfo: nil
                                          repeats: YES] retain];
      }
      NSLog(@"CEF initialized successfully");
    } else {
      NSLog(@"Failed to initialize CEF");
    }
  }
}

@interface GSWebView : WebView
{
  CefRefPtr<CefBrowser> browser_;
  CefRefPtr<GSCefClient> client_;
  BOOL isInitialized_;
  BOOL isLoading_;
  NSString* currentURL_;
  NSString* pageTitle_;
  NSString* pendingURL_;
  NSString* pendingHTML_;
}
- (void)initializeBrowserIfNeeded;
- (void)browserViewWasResized;
- (NSRect)browserChildWindowRect;
@end

@implementation WebView

+ (void)initialize {
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

- (void)loadURL:(NSString*)url {
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

- (void)evaluateJavaScript:(NSString*)script 
           completionHandler:(WebViewJavaScriptCompletionHandler)completionHandler {
  // Base implementation - overridden in GSWebView
}

- (NSURL*)mainFrameURL {
  return nil;
}

- (NSString*)mainFrameTitle {
  return @"";
}

// Internal callback methods - default implementations
- (void)browserCreated:(void*)browser {
  // Base implementation - overridden in GSWebView
}

- (void)loadingStarted {
  // Base implementation - overridden in GSWebView
}

- (void)loadingEnded {
  // Base implementation - overridden in GSWebView
}

- (void)loadingFailed:(NSString*)error {
  // Base implementation - overridden in GSWebView
}

- (void)urlChanged:(NSString*)url {
  // Base implementation - overridden in GSWebView
}

@end

@implementation GSWebView

- (void)postURLDidChangeNotification {
  NSDictionary *userInfo;

  userInfo = nil;
  if (currentURL_) {
    userInfo = [NSDictionary dictionaryWithObject: currentURL_
                                           forKey: WebViewURLKey];
  }

  [[NSNotificationCenter defaultCenter] postNotificationName: WebViewURLDidChangeNotification
                                                      object: self
                                                    userInfo: userInfo];
}

- (id)initWithFrame:(NSRect)frameRect {
  self = [super initWithFrame:frameRect];
  if (self) {
    isInitialized_ = NO;
    isLoading_ = NO;
    currentURL_ = nil;
    pageTitle_ = nil;
    pendingURL_ = nil;
    pendingHTML_ = nil;
  }
  return self;
}

- (void)awakeFromNib {
  [super awakeFromNib];
}

- (void)viewDidMoveToWindow {
  [super viewDidMoveToWindow];
}

- (void)initializeBrowserIfNeeded {
  if (isInitialized_) {
    return;  // Already initialized
  }
  
  NSLog(@"GSWebView: Initializing CEF browser");
  
  NSWindow *window = [self window];
  
  if (!window) {
    NSLog(@"Warning: WebView not in a window yet");
    return;
  }

  InitializeCEFIfNeeded();
  
  // Create CEF window info
  CefWindowInfo window_info;
  
  NSRect windowRect = [self browserChildWindowRect];
  
  // CEF on GNUstep/Linux expects the native X window handle, not an NSView.
  window_info.SetAsChild(
    (CefWindowHandle)[window windowRef],
    CefRect(
      (int)windowRect.origin.x,
      (int)windowRect.origin.y,
      (int)windowRect.size.width,
      (int)windowRect.size.height
    )
  );
  
  // Create the CEF client
    client_ = new GSCefClient(self);
  
  // Configure browser settings
  CefBrowserSettings browser_settings;
  // Most browser settings are controlled via CEF command line
  // for details see CEF documentation
  
  CefString start_url = "about:blank";

  if (pendingHTML_) {
    std::string html = [pendingHTML_ UTF8String];
    start_url = DataURLForHTML(html);
  } else if (pendingURL_) {
    start_url = std::string([pendingURL_ UTF8String]);
  }
  
  // Create the browser
  CefRefPtr<CefDictionaryValue> extraInfo;
  CefRefPtr<CefRequestContext> requestContext;

  browser_ = CefBrowserHost::CreateBrowserSync(
    window_info,
    client_,
    start_url,
    browser_settings,
    extraInfo,
    requestContext
  );
  
  if (browser_) {
    NSLog(@"CEF browser created successfully");
    isInitialized_ = YES;
  } else {
    NSLog(@"Failed to create CEF browser");
  }
}

- (void)browserCreated:(void*)browser {
  NSLog(@"Browser created callback");
}

- (void)loadingStarted {
  isLoading_ = YES;
  NSLog(@"Page loading started");
  [self urlChanged: [[self mainFrameURL] absoluteString]];
}

- (void)loadingEnded {
  isLoading_ = NO;
  NSLog(@"Page loading ended");
  [self urlChanged: [[self mainFrameURL] absoluteString]];
}

- (void)loadingFailed:(NSString*)error {
  isLoading_ = NO;
  NSLog(@"Page loading failed: %@", error);
}

- (void)urlChanged:(NSString*)url {
  if (url == nil) {
    return;
  }

  if (currentURL_) {
    [currentURL_ release];
  }
  currentURL_ = [url retain];
  [self postURLDidChangeNotification];
}

- (void)dealloc {
  if (browser_) {
    CefRefPtr<CefBrowserHost> host = browser_->GetHost();
    if (host) {
      host->CloseBrowser(true);
    }
    browser_ = CefRefPtr<CefBrowser>();
  }
  
  client_ = CefRefPtr<GSCefClient>();
  
  if (currentURL_) {
    [currentURL_ release];
  }
  
  if (pageTitle_) {
    [pageTitle_ release];
  }

  if (pendingURL_) {
    [pendingURL_ release];
  }

  if (pendingHTML_) {
    [pendingHTML_ release];
  }
  
  [super dealloc];
}

- (NSRect)browserChildWindowRect {
  NSWindow *window;
  NSView *contentView;
  NSRect windowRect;
  CGFloat contentHeight;

  window = [self window];
  if (window == nil) {
    return [self bounds];
  }

  contentView = [window contentView];
  windowRect = [self convertRect: [self bounds] toView: nil];
  contentHeight = [contentView bounds].size.height;

  windowRect.origin.y = MAX(0.0, contentHeight - NSMaxY(windowRect));
  windowRect.size.width = MAX(0.0, windowRect.size.width);
  windowRect.size.height = MAX(0.0, windowRect.size.height);

  return windowRect;
}

- (void)browserViewWasResized {
  if (!browser_ || !isInitialized_) {
    return;
  }

  CefRefPtr<CefBrowserHost> host = browser_->GetHost();
  if (host) {
#if defined(HAVE_CEF) && defined(__linux__)
    NSRect windowRect = [self browserChildWindowRect];
    CefWindowHandle childWindow = host->GetWindowHandle();

    if (childWindow) {
      if (g_x_display == NULL) {
        g_x_display = XOpenDisplay(NULL);
      }

      if (g_x_display != NULL) {
        XMoveResizeWindow(g_x_display,
                          childWindow,
                          (int)windowRect.origin.x,
                          (int)windowRect.origin.y,
                          (unsigned int)windowRect.size.width,
                          (unsigned int)windowRect.size.height);
        XFlush(g_x_display);
      }
    }
#endif
    host->NotifyMoveOrResizeStarted();
    host->WasResized();
  }
}

- (void)setFrame:(NSRect)frameRect {
  [super setFrame: frameRect];
  [self browserViewWasResized];
}

- (void)setFrameSize:(NSSize)newSize {
  [super setFrameSize: newSize];
  [self browserViewWasResized];
}

- (void)resizeSubviewsWithOldSize:(NSSize)oldSize {
  [super resizeSubviewsWithOldSize:oldSize];
  [self browserViewWasResized];
}

- (void)loadRequest:(NSURLRequest*)request {
  [self initializeBrowserIfNeeded];

  if (!browser_ || !isInitialized_) {
    NSLog(@"Warning: Cannot load request - browser not initialized");
    return;
  }
  
  NSString* urlString = [[request URL] absoluteString];
  [self loadURL:urlString];
}

- (void)loadHTMLString:(NSString*)string baseURL:(NSURL*)baseURL {
  BOOL wasInitialized = isInitialized_;

  if (pendingHTML_) {
    [pendingHTML_ release];
  }
  pendingHTML_ = [string retain];

  if (pendingURL_) {
    [pendingURL_ release];
    pendingURL_ = nil;
  }

  [self initializeBrowserIfNeeded];

  if (!browser_ || !isInitialized_) {
    NSLog(@"Warning: Cannot load HTML - browser not initialized");
    return;
  }

  if (!wasInitialized) {
    return;
  }
  
  std::string html = [string UTF8String];
  CefRefPtr<CefFrame> frame = browser_->GetMainFrame();
  
  if (frame) {
    LoadHTML(frame, html);
  }
}

- (void)loadURL:(NSString*)url {
  BOOL wasInitialized = isInitialized_;

  if (pendingURL_) {
    [pendingURL_ release];
  }
  pendingURL_ = [url retain];

  if (pendingHTML_) {
    [pendingHTML_ release];
    pendingHTML_ = nil;
  }

  [self initializeBrowserIfNeeded];

  if (!browser_ || !isInitialized_) {
    NSLog(@"Warning: Cannot load URL - browser not initialized");
    return;
  }

  if (!wasInitialized) {
    if (currentURL_) {
      [currentURL_ release];
    }
    currentURL_ = [url retain];
    [self postURLDidChangeNotification];
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
  [self postURLDidChangeNotification];
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
      NSDictionary *userInfo = [NSDictionary dictionaryWithObject: @"Browser not initialized"
                                                           forKey: NSLocalizedDescriptionKey];
      NSError* error = [NSError errorWithDomain:@"WebView" 
                                           code:-1 
                                       userInfo:userInfo];
      completionHandler(nil, error);
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
    completionHandler(@"", nil);
  }
}

- (NSURL*)mainFrameURL {
  if (!browser_ || !isInitialized_) {
    if (currentURL_) {
      return [NSURL URLWithString: currentURL_];
    }
    return nil;
  }
  
  CefRefPtr<CefFrame> frame = browser_->GetMainFrame();
  if (!frame) {
    return nil;
  }
  
  std::string url = frame->GetURL().ToString();
  NSString* urlStr = [NSString stringWithUTF8String:url.c_str()];
  if (urlStr == nil || [urlStr length] == 0) {
    if (currentURL_) {
      return [NSURL URLWithString: currentURL_];
    }
    return nil;
  }
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
