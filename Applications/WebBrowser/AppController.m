/* 
   Project: WebBrowser

   Author: Gregory John Casamento,,,

   Created: 2025-07-14 07:25:29 -0400 by heron
   
   Application Controller
*/

#import "AppController.h"

@implementation AppController

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
  [_webView release];
  [_window release];
  [super dealloc];
}

- (void) awakeFromNib
{
}

- (void) applicationDidFinishLaunching: (NSNotification *)aNotif
{
// Uncomment if your application is Renaissance-based
//  [NSBundle loadGSMarkupNamed: @"Main" owner: self];
  NSRect windowFrame;
  NSView *contentView;
  NSString *demoPath;

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

  contentView = [_window contentView];

  while ([[contentView subviews] count] > 0)
    {
      [[[contentView subviews] objectAtIndex: 0] removeFromSuperview];
    }

  [_window makeKeyAndOrderFront: self];
  [NSApp activateIgnoringOtherApps: YES];

  if (_webView == nil)
    {
      _webView = [[WebView alloc] initWithFrame: [contentView bounds]];
      [_webView setAutoresizingMask: (NSViewWidthSizable | NSViewHeightSizable)];
      [contentView addSubview: _webView];
    }

  demoPath = [[NSBundle mainBundle] pathForResource: @"Demo" ofType: @"html"];
  if (demoPath != nil)
    {
      [_webView loadURL: [[NSURL fileURLWithPath: demoPath] absoluteString]];
    }
  else
    {
      [_webView loadURL: @"https://example.com"];
    }
}

- (BOOL) applicationShouldTerminate: (id)sender
{
  return YES;
}

- (void) applicationWillTerminate: (NSNotification *)aNotif
{
}

- (BOOL) application: (NSApplication *)application
	    openFile: (NSString *)fileName
{
  return NO;
}

- (IBAction) showPrefPanel: (id)sender
{
}

@end
