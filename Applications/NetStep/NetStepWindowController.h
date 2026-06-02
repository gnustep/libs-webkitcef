/* Definition of class NetStepWindowController
   Copyright (C) 2026 Free Software Foundation, Inc.
   
   By: heron
   Date: 30-05-2026

   This file is part of GNUstep.
   
   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2.1 of the License, or (at your option) any later version.
   
   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Lesser General Public License for more details.
   
   You should have received a copy of the GNU Lesser General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
   Boston, MA 02110 USA.
*/

#ifndef _NetStepWindowController_h_INCLUDE
#define _NetStepWindowController_h_INCLUDE

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <WebKit/WebKit.h>

#import <GNUstepBase/GSVersionMacros.h>

#if	defined(__cplusplus)
extern "C" {
#endif

GS_EXPORT_CLASS
@interface NetStepWindowController : NSWindowController
{
  IBOutlet NSTextField *_urlField;
  IBOutlet WebView     *_webView;

  IBOutlet NSButton    *_backButton;
  IBOutlet NSButton    *_forwardButton;
  IBOutlet NSButton    *_stopButton;
  IBOutlet NSButton    *_reloadButton;

  NSURL *_url;
}

- (void) awakeFromNib;
- (void) updateURLFieldFromWebView;
- (NSString *) normalizedURLStringFromString: (NSString *)urlString;
- (void) setURL: (NSURL *)url;
  
- (IBAction) forward: (id)sender;
- (IBAction) back: (id)sender;
- (IBAction) reload: (id)sender;
- (IBAction) stop: (id)sender;
- (IBAction) urlFieldDidReturn: (id)sender;

- (void) webViewURLDidChange: (NSNotification *)notification;

@end

#if	defined(__cplusplus)
}
#endif

#endif	/* _NetStepWindowController_h_INCLUDE */
