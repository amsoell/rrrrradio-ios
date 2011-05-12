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

- (void) lock {
    locked = YES;
}

- (void) unlock {
    locked = NO;
}

- (NSMutableDictionary*) getNext {
    [self lock];
    
    ptr++;
    for (int i=0; i<ptr; i++) {
        if ([[[q objectAtIndex:i] objectForKey:@"prune"] isEqualToNumber:[NSNumber numberWithBool:YES]]) {
            [q removeObjectAtIndex:i];
            ptr--;
            i--;
        }
    }
    
    [self unlock];
    return [self currentTrack];
}

- (NSMutableDictionary*) currentTrack {
    return [q objectAtIndex:ptr];
}

- (NSMutableDictionary*) firstTrack {
    return [q objectAtIndex:0];
}

- (void) push:(NSMutableDictionary *)trackData {
    [q addObject:trackData];
}

- (id) initWithTrackData:(NSArray *)tracks {
    ptr = -1;
    q = [[NSMutableArray alloc] initWithArray:tracks];
    
    return [super init];
}

- (int) length {
    return [q count];
}

- (void) updateQueue:(NSArray *)trackData {
    if (!locked) {
        int offset = 0;
        
        for (int i = 0; i < [q count]; i++) {
            NSLog(@"Comparing %@ to %@.", [[q objectAtIndex:i] objectForKey:@"key"], [[trackData objectAtIndex:0] objectForKey:@"key"]);
            if ([[[q objectAtIndex:i] objectForKey:@"key"] isEqualToString:[[trackData objectAtIndex:0] objectForKey:@"key"]]) {
                NSLog(@"Equal!");
                offset = i;
                break;
            }
        }
        NSLog(@"Offset: %i", offset);

        for (int i=0; i<offset; i++) {
            [[q objectAtIndex:i] setValue:[NSNumber numberWithBool:YES] forKey:@"prune"]; 
        }

        for (int i=0; i<[trackData count]; i++) {
            if ((i+offset) >= [q count]) {
                [q insertObject:[trackData objectAtIndex:i] atIndex:(i+offset)];  
            } else {
                [q replaceObjectAtIndex:(i+offset) withObject:[trackData objectAtIndex:i]];
            }
            [q objectAtIndex:(i+offset)];
        }
        
        NSLog(@"Pointer: %i", ptr);
        for (NSDictionary *track in q) {
            NSLog(@"Track %@ has prune set to %@", [track objectForKey:@"name"], [track objectForKey:@"prune"]);
        }
    }
}

- (void) dealloc {
    [q release];
    [super dealloc];
}
@end
