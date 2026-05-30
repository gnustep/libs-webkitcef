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

// Class methods...
+ (void)  initialize;

// Initialization
- (id) init;
- (void) dealloc;

// Notification methods...
- (void) applicationDidFinishLaunching: (NSNotification *)aNotif;
- (BOOL) applicationShouldTerminate: (id)sender;
- (void) applicationWillTerminate: (NSNotification *)aNotif;
// - (void) windowDidResize: (NSNotification *)notification;
//- (BOOL) application: (NSApplication *)application
//	    openFile: (NSString *)fileName;

// Actions...
- (IBAction) showPrefPanel: (id)sender;

@end

#endif
