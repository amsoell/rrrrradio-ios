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
#import "NowPlayingCell.h"
#import "UpcomingCell.h"

@interface rrrrradioMobileViewController : UIViewController <RDPlayerDelegate,RdioDelegate,UITableViewDataSource,UITableViewDelegate,UIActionSheetDelegate> {
    IBOutlet UITableView *upcoming;
    IBOutlet UIImageView *progress;
    IBOutlet UIToolbar *volumeToolbar;  
    IBOutlet UIToolbar *opsToolbar;
    IBOutlet UIView *blackout;
    int skip;
    MusicQueue *_QUEUE;
    NSTimer *queueLoader;
    NSArray *artistData;
}

- (void) playTrack:(NSDictionary *)trackData;
- (void) refreshQueueDisplay;
- (void) updateQueue;
- (void) enableRequests;
- (void) enableBackgroundPooling;
- (IBAction) playStream;
- (void)stopStream;
- (IBAction) toggleHUD;
- (IBAction) handleVolumeToolbar:(id)selected;
- (IBAction) handleOpsToolbar:(id)selected;

@property (nonatomic, retain) IBOutlet UITableView *upcoming;
@property (nonatomic, retain) IBOutlet UIImageView *progress;
@property (nonatomic, retain) IBOutlet UIToolbar *volumeToolbar;
@property (nonatomic, retain) IBOutlet UIToolbar *opsToolbar;
@property (nonatomic, retain) IBOutlet UIView *blackout;
@property int skip;
@property (retain) MusicQueue *_QUEUE;
@property (retain) NSTimer *queueLoader;
@property (nonatomic, retain) NSArray *artistData;

@end
