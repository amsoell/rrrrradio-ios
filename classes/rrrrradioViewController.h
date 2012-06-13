//
//  rrrrradioViewController.h
//  rrrrradio
//
//  Created by Andy Soell on 5/11/11.
//  Copyright 2011 The Institute for Justice. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Rdio/Rdio.h>
#import "MusicQueue.h"
#import "NowPlayingCell.h"
#import "UpcomingCell.h"
#import "Reachability.h"

@class Reachability;

@interface rrrrradioViewController : UIViewController <RDAPIRequestDelegate,RDPlayerDelegate,RdioDelegate,UITableViewDataSource,UITableViewDelegate,UIActionSheetDelegate,UISplitViewControllerDelegate> {
    IBOutlet UITableView *upcoming;
    IBOutlet UIImageView *progress;
    IBOutlet UIToolbar *volumeToolbar;  
    IBOutlet UIToolbar *opsToolbar;
    IBOutlet UIView *blackout;
    IBOutlet UIToolbar *toolbar;
    UILabel *listenersLabel;
    UIImageView *listenersBg;
    UINavigationController *listenerController;
    int skip;
    MusicQueue *_QUEUE;
    NSTimer *queueLoader;
    NSArray *artistData;
    NSArray *listeners;
    Reachability* internetReachable;
    Reachability* hostReachable;    
    BOOL internetActive;
    BOOL hostActive;
    NetworkStatus networkSpeed; 
}

- (void) refreshLockDisplay;
- (void) refreshQueueDisplay;
- (void) updateQueue;
- (void) enableRequests;
- (void) displayListeners;
- (void) dismissListeners;
- (void) enableBackgroundPooling:(int)seconds;
- (IBAction) playStream;
- (void)stopStream;
- (IBAction) toggleHUD;
- (IBAction) handleVolumeToolbar:(id)selected;
- (IBAction) handleOpsToolbar:(id)selected;
- (void) foregrounding;
- (void) backgrounding;

@property (nonatomic, retain) IBOutlet UITableView *upcoming;
@property (nonatomic, retain) IBOutlet UIImageView *progress;
@property (nonatomic, retain) IBOutlet UIToolbar *volumeToolbar;
@property (nonatomic, retain) IBOutlet UIToolbar *opsToolbar;
@property (nonatomic, retain) IBOutlet UIView *blackout;
@property (nonatomic, retain) IBOutlet UIToolbar *toolbar;
@property (nonatomic, retain) UILabel *listenersLabel;
@property (nonatomic, retain) UIImageView *listenersBg;
@property (nonatomic, retain) UINavigationController *listenerController;
@property int skip;
@property (retain) MusicQueue *_QUEUE;
@property (retain) NSTimer *queueLoader;
@property (nonatomic, retain) NSArray *artistData;
@property (nonatomic, retain) NSArray *listeners;
@property (nonatomic) BOOL internetActive;
@property (nonatomic) BOOL hostActive;
@property (nonatomic) NetworkStatus networkSpeed;

@end
