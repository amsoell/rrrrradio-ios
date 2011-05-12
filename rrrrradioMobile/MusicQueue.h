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
}

-(void) lock;
-(void) unlock;
-(NSMutableDictionary*) getNext;
-(NSMutableDictionary*) currentTrack;
-(void) push:(NSDictionary*)trackData;
-(id) initWithTrackData:(NSArray*)trackData;
-(int) length;
-(void) updateQueue:(NSArray*)trackData;

@property (retain) NSMutableArray *q;
@property int ptr;
@property BOOL locked;

@end
