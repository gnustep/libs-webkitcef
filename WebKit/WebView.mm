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

#include "cef_app.h"
#include "cef_browser.h"
#include "cef_command_line.h"
#include "cef_client.h"
#include "cef_render_handler.h"
#include "cef_message_router.h"
#include "cef_browser_process_handler.h"
#include "cef_parser.h"

#import "WebView.h"

class GSCefClient : public CefClient
{
 public:
  IMPLEMENT_REFCOUNTING(GSCefClient);

  // void OnAfterCreated(CefRefPtr<CefBrowser> browser) {
  //   browser_ = browser;
  // }
};


class GSCefApp : public CefApp, public CefBrowserProcessHandler
{
 public:
    CefRefPtr<CefBrowserProcessHandler> GetBrowserProcessHandler() override
    {
        return this;
    }    

    IMPLEMENT_REFCOUNTING(GSCefApp);
};

std::string GetExecutablePath()
{
  NSString *path = [[NSBundle mainBundle] executablePath];

  if (path == nil)
    {
      NSString *arg0 = [[NSProcessInfo processInfo] arguments][0];
      path = [[NSURL fileURLWithPath:arg0] URLByResolvingSymlinksInPath].path;
    }

  NSLog(@"path = %@", path);
  return [path UTF8String];
}

void LoadHTML(CefRefPtr<CefFrame> frame, const std::string& html)
{
  if (!frame) return;

  CefString encoded = CefURIEncode(CefString(html), false);
  std::string data_url = "data:text/html;charset=utf-8," + encoded.ToString();

  frame->LoadURL(data_url);
}

CefMainArgs GetMainArgsFromNSProcessInfo()
{
  NSArray<NSString *> *args = [[NSProcessInfo processInfo] arguments];
  int argc = (int)[args count];

  // Allocate argv array
  char** argv = new char*[argc];
  for (int i = 0; i < argc; ++i) {
    const char* utf8 = [args[i] UTF8String];
    argv[i] = strdup(utf8);
  }

  // Return CefMainArgs
  return CefMainArgs(argc, argv);
}

@interface GSWebView : WebView
{
  CefRefPtr<CefBrowser> browser_;
  CefRefPtr<GSCefClient> client_;
}
@end

@implementation WebView

+ (id) allocWithZone: (NSZone *)zone
{
  if (self == [WebView class])
  {
    return [GSWebView allocWithZone: zone];
  }
  return [super allocWithZone: zone];
}

- (void)loadRequest: (NSURLRequest*)request
{
}

- (void)loadHTMLString: (NSString*)string baseURL: (NSURL*)baseURL
{
}

- (void)reload
{
}

- (void)stopLoading
{
}

- (void)goBack
{
}

- (void)goForward
{
}

- (BOOL)canGoBack
{
  return NO;
}

- (BOOL)canGoForward
{
  return NO;
}

- (NSString*) stringByEvaluatingJavaScriptFromString: (NSString*)script
{
  return @"";
}

- (NSURL*)mainFrameURL
{
  return nil;
}

- (NSString*)mainFrameTitle
{
  return @"";
}

@end

@implementation GSWebView

/*
+ (void)runCEFLoop
{
  CefRunMessageLoop();
}
*/

- (void) awakeFromNib
{
  NSRect frameRect = [self frame];
  NSWindow *w = [self window];
  CefWindowInfo window_info;
  
  client_ = new GSCefClient();
  window_info.SetAsChild((CefWindowHandle)w, {(int)frameRect.origin.x, (int)frameRect.origin.y,
	(int)frameRect.size.width, (int)frameRect.size.height});

  CefBrowserSettings browser_settings;
  CefString start_url = "https://www.gnu.org";
  CefBrowserHost::CreateBrowser(window_info, client_, start_url, browser_settings, nullptr, nullptr);  
}

- (void)dealloc
{
  CefShutdown();
  [super dealloc];
}

- (void)resizeSubviewsWithOldSize:(NSSize)oldSize
{
  [super resizeSubviewsWithOldSize:oldSize];

  if (!browser_)
    return;

  CefRefPtr<CefBrowserHost> host = browser_->GetHost();
  if (host)
    host->WasResized();
}

- (void)loadRequest:(NSURLRequest*)request
{
  NSString* url = [[request URL] absoluteString];
  [self loadURL: url];
}

- (void)loadHTMLString:(NSString*)string baseURL:(NSURL*)baseURL
{
  if (!browser_)
    return;

  std::string html = [string UTF8String];
  std::string base;

  if (baseURL)
    {
      base = [[baseURL absoluteString] UTF8String];
    }

  CefRefPtr<CefFrame> frame = browser_->GetMainFrame();
  if (frame)
    {
      LoadHTML(frame, html);
    }
}

- (void)loadURL:(NSString*)url
{
  if (!browser_)
    return;

  std::string urlStr = [url UTF8String];

  CefRefPtr<CefFrame> frame = browser_->GetMainFrame();
  if (frame)
    {
      LoadHTML(frame, urlStr);
    }
}

- (void)reload
{
  if (browser_)
    {
      browser_->Reload();
    }
}

- (void)stopLoading
{
  if (browser_)
    {
      browser_->StopLoad();
    }
}

- (void)goBack
{
  if (browser_)
    {
      browser_->GoBack();
    }
}

- (void)goForward
{
  if (browser_)
    {
      browser_->GoForward();
    }
}

- (BOOL)canGoBack
{
  return browser_ ? browser_->CanGoBack() : NO;
}

- (BOOL)canGoForward
{
  return browser_ ? browser_->CanGoForward() : NO;
}

- (NSString*)stringByEvaluatingJavaScriptFromString:(NSString*)script
{
  if (!browser_)
    return @"";

  std::string jsCode = [script UTF8String];
  CefRefPtr<CefFrame> frame = browser_->GetMainFrame();
  if (frame)
    frame->ExecuteJavaScript(jsCode, frame->GetURL(), 0);

  return @"";  // still async, no result returned  
}

- (NSURL*)mainFrameURL
{
  if (!browser_)
    return nil;

  CefRefPtr<CefFrame> frame = browser_->GetMainFrame();
  if (!frame)
    return nil;

  std::string url = frame->GetURL();
  return [NSURL URLWithString:[NSString stringWithUTF8String:url.c_str()]];
}

- (NSString*)mainFrameTitle
{
  if (!browser_) return @"";
  return @"CEF WebView";
}

@end
