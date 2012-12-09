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
#import <iVersion/iVersion.h>
#import "iTunesApplication+DD.h"

@implementation DDAppDelegate

- (void)notifyWithTitle:(id)title description:(id)desc notificationName:(id)noteName {
    if(NSClassFromString(@"NSUserNotification")) {
        NSUserNotification *note = [[NSUserNotification alloc] init];
        note.title = title;
        note.informativeText = desc;
        note.userInfo = @{@"name":noteName};
        [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:note];
    }
    else {
        [GrowlApplicationBridge notifyWithTitle:title description:desc notificationName:noteName iconData:nil priority:0 isSticky:NO clickContext:0 identifier:nil];
    }
}

+ (void)initialize {
    [iVersion sharedInstance].remoteVersionsPlistURL = @"https://raw.github.com/Daij-Djan/BoomBox/master/versions.plist";
    [iVersion sharedInstance].updateURL = [NSURL URLWithString:@"https://github.com/Daij-Djan/BoomBox/downloads"];
    [iVersion sharedInstance].onlyPromptIfMainWindowIsAvailable = NO;
#ifdef DEBUG
    [iVersion sharedInstance].previewMode = YES;
    [iVersion sharedInstance].verboseLogging = YES;
#endif
}

#pragma mark app delegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    self.item = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    self.item.menu = self.menu;
    
    [self runiTunesCheck];
    [[NSDistributedNotificationCenter defaultCenter] addObserver:self
                                                        selector:@selector(anyNotification:)
                                                            name:SONG_CHANGE_NOTIFICATION
                                                          object:nil];    
    [[NSWorkspace sharedWorkspace].notificationCenter addObserver:self
                                                         selector:@selector(anyNotification:)
                                                             name:NSWorkspaceDidActivateApplicationNotification
                                                           object:nil];
    [[NSWorkspace sharedWorkspace].notificationCenter addObserver:self
                                                         selector:@selector(anyNotification:)
                                                             name:NSWorkspaceDidDeactivateApplicationNotification
                                                           object:nil];
}

#pragma mark - trigger

- (void)anyNotification:(NSNotification *)note {
    //find itunes
    NSArray *apps = [[[NSWorkspace sharedWorkspace] runningApplications] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"bundleIdentifier==%@", ITUNES_BUNDLE_IDENTIFIER]];
    NSRunningApplication *app = apps.count ? [apps objectAtIndex:0] : nil;
    
     NSLog(@"%@ / %@(%d,%d)", note.name, app.bundleIdentifier, app.isActive, app.terminated);
    
    //cancel previous checks
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(runiTunesCheck) object:nil];
    [self.timer invalidate];
    
    //check itunes on song change
    if([note.name isEqualToString:SONG_CHANGE_NOTIFICATION]) {
        [self performSelector:@selector(runiTunesCheck) withObject:nil afterDelay:1.0f];
        return;
    }
    
    //check foreground app and set timer if itunes it up
    if(app.isActive && !app.terminated) {
        [self runiTunesCheck];
        //prepare a timer
        self.timer = [NSTimer scheduledTimerWithTimeInterval:2.0f
                                                      target:self
                                                    selector:@selector(iTunesCheckTimerFired:)
                                                    userInfo:nil
                                                     repeats:YES];
    }
    else {
        //cancel
        if(!app || app.terminated)
            [self turnOffMenu];
    }
    
}

- (void)iTunesCheckTimerFired:(NSTimer*)timer {
    [self runiTunesCheck];
}

#pragma mark - actions

- (void)turnOffMenu {
    if(self.item.menu != self.menu)
        return;
    
    NSLog(@"turnOffMenu");
    
    NSMenu *tempMenu = [[NSMenu alloc] init];
    [tempMenu addItemWithTitle:@"Launch iTunes" action:@selector(openITunes:) keyEquivalent:@""];
    [tempMenu addItemWithTitle:@"Quit" action:@selector(quitMe:) keyEquivalent:@""];
    self.item.menu = tempMenu;
    self.item.image = [NSImage imageNamed:@"boombox_close"];
}

- (void)runiTunesCheck {
    //find itunes
    NSArray *apps = [[[NSWorkspace sharedWorkspace] runningApplications] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"bundleIdentifier==%@", ITUNES_BUNDLE_IDENTIFIER]];
    NSRunningApplication *app = apps.count ? [apps objectAtIndex:0] : nil;
    
    //temp menu if itunes isnt up
    if(!app || app.terminated) {
        [self turnOffMenu];
        return;
    }
    self.item.menu = self.menu;
    
    NSLog(@"runiTunesCheck");
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
        [self notifyWithTitle:newTitle
                  description:[NSString stringWithFormat:@"EQ Preset: %@", newItemName]
             notificationName:@"iTunes Song Change"];
    }
    else if(![oldItemName isEqualToString:newItemName]) {
        [self notifyWithTitle:[NSString stringWithFormat:@"EQ Preset: %@", newItemName]
                  description:@"Equalizer preset changed"
             notificationName:@"iTunes Equalizer Change"];
    }
}

- (IBAction)changeActiveEQPreset:(NSMenuItem*)sender {
    iTunesApplication *tunes = self.iTunesApplication;
    
    //change
    NSMenuItem *oldItem = [self.menu itemWithTag:CHOSEN_EQ_TAG];
    oldItem.tag = EQ_TAG;
    oldItem.state = NSOffState;
    NSString *oldItemName = oldItem.title;
    NSString *newItemName = [tunes changeActiveEQPresetTo:sender.representedObject];
    NSMenuItem *newItem = [self.menu itemWithTitle:newItemName];
    newItem.state = NSOnState;
    newItem.tag = CHOSEN_EQ_TAG;
    
    if(![oldItemName isEqualToString:newItemName]) {
        //growl
        [self notifyWithTitle:[NSString stringWithFormat:@"EQ Preset: %@", newItemName]
                  description:@"Equalizer preset changed"
             notificationName:@"iTunes Equalizer Change"];
    }
}

- (IBAction)openITunes:(id)sender {
    [[NSWorkspace sharedWorkspace] launchAppWithBundleIdentifier:ITUNES_BUNDLE_IDENTIFIER
                                                         options:0
                                  additionalEventParamDescriptor:nil
                                                launchIdentifier:nil];
}

- (IBAction)quitMe:(id)sender {
    [[NSApplication sharedApplication] terminate:sender];
}

- (iTunesApplication*)iTunesApplication {
    return (iTunesApplication*)[[SBApplication alloc] initWithBundleIdentifier:@"com.apple.itunes"];
}

@end
