/* 
   Project: WebBrowser

   Author: Gregory John Casamento,,,

   Created: 2025-07-14 07:25:29 -0400 by heron
   
   Application Controller
*/

#import "AppController.h"

@implementation AppController

static const CGFloat URLBarPadding = 8.0;
static const CGFloat URLFieldHeight = 24.0;

+ (void) initialize
{
  NSMutableDictionary *defaults = [NSMutableDictionary dictionary];

  /*
   * Register your app's defaults here by adding objects to the
   * dictionary, eg
   *
   * [defaults setObject:anObject forKey:keyForThatObject];
   *
   */
  
  [[NSUserDefaults standardUserDefaults] registerDefaults: defaults];
  [[NSUserDefaults standardUserDefaults] synchronize];
}

- (id) init
{
  if ((self = [super init]))
    {
    }
  return self;
}

- (void) dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver: self];
  [_urlField release];
  [_webView release];
  [_window release];
  [super dealloc];
}

- (void) awakeFromNib
{
}

- (void) setupMainMenu
{
  NSString *appName;
  NSMenu *mainMenu;
  NSMenu *appMenu;
  NSMenu *fileMenu;
  NSMenuItem *appMenuItem;
  NSMenuItem *fileMenuItem;

  if ([NSApp mainMenu] != nil)
    {
      return;
    }

  appName = [[NSProcessInfo processInfo] processName];
  mainMenu = [[NSMenu alloc] initWithTitle: @""];

  appMenuItem = [[NSMenuItem alloc] initWithTitle: appName
                                           action: NULL
                                    keyEquivalent: @""];
  [mainMenu addItem: appMenuItem];
  [appMenuItem release];

  appMenu = [[NSMenu alloc] initWithTitle: appName];
  [appMenu addItemWithTitle: [NSString stringWithFormat: @"About %@", appName]
                     action: @selector(orderFrontStandardAboutPanel:)
              keyEquivalent: @""];
  [appMenu addItem: [NSMenuItem separatorItem]];
  [appMenu addItemWithTitle: [NSString stringWithFormat: @"Hide %@", appName]
                     action: @selector(hide:)
              keyEquivalent: @"h"];
  [appMenu addItem: [NSMenuItem separatorItem]];
  [appMenu addItemWithTitle: [NSString stringWithFormat: @"Quit %@", appName]
                     action: @selector(terminate:)
              keyEquivalent: @"q"];
  [mainMenu setSubmenu: appMenu forItem: appMenuItem];
  [appMenu release];

  fileMenuItem = [[NSMenuItem alloc] initWithTitle: @"File"
                                            action: NULL
                                     keyEquivalent: @""];
  [mainMenu addItem: fileMenuItem];
  [fileMenuItem release];

  fileMenu = [[NSMenu alloc] initWithTitle: @"File"];
  [fileMenu addItemWithTitle: @"Close"
                      action: @selector(performClose:)
               keyEquivalent: @"w"];
  [mainMenu setSubmenu: fileMenu forItem: fileMenuItem];
  [fileMenu release];

  [NSApp setMainMenu: mainMenu];
  [mainMenu release];
}

- (void) layoutBrowserViews
{
  NSView *contentView;
  NSRect contentBounds;
  NSRect urlFieldFrame;
  NSRect webViewFrame;
  CGFloat urlFieldY;
  CGFloat webViewHeight;

  if (_window == nil)
    {
      return;
    }

  contentView = [_window contentView];
  contentBounds = [contentView bounds];
  urlFieldY = MAX(URLBarPadding,
                  contentBounds.size.height - URLBarPadding - URLFieldHeight);
  webViewHeight = MAX(0.0, urlFieldY - URLBarPadding);

  urlFieldFrame = NSMakeRect(URLBarPadding,
                             urlFieldY,
                             MAX(0.0, contentBounds.size.width - (URLBarPadding * 2.0)),
                             URLFieldHeight);
  webViewFrame = NSMakeRect(0.0,
                            0.0,
                            contentBounds.size.width,
                            webViewHeight);

  [_urlField setFrame: urlFieldFrame];
  [_webView setFrame: webViewFrame];
}

