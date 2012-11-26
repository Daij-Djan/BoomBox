//
//  DDAppDelegate.h
//  BoomBox
//
//  Created by Dominik Pich on 26.11.12.
//  Copyright (c) 2012 info.pich. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface DDAppDelegate : NSObject <NSApplicationDelegate>

@property (strong) NSTimer *timer;
@property (strong) NSStatusItem *item;
@property (assign) IBOutlet NSMenu *menu;

@end
