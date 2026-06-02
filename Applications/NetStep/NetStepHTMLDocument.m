/* Implementation of class NetStepHTMLDocument
   Copyright (C) 2026 Free Software Foundation, Inc.
   
   By: heron
   Date: 29-05-2026

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

#import "NetStepHTMLDocument.h"
#import "NetStepWindowController.h"

@implementation NetStepHTMLDocument

- (void) makeWindowControllers
{
  NetStepWindowController *wc =
    [[NetStepWindowController alloc] initWithWindowNibName:
				       @"NetStepWindowController"];

  NSLog(@"URL = %@, wc = %@", _url, wc);
  [self addWindowController: wc];
  [wc setURL: _url];
}

- (BOOL) readFromURL: (NSURL *)url
	      ofType: (NSString *)typeName
	       error: (NSError **)error
{
  NSLog(@"Read from URL %@", url);
  ASSIGN(_url, url);
  return YES;
}

@end