- (NSString *) normalizedURLStringFromString: (NSString *)urlString
{
  NSString *trimmedString;
  NSCharacterSet *whitespace;

  whitespace = [NSCharacterSet whitespaceAndNewlineCharacterSet];
  trimmedString = [urlString stringByTrimmingCharactersInSet: whitespace];

  if ([trimmedString length] == 0)
    {
      return nil;
    }

  if ([trimmedString rangeOfString: @"://"].location == NSNotFound
      && [trimmedString rangeOfString: @":"].location == NSNotFound)
    {
      return [@"https://" stringByAppendingString: trimmedString];
    }

  return trimmedString;
}

- (void) updateURLFieldFromWebView
{
  NSString *urlString;

  urlString = [[_webView mainFrameURL] absoluteString];
  if (urlString == nil)
    {
      urlString = @"";
    }

  [_urlField setStringValue: urlString];
}

- (void) applicationDidFinishLaunching: (NSNotification *)aNotif
{
// Uncomment if your application is Renaissance-based
//  [NSBundle loadGSMarkupNamed: @"Main" owner: self];
  NSRect windowFrame;
  NSView *contentView;
  NSString *demoPath;

  [self setupMainMenu];

  if (_window == nil)
    {
      windowFrame = NSMakeRect(100, 100, 1024, 768);
      _window = [[NSWindow alloc] initWithContentRect: windowFrame
                                            styleMask: (NSTitledWindowMask
                                                        | NSClosableWindowMask
                                                        | NSMiniaturizableWindowMask
                                                        | NSResizableWindowMask)
                                              backing: NSBackingStoreBuffered
                                                defer: NO];
      [_window setTitle: @"CEF WebKit Demo"];
    }
  [_window setDelegate: self];

  contentView = [_window contentView];

  while ([[contentView subviews] count] > 0)
    {
      [[[contentView subviews] objectAtIndex: 0] removeFromSuperview];
    }

  [_window makeKeyAndOrderFront: self];
  [NSApp activateIgnoringOtherApps: YES];

  if (_urlField == nil)
    {
      _urlField = [[NSTextField alloc] initWithFrame: NSZeroRect];
      [_urlField setAutoresizingMask: 0];
      [_urlField setTarget: self];
      [_urlField setAction: @selector(urlFieldDidReturn:)];
      [_urlField setStringValue: @""];
    }

  if (_webView == nil)
    {
      _webView = [[WebView alloc] initWithFrame: NSZeroRect];
      [_webView setAutoresizingMask: 0];
      [[NSNotificationCenter defaultCenter] addObserver: self
                                               selector: @selector(webViewURLDidChange:)
                                                   name: WebViewURLDidChangeNotification
                                                 object: _webView];
    }
  [contentView addSubview: _webView];
  [contentView addSubview: _urlField];
  [self layoutBrowserViews];

  demoPath = [[NSBundle mainBundle] pathForResource: @"Demo" ofType: @"html"];
  if (demoPath != nil)
    {
      [_webView loadURL: [[NSURL fileURLWithPath: demoPath] absoluteString]];
    }
  else
    {
      [_webView loadURL: @"https://example.com"];
    }

  [self updateURLFieldFromWebView];
}

- (BOOL) applicationShouldTerminate: (id)sender
{
  return YES;
}

- (void) applicationWillTerminate: (NSNotification *)aNotif
{
}

- (void) windowDidResize: (NSNotification *)notification
{
  if ([notification object] == _window)
    {
      [self layoutBrowserViews];
    }
}

- (BOOL) application: (NSApplication *)application
	    openFile: (NSString *)fileName
{
  return NO;
}

- (IBAction) showPrefPanel: (id)sender
{
}

- (IBAction) urlFieldDidReturn: (id)sender
{
  NSString *urlString;

  urlString = [self normalizedURLStringFromString: [_urlField stringValue]];
  if (urlString == nil)
    {
      return;
    }

  [_urlField setStringValue: urlString];
  [_webView loadURL: urlString];
}

- (void) webViewURLDidChange: (NSNotification *)notification
{
  NSString *urlString;

  urlString = [[notification userInfo] objectForKey: WebViewURLKey];
  if (urlString == nil)
    {
      [self updateURLFieldFromWebView];
      return;
    }

  [_urlField setStringValue: urlString];
}

@end
