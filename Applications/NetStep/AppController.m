/* 
   Project: WebBrowser

   Author: Gregory John Casamento,,,

   Created: 2025-07-14 07:25:29 -0400 by heron
   
   Application Controller
*/

#import "AppController.h"
#import "NetStepHTMLDocument.h"

@implementation AppController

+ (void) initialize
{
  NSMutableDictionary *defaults = [NSMutableDictionary dictionary];

  /*
   * Register your app's defaults here by adding objects to the
   * dictionary, eg
   */
  [defaults setObject:@"https://www.google.com" forKey: @"homePage"];
  
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

- (IBAction) showPrefPanel: (id)sender
{
}

- (void) dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver: self];
  [super dealloc];
}

- (void) applicationDidFinishLaunching: (NSNotification *)aNotif
{
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  NSString *demoPath = [defaults objectForKey: @"homePage"];
  NSURL *url = [NSURL URLWithString: demoPath];

  NSLog(@"url = %@", url);
  if (url != nil)
    {
      NSDocumentController *controller = [NSDocumentController sharedDocumentController];
      NetStepHTMLDocument *doc = [[NetStepHTMLDocument alloc] init];

      [controller addDocument: doc];

      [doc setURL: url];
      [doc makeWindowControllers];
      [doc showWindows];
    }
}

- (BOOL) applicationShouldTerminate: (id)sender
{
  return YES;
}

- (void) applicationWillTerminate: (NSNotification *)aNotif
{
}

/*
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
*/

@end

