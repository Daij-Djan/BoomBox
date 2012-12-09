//
//  iTunesApplication+DD.m
//  BoomBox
//
//  Created by Dominik Pich on 26.11.12.
//  Copyright (c) 2012 info.pich. All rights reserved.
//

#import "iTunesApplication+DD.h"

@implementation SBApplication (DD)

+ (iTunesApplication*)mainInstance {
    return [SBApplication applicationWithBundleIdentifier:ITUNES_BUNDLE_IDENTIFIER];
}

- (NSString*)updateTrack {
    NSString *artist = ((iTunesApplication*)self).currentTrack.artist;
    NSString *newTitle;
    if(artist)
        newTitle = [NSString stringWithFormat:@"%@ - %@", artist, ((iTunesApplication*)self).currentTrack.name];
    else
        newTitle = ((iTunesApplication*)self).currentTrack.name;
    
    if(!newTitle) newTitle = @"Not playing";
    return newTitle;
}

- (NSArray*)updateEQPresetsMenu:(NSArray*)menuItems {
    SBElementArray *eqs = ((iTunesApplication*)self).EQPresets;
    
    //remove old EQs from menu
    NSMutableArray *newMenu = menuItems.mutableCopy;
    BOOL remove;
    NSMenuItem *item;
    do {
        item = newMenu[1];
        remove = (item.tag == CHOSEN_EQ_TAG || item.tag == EQ_TAG);
        
        if(remove) {
            [newMenu removeObjectAtIndex:1];
        }
    } while(remove);
    
    ///build menu with new EQPresets
    NSString *nameOfCurrentEQ = ((iTunesApplication*)self).currentEQPreset.name;//persistentID;
    BOOL EQEnabled = ((iTunesApplication*)self).EQEnabled;
    if(!EQEnabled) {
        nameOfCurrentEQ = nil;
    }
    
    //add none item
    item = [[NSMenuItem alloc] initWithTitle:@"None"
                                      action:@selector(changeActiveEQPreset:)
                               keyEquivalent:@""];
    
    item.tag = !nameOfCurrentEQ ? CHOSEN_EQ_TAG : EQ_TAG;
    item.state = !nameOfCurrentEQ ? NSOnState : NSOffState;
    [newMenu insertObject:item atIndex:1];
    
    //add all items from itunes
    NSString *name;
    for(iTunesEQPreset *eq in eqs) {
        name = eq.name;
        
        item = [[NSMenuItem alloc] initWithTitle:name
                                          action:@selector(changeActiveEQPreset:)
                                   keyEquivalent:@""];
        
        item.representedObject = name;
        item.tag = [nameOfCurrentEQ isEqualToString:name] ? CHOSEN_EQ_TAG : EQ_TAG;
        item.state = [nameOfCurrentEQ isEqualToString:name] ? NSOnState : NSOffState;
        [newMenu insertObject:item atIndex:1];
    }
    
    return newMenu;
}

- (NSString*)changeActiveEQPresetTo:(NSString*)name {
    if(name) {
        //apply
        ((iTunesApplication*)self).EQEnabled = YES;
        for(iTunesEQPreset *eq in ((iTunesApplication*)self).EQPresets) {
            if([eq.name isEqualToString:name]) {
                ((iTunesApplication*)self).currentEQPreset = eq;
                break;
            }
        }
        return ((iTunesApplication*)self).currentEQPreset.name;
    }
    else {
        ((iTunesApplication*)self).EQEnabled = NO;
        ((iTunesApplication*)self).currentEQPreset = nil;
        return @"None";
    }
}

@end