/* 
   Project: WebBrowser

   Author: Gregory John Casamento,,,

   Created: 2025-07-14 07:25:29 -0400 by heron
   
   Application Controller
*/
 
#ifndef _PCAPPPROJ_APPCONTROLLER_H
#define _PCAPPPROJ_APPCONTROLLER_H

#import <AppKit/AppKit.h>
#import <WebKit/WebKit.h>
// Uncomment if your application is Renaissance-based
//#import <Renaissance/Renaissance.h>

@interface AppController : NSObject
{
  IBOutlet NSWindow *_window;
  NSTextField *_urlField;
  WebView *_webView;
}

// Class methods...
+ (void)  initialize;

// Initialization
- (id) init;
- (void) dealloc;
- (void) awakeFromNib;
- (void) setupMainMenu;
- (void) layoutBrowserViews;
- (void) updateURLFieldFromWebView;
- (NSString *) normalizedURLStringFromString: (NSString *)urlString;

// Notification methods...
- (void) applicationDidFinishLaunching: (NSNotification *)aNotif;
- (BOOL) applicationShouldTerminate: (id)sender;
- (void) applicationWillTerminate: (NSNotification *)aNotif;
- (void) windowDidResize: (NSNotification *)notification;
- (BOOL) application: (NSApplication *)application
	    openFile: (NSString *)fileName;

// Actions...
- (IBAction) showPrefPanel: (id)sender;
- (IBAction) urlFieldDidReturn: (id)sender;
- (void) webViewURLDidChange: (NSNotification *)notification;

@end

#endif
