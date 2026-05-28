/* 
   Project: WebBrowser

   Author: Gregory John Casamento,,,

   Created: 2025-07-14 07:25:29 -0400 by heron
*/

#import <AppKit/AppKit.h>
#import <WebKit/WebKit.h>
#import "AppController.h"

int 
main(int argc, const char *argv[])
{
#ifdef GNUSTEP
  int cefExitCode = WebKitCEFHandleProcess(argc, argv);
  if (cefExitCode >= 0)
    {
      return cefExitCode;
    }
#endif
  return NSApplicationMain(argc, argv);
}
