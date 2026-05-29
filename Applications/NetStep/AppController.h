/* 
   Project: WebStep

   Author: Gregory John Casamento

   Created: 2026-05-28 04:32:27 -0400 by heron
   
   Application Controller
*/
 
#ifndef _PCAPPPROJ_APPCONTROLLER_H
#define _PCAPPPROJ_APPCONTROLLER_H

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

#import <WebKit/WebKit.h>

@interface AppController : NSObject
{
  IBOutlet NSWindow *_window;
  IBOutlet NSTextField *_urlField;
  IBOutlet WebView *_webView;
  IBOutlet NSButton *_backButton;
  IBOutlet NSButton *_fwdButton;
}

// Class methods...
+ (void)  initialize;

// Initialization
- (id) init;
- (void) dealloc;
- (void) awakeFromNib;
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

- (IBAction) foward: (id)sender;
- (IBAction) back: (id)sender;

@end

#endif
