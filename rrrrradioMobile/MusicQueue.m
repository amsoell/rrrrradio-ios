//
//  MusicQueue.m
//  rrrrradioMobile
//
//  Created by Andy Soell on 5/12/11.
//  Copyright 2011 The Institute for Justice. All rights reserved.
//

#import "MusicQueue.h"


@implementation MusicQueue
@synthesize q;
@synthesize ptr;
@synthesize locked;
@synthesize needsRefresh;

- (void) lock:(NSString*)lockedBy {
//    NSLog(@"**%@: LOCKED**", lockedBy);
    locked = YES;
}

- (void) unlock {
//    NSLog(@"**UNLOCKED**");    
    locked = NO;
}

-(void) cancelPlayback {
    while ([self locked]) { }
    [self lock:@"cancelPlayback"];
    ptr --;
    [self unlock];
}

- (NSMutableDictionary*) getNext {
    
    ptr++;
    [self prune:ptr];

    return [self currentTrack];
}

- (void) prune:(int) max {
    while ([self locked]) { }
    [self lock:@"prune"];
    
    for (int i=0; (i<max) && (i<[q count]); i++) {
        if ([[[q objectAtIndex:i] objectForKey:@"prune"] isEqualToNumber:[NSNumber numberWithBool:YES]]) {
            [q removeObjectAtIndex:i];
            if (ptr>=0) ptr--;
            i--;
        }
    }    
    [self unlock]; 
}

- (NSMutableDictionary*) currentTrack {
    if ((ptr>=0) && (ptr<[q count])) {
        return [q objectAtIndex:ptr];
    } else if ([q count]>0) {
        return [q objectAtIndex:0];
    } else {
        return NO;
    }
}

- (NSMutableDictionary*) firstTrack {
    int index = 0;
    if (ptr>0) index += ptr;
    return [self trackAt:index];
}

- (NSMutableDictionary*) trackAt:(int)index {
    if (ptr>0) index+=ptr;
    
    if ((index>=0) && (index<[q count])) {
        return [q objectAtIndex:index];
    } else {
        return NO;
    }
}

- (void) push:(NSMutableDictionary *)trackData {
    while ([self locked]) { }
    if (!locked) {    
        [self lock:@"push"];
        if ([trackData objectForKey:@"bigIcon"]!=nil) {
            [trackData setObject:[UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:[trackData objectForKey:@"bigIcon"]]]] forKey:@"bigIcon"];
        }
        if ([trackData objectForKey:@"icon"]!=nil) {
            [trackData setObject:[UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:[trackData objectForKey:@"icon"]]]] forKey:@"icon"];
        }
        
        [q addObject:trackData];
        [self unlock];
    }
}

- (id) initWithTrackData:(NSArray *)tracks {
    while ([self locked]) { }
    [self lock:@"initWithTrackData"];
    ptr = -1;
    q = [[NSMutableArray alloc] initWithArray:tracks];
    
    [self unlock];

    return [super init];
}

- (int) length {
    if (ptr<0) {
        return [q count];
    } else {
        return [q count] - ptr;
    }
}

- (void) updateQueue:(NSArray *)trackData {
    if (!locked) {
        [self lock:@"updateQueue"];
        int offset = 0;
        
        for (int i = 0; i < [q count]; i++) {
            if ([[[q objectAtIndex:i] objectForKey:@"key"] isEqualToString:[[trackData objectAtIndex:0] objectForKey:@"key"]]) {
                offset = i;
                break;
            }
        }

        for (int i=0; i<offset; i++) {
            [[q objectAtIndex:i] setValue:[NSNumber numberWithBool:YES] forKey:@"prune"]; 
        }

        for (int i=0; i<[trackData count]; i++) {
            if ((i+offset) >= [q count]) {
                [q insertObject:[trackData objectAtIndex:i] atIndex:(i+offset)];                  
            } else {
                [[trackData objectAtIndex:i] setValue:[[q objectAtIndex:(i+offset)] objectForKey:@"NowPlayingCell"] forKey:@"NowPlayingCell"];
                [[trackData objectAtIndex:i] setValue:[[q objectAtIndex:(i+offset)] objectForKey:@"UpcomingCell"] forKey:@"UpcomingCell"];
                
                [q replaceObjectAtIndex:(i+offset) withObject:[trackData objectAtIndex:i]];
            }
            [q objectAtIndex:(i+offset)];
        }
        
        [self unlock];
    }
}

- (void) dealloc {
    [q release];
    [super dealloc];
}
@end
