//
//  iTunesApplication+DD.h
//  BoomBox
//
//  Created by Dominik Pich on 26.11.12.
//  Copyright (c) 2012 info.pich. All rights reserved.
//

#import "iTunes.h"

//tags for the menu
#define TRACK_TAG 123
#define EQ_TAG 321
#define CHOSEN_EQ_TAG 322

//the distributed notification sent
#define SONG_CHANGE_NOTIFICATION @"com.apple.iTunes.playerInfo"

@interface SBApplication (DD)

//trackinfo as a nice string
- (NSString*)updateTrack;

//array of NSMenuItems with the current EQPresets put in with the old menu
- (NSArray*)updateEQPresetsMenu:(NSArray*)menuItems;

//changes the EQ. nil = None
- (NSString*)changeActiveEQPresetTo:(NSString*)name;

@end
