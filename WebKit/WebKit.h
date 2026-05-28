/*
   Project: WebKit

   Copyright (C) 2025 Free Software Foundation

   Author: Gregory John Casamento,,,

   Created: 2025-06-02 12:58:35 -0400 by heron

   This application is free software; you can redistribute it and/or
   modify it under the terms of the GNU General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This application is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 31 Milk Street #960789 Boston, MA 02196 USA.
*/

#ifndef _WEBKIT_H_
#define _WEBKIT_H_

#import <WebKit/WebView.h>

#ifdef __cplusplus
extern "C" {
#endif

/**
 * Handles CEF subprocess execution when the current process was launched as a
 * Chromium helper process.
 *
 * This function inspects the command-line arguments for CEF process role flags
 * and, when appropriate, dispatches into CEF's process execution path. For a
 * normal application process it returns without starting a subprocess role.
 *
 * The return value follows CEF conventions. A non-negative value indicates the
 * process was handled as a CEF subprocess and should typically be returned from
 * main. A negative value indicates normal application startup should continue.
 */
int WebKitCEFHandleProcess(int argc, const char **argv);

/**
 * Executes the CEF subprocess entry point directly.
 *
 * This function calls into CEF's subprocess dispatcher for renderer, GPU,
 * utility, and other Chromium-managed child roles. It is intended for
 * integration code that already determined the process is a CEF child process.
 *
 * The return value is the subprocess exit code returned by CEF.
 */
int WebKitCEFExecuteProcess(int argc, const char **argv);

#ifdef __cplusplus
}
#endif

#endif // _WEBKIT_H_
