//
//  MusicQueue.h
//  rrrrradioMobile
//
//  Created by Andy Soell on 5/12/11.
//  Copyright 2011 The Institute for Justice. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MusicQueue : NSObject {
    NSMutableArray *q;
    int ptr;
    BOOL locked;
    BOOL needsRefresh;
}

-(void) lock:(NSString*)lockedBy;
-(void) unlock;
-(NSMutableDictionary*) getNext;
-(void) cancelPlayback;
-(NSMutableDictionary*) currentTrack;
-(NSMutableDictionary*) trackAt:(int)index;
-(NSMutableDictionary*) firstTrack;
-(void) push:(NSDictionary*)trackData;
-(id) initWithTrackData:(NSArray*)trackData;
-(int) length;
-(void) updateQueue:(NSArray*)trackData;
-(void) prune:(int) allTracks;

@property (retain) NSMutableArray *q;
@property int ptr;
@property BOOL locked;
@property BOOL needsRefresh;


@end
