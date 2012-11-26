//
//  DDAppDelegate.m
//  BoomBox
//
//  Created by Dominik Pich on 26.11.12.
//  Copyright (c) 2012 info.pich. All rights reserved.
//
#import "DDAppDelegate.h"

#import <ScriptingBridge/ScriptingBridge.h>
#import <Growl/Growl.h>
#import "iTunesApplication+DD.h"

@implementation DDAppDelegate

#pragma mark app delegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    self.item = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    self.item.menu = self.menu;
    
    [self iTunesSongChanged:nil];
    [[NSDistributedNotificationCenter defaultCenter] addObserver:self
                                                        selector:@selector(iTunesSongChanged:)
                                                            name:SONG_CHANGE_NOTIFICATION
                                                          object:nil];
}

#pragma mark - trigger

- (void)iTunesSongChanged:(NSNotification *)note {
    [self iTunesCheckTimerFired:nil];

    [self.timer invalidate];
    self.timer = [NSTimer scheduledTimerWithTimeInterval:2.0f
                                     target:self
                                   selector:@selector(iTunesCheckTimerFired:)
                                   userInfo:nil
                                    repeats:YES];
}

- (void)iTunesCheckTimerFired:(NSTimer*)timer {
    iTunesApplication *tunes = self.iTunesApplication;
    
    //title
    NSString *newTitle = [tunes updateTrack];
    NSMenuItem *trackItem = [self.menu itemWithTag:123];
    NSString *oldTitle = trackItem.title;
    trackItem.title = newTitle;
    
    //EQs
    NSArray *menuItems = [tunes updateEQPresetsMenu:self.menu.itemArray];
    NSString *oldItemName = [self.menu itemWithTag:CHOSEN_EQ_TAG].title;
    [self.menu removeAllItems];
    for(NSMenuItem *newItem in menuItems) {
        [self.menu addItem:newItem];
    }
    NSString *newItemName = [self.menu itemWithTag:CHOSEN_EQ_TAG].title;

    //set our icon
    self.item.image = [NSImage imageNamed:([newItemName isEqualToString:@"None"]) ? @"boombox_close" : @"boombox_check"];
    
    //growl
    if(![oldTitle isEqualToString:newTitle]) {
        [GrowlApplicationBridge notifyWithTitle:newTitle
                                    description:[NSString stringWithFormat:@"EQ Preset: %@", newItemName]
                               notificationName:@"iTunes Song Change"
                                       iconData:nil
                                       priority:0
                                       isSticky:NO
                                   clickContext:nil];

    }
    else if(![oldItemName isEqualToString:newItemName]) {
        [GrowlApplicationBridge notifyWithTitle:[NSString stringWithFormat:@"EQ Preset: %@", newItemName]
                                    description:@"Equalizer preset changed"
                               notificationName:@"iTunes Equalizer Change"
                                       iconData:nil
                                       priority:0
                                       isSticky:NO
                                   clickContext:nil];
    }
}

- (IBAction)changeActiveEQPreset:(NSMenuItem*)sender {
    iTunesApplication *tunes = self.iTunesApplication;

    //change
    NSMenuItem *oldItem = [self.menu itemWithTag:CHOSEN_EQ_TAG];
    oldItem.tag = EQ_TAG;
    NSString *oldItemName = oldItem.title;
    NSString *newItemName = [tunes changeActiveEQPresetTo:sender.representedObject];
    NSMenuItem *newItem = [self.menu itemWithTitle:newItemName];
    newItem.state = NSOnState;
    newItem.tag = CHOSEN_EQ_TAG;
    
    if(![oldItemName isEqualToString:newItemName]) {
        //growl
        [GrowlApplicationBridge notifyWithTitle:[NSString stringWithFormat:@"EQ Preset: %@", newItemName]
                                    description:@"Equalizer preset changed"
                               notificationName:@"iTunes Equalizer Change"
                                       iconData:nil
                                       priority:0
                                       isSticky:NO
                                   clickContext:nil];
    }
}

- (iTunesApplication*)iTunesApplication {
    return [SBApplication applicationWithBundleIdentifier:@"com.apple.itunes"];
}

@end
