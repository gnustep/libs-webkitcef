/* 
   Project: WebBrowser

   Author: Gregory John Casamento,,,

   Created: 2025-07-14 07:25:29 -0400 by heron
*/

#import <AppKit/AppKit.h>
#import <WebKit/WebKit.h>
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

// Uncomment if your application is Renaissance application
/*  CREATE_AUTORELEASE_POOL (pool);
  [NSApplication sharedApplication];
  [NSApp setDelegate: [AppController new]];

  #ifdef GNUSTEP
    [NSBundle loadGSMarkupNamed: @"MainMenu-GNUstep"  owner: [NSApp delegate]];
  #else
    [NSBundle loadGSMarkupNamed: @"MainMenu-OSX"  owner: [NSApp delegate]];
  #endif
   
  RELEASE (pool);
*/

  return NSApplicationMain (argc, argv);
}
