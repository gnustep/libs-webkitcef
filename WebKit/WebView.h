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

#ifndef INCLUDED_WebView_h
#define INCLUDED_WebView_h

#include <Foundation/Foundation.h>
#include <AppKit/AppKit.h>

/**
 * Completion callback used by asynchronous JavaScript evaluation.
 *
 * The callback receives the resulting value as an NSString when evaluation
 * succeeds, and an NSError when evaluation fails. Implementations may provide
 * an empty string when script execution succeeds but no explicit value is
 * returned by the page.
 *
 * The function-pointer form is used to keep compatibility with older
 * Objective-C runtimes that do not rely on block-based callback types.
 */
typedef void (*WebViewJavaScriptCompletionHandler)(NSString* result, NSError* error);

/**
 * Notification posted whenever the main frame URL changes.
 *
 * The notification object is the WebView instance that observed the change.
 * The userInfo dictionary may include a value for WebViewURLKey.
 */
extern NSString *WebViewURLDidChangeNotification;

/**
 * User-info dictionary key containing the current URL string.
 *
 * Used with WebViewURLDidChangeNotification to expose the latest URL observed
 * for the main frame.
 */
extern NSString *WebViewURLKey;

/**
 * AppKit view that embeds a Chromium-backed browser surface.
 *
 * WebView provides a GNUstep-compatible API for loading web content,
 * navigating session history, and executing JavaScript in the active page.
 * The implementation lazily initializes browser resources as needed.
 */
@interface WebView : NSView

/**
 * Loads content from the URL contained in the request.
 *
 * This is the primary entry point when request metadata is already available.
 * The implementation extracts the request URL and navigates the main frame.
 */
- (void)loadRequest:(NSURLRequest*)request;

/**
 * Loads an HTML document string into the main frame.
 *
 * The HTML string is converted into a browser-loadable data URL and rendered
 * in the current view. The base URL may be used by the page for resolving
 * relative resource references.
 */
- (void)loadHTMLString:(NSString*)string baseURL:(NSURL*)baseURL;

/**
 * Navigates the main frame to the provided URL string.
 *
 * The URL is treated as a full navigation target and updates the current page,
 * history state, and URL change notifications.
 */
- (void)loadURL:(NSString*)url;

/**
 * Reloads the current page in the main frame.
 *
 * Equivalent to a browser refresh action for the active document.
 */
- (void)reload;

/**
 * Stops the current in-progress navigation or resource load.
 *
 * If no load is active, calling this method has no effect.
 */
- (void)stopLoading;

/**
 * Navigates one step backward in session history.
 *
 * If no previous entry exists, the call has no visible effect.
 */
- (void)goBack;

/**
 * Navigates one step forward in session history.
 *
 * If no forward entry exists, the call has no visible effect.
 */
- (void)goForward;

/**
 * Indicates whether backward navigation is currently possible.
 *
 * Returns YES when a previous history entry is available.
 */
- (BOOL)canGoBack;

/**
 * Indicates whether forward navigation is currently possible.
 *
 * Returns YES when a forward history entry is available.
 */
- (BOOL)canGoForward;

/**
 * Executes JavaScript in the main frame and returns a string result when
 * available.
 *
 * This convenience method is intended for simple fire-and-forget script
 * execution and may return an empty string when no immediate result mapping is
 * available.
 */
- (NSString*)stringByEvaluatingJavaScriptFromString:(NSString*)script;

/**
 * Executes JavaScript asynchronously and reports completion through a callback.
 *
 * The completion handler is invoked when execution completes or fails. This
 * method is appropriate when callers need explicit success/error reporting.
 */
- (void)evaluateJavaScript:(NSString*)script 
           completionHandler:(WebViewJavaScriptCompletionHandler)completionHandler;

/**
 * Returns the current main frame URL.
 *
 * The returned NSURL reflects the browser's active main-frame location when
 * available, or the most recently tracked URL when no live frame is present.
 */
- (NSURL*)mainFrameURL;

/**
 * Returns the current page title for the main frame.
 *
 * If no title has been reported yet, implementations may return a default
 * framework-provided title string.
 */
- (NSString*)mainFrameTitle;

/**
 * Internal lifecycle callback indicating browser creation is complete.
 *
 * Called by the CEF integration layer after the native browser instance has
 * been created and attached.
 */
- (void)browserCreated:(void*)browser;

/**
 * Internal callback indicating main-frame loading has started.
 *
 * Implementations typically update loading state and UI indicators.
 */
- (void)loadingStarted;

/**
 * Internal callback indicating main-frame loading has finished successfully.
 *
 * Implementations typically clear loading state and refresh URL-dependent UI.
 */
- (void)loadingEnded;

/**
 * Internal callback indicating main-frame loading failed.
 *
 * The provided error text describes the browser-reported load failure.
 */
- (void)loadingFailed:(NSString*)error;

/**
 * Internal callback indicating the observed main-frame URL changed.
 *
 * Implementations use this to maintain URL state and post URL change
 * notifications to observers.
 */
- (void)urlChanged:(NSString*)url;

@end

#endif
