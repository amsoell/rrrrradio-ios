//
//  rrrrradioMobileViewController.h
//  rrrrradioMobile
//
//  Created by Andy Soell on 5/11/11.
//  Copyright 2011 The Institute for Justice. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Rdio/Rdio.h>
#import "MusicQueue.h"

@interface rrrrradioMobileViewController : UIViewController <RDPlayerDelegate,RdioDelegate,UITableViewDataSource,UITableViewDelegate> {
    IBOutlet UIImageView *coverart; 
    IBOutlet UILabel *song_name;
    IBOutlet UILabel *song_artist;
    IBOutlet UIImageView *trackmask;
    IBOutlet UIImageView *artmask;    
    IBOutlet UIButton *playbutton;
    IBOutlet UITableView *upcoming;
    int skip;
    MusicQueue *_QUEUE;
    NSTimer *queueLoader;
}

- (void) playTrack:(NSDictionary *)trackData;
- (void) refreshQueueDisplay;
- (void) updateQueue;
- (IBAction)playStream;

@property (nonatomic, retain) IBOutlet UIImageView *coverart;
@property (nonatomic, retain) IBOutlet UILabel *song_name;
@property (nonatomic, retain) IBOutlet UILabel *song_artist;
@property (nonatomic, retain) IBOutlet UIImageView *trackmask;
@property (nonatomic, retain) IBOutlet UIImageView *artmask;
@property (nonatomic, retain) IBOutlet UIButton *playbutton;
@property (nonatomic, retain) IBOutlet UITableView *upcoming;
@property int skip;
@property (retain) MusicQueue *_QUEUE;
@property (retain) NSTimer *queueLoader;

@end
