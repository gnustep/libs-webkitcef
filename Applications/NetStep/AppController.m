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
  [[NSNotificationCenter defaultCenter] removeObserver: self];
  [super dealloc];
}

- (IBAction) foward: (id)sender
{
  [_webView goForward];
}

- (IBAction) back: (id)sender
{
  [_webView goBack];
}

- (IBAction) reload: (id)sender
{
  [_webView reload];
}

- (IBAction) stop: (id)sender
{
  [_webView stopLoading];
}

- (void) awakeFromNib
{
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
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  NSString *demoPath = [defaults objectForKey: @"homePage"];

  if (_window == nil)
    {
      [_window setTitle: @"NetStep"];
    }

  [_window makeKeyAndOrderFront: self];
  [NSApp activateIgnoringOtherApps: YES];

  if (demoPath != nil)
    {
      [_webView loadURL: demoPath];
    }
  else
    {
      [_webView loadURL: @"https://google.com"];
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

- (BOOL) application: (NSApplication *)application
	    openFile: (NSString *)fileName
{
  BOOL result = NO;
  NSLog(@"Opening file %@", fileName);
  if ([fileName hasPrefix: @"http"])
    {
      NSLog(@"Opening as a web page");
      [_webView loadURL: fileName];
      [self updateURLFieldFromWebView];
      result = YES;
    }
  else
    {
      NSLog(@"Opening as a file");
      NSString *path = [[NSURL fileURLWithPath: fileName] absoluteString];
      [_webView loadURL: path];
      [self updateURLFieldFromWebView];
      result = YES;
    }
  return result;
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
  [_window setTitle: urlString];
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

- (void) windowDidResize: (NSNotification *)notification
{
}

@end

