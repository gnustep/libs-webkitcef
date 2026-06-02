/* Implementation of class NetStepWindowController
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

#import "NetStepWindowController.h"

@implementation NetStepWindowController

- (id) init
{
  if (self = [super init])
    {
      _url = nil;
    }
  return self;
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

- (void) setURL: (NSURL *)url
{
  ASSIGN(_url, url);
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

- (void) windowDidResize: (NSNotification *)notification
{
}

- (void) awakeFromNib
{
  NSString *urlString = nil;

  if (_url != nil)
    {
      urlString = [_url absoluteString];
    }

  [_urlField setStringValue: urlString];
  [_webView loadURL: urlString];
}

@end

