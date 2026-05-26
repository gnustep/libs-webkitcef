/* 
   Project: WebBrowser

   Author: Gregory John Casamento,,,

   Created: 2025-07-14 07:25:29 -0400 by heron
*/

#import <AppKit/AppKit.h>
#import <WebKit/WebKit.h>
#import "AppController.h"
#include <string.h>

int 
main(int argc, const char *argv[])
{
  int i;
  BOOL isCEFSubprocess = NO;

  for (i = 1; i < argc; i++)
    {
      if (strncmp(argv[i], "--type=", 7) == 0)
        {
          isCEFSubprocess = YES;
          break;
        }
    }

  if (isCEFSubprocess)
    {
      int cefExitCode = WebKitCEFExecuteProcess(argc, argv);
      if (cefExitCode >= 0)
        {
          return cefExitCode;
        }
    }

  {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    AppController *delegate;

    [NSApplication sharedApplication];
    delegate = [[AppController alloc] init];
    [NSApp setDelegate: delegate];
    [pool release];
    [NSApp run];
    [delegate release];
  }

  return 0;
}
