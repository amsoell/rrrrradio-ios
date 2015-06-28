//
//  rrrrradioViewController.m
//  rrrrradio
//
//  Created by Andy Soell on 5/11/11.
//  Copyright 2011 The Institute for Justice. All rights reserved.
//

#import "rrrrradioViewController.h"
#import <Rdio/Rdio.h>
#import <YAJLiOS/YAJL.h>
#import <MediaPlayer/MPVolumeView.h>
#import <MediaPlayer/MPNowPlayingInfoCenter.h>
#import <MediaPlayer/MPMediaItem.h>
#import <AVFoundation/AVFoundation.h>
#import <QuartzCore/QuartzCore.h>
#import "rrrrradioAppDelegate.h"
#import "CollectionBrowser.h"
#import "ListenerController.h"
#import "MusicQueue.h"
#import "DataInterface.h"
#import "Reachability.h"
#import "Settings.h"
#import "ATMHud.h"
#import "Common.h"


@interface rrrrradioViewController ()
    @property (nonatomic, retain) UIPopoverController *popoverController;
@end

@implementation rrrrradioViewController
@synthesize skip;
@synthesize _QUEUE;
@synthesize queueLoader;
@synthesize upcoming;
@synthesize progress;
@synthesize volumeToolbar;
@synthesize opsToolbar;
@synthesize blackout;
@synthesize artistData;
@synthesize listeners;
@synthesize toolbar;
@synthesize listenersLabel;
@synthesize listenersBg;
@synthesize listenerController;
@synthesize internetActive, hostActive, networkSpeed;
@synthesize popoverController=_myPopoverController;
@synthesize hud;


#pragma mark -
#pragma mark Audio interaction methods


// Tell the RDPlayer object to start playing a bunch of tracks
- (void) playTracks:(NSMutableArray *)trackData {
    RDPlayer *player = [[rrrrradioAppDelegate rdioInstance] player];
    [player.queue add:trackData];
    [player playFromQueue:0];
}

// Start the audio
- (void)playStream {
    if (hostActive) {
        if ([[rrrrradioAppDelegate rdioInstance] user] == nil) {
            [self resignFirstResponder];
            [[rrrrradioAppDelegate rdioInstance] authorizeFromController:self];
        } else {
            if (![self isFirstResponder]) [self becomeFirstResponder];        
            
            RDPlayer *player = [[rrrrradioAppDelegate rdioInstance] player];
            [player setDelegate:self];        
            [player addObserver:self forKeyPath:@"position" options:NSKeyValueObservingOptionNew context:nil];    
            [player addObserver:self forKeyPath:@"currentTrack" options:NSKeyValueObservingOptionNew context:nil];
            
            [player addObserver:self forKeyPath:@"position" options:NSKeyValueObservingOptionNew context:nil];        
            [player addObserver:self forKeyPath:@"currentTrack" options:NSKeyValueObservingOptionNew context:nil];
            
            [_QUEUE getNext]; // increment the pointer
            [player.queue add:[_QUEUE getTrackKeys]];
            [player playFromQueue:0];
            [self refreshLockDisplay];            
            
            UIBarButtonItem *btnOld = [[volumeToolbar items] objectAtIndex:0];
            UIBarButtonItem *btnNew = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop target:self action:btnOld.action];
            [btnNew setTag:2];
            NSMutableArray *volumeToolbarItems = [NSMutableArray arrayWithArray:volumeToolbar.items];
            [volumeToolbarItems replaceObjectAtIndex:0 withObject:btnNew];
            [volumeToolbar setItems:volumeToolbarItems];
            
            [btnNew release];
        }
    } else {
        if (!self.internetActive) {
            [hud setBlockTouches:NO];
            [hud setCaption:@"rrrrradio requires an internet connection."];
            [hud setImage:[UIImage imageNamed:@"11-x"]];
            [hud show];            
        } else {
            [hud setBlockTouches:NO];
            [hud setCaption:@"rrrrradio cannot be contacted. Probably some more unscheduled maintenance."];
            [hud setImage:[UIImage imageNamed:@"11-x"]];
            [hud show];
        }
        
    }
}

// Stop the audio playback and reset the system back to infant state
- (void)stopStream {   
    RDPlayer *player = [[rrrrradioAppDelegate rdioInstance] player];
    
    skip = [player position];
    CGRect frame = [progress frame];
    frame.origin.x = 0.0;
    frame.origin.y = 0.0;
    frame.size.width = 0.0;
    
    [progress setFrame:frame];
    if (player.state!=RDPlayerStateStopped) [_QUEUE cancelPlayback];
    [player stop];

    // Change stop button to play button
    UIBarButtonItem *btnOld = [[volumeToolbar items] objectAtIndex:0];    
    UIBarButtonItem *btnNew = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPlay target:self action:btnOld.action];
    [btnNew setTag:1];
    NSMutableArray *volumeToolbarItems = [NSMutableArray arrayWithArray:volumeToolbar.items];
    [volumeToolbarItems replaceObjectAtIndex:0 withObject:btnNew];
    [volumeToolbar setItems:volumeToolbarItems];    
    
    [btnNew release];
}

// Start the system over. Should be called on first load and after coming back from the background if
// a track isn't already playing.
- (void) reset {
    NSLog(@"resetting");
    [UIView beginAnimations:@"blackout" context:nil];
    [blackout setAlpha:0.60];
    [UIView commitAnimations];
    if (_QUEUE!=nil) {
        [_QUEUE release];
        _QUEUE = nil;
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        NSDictionary *arrayData = [[DataInterface issueCommand:@"controller.php?r=getQueue"] yajl_JSON];
        NSArray *queue = [arrayData objectForKey:@"queue"];  
        [self setListeners:[arrayData objectForKey:@"listeners"]];
        _QUEUE = [[MusicQueue alloc ] initWithTrackData:queue];
        
        skip = [[arrayData objectForKey:@"timestamp"] intValue] - [[[queue objectAtIndex:0] objectForKey:@"startplay"] intValue];
        NSLog(@"--skip: %d", skip);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self refreshQueueDisplay];
            [UIView beginAnimations:@"blackout" context:nil];            
            [blackout setAlpha:0.0];   
            [UIView commitAnimations];
        });
    });
}


#pragma mark -
#pragma mark Issue UI instructions

// Toggle the display of Heads-Up-Display objects (toolbars)
- (void)toggleHUD {
    NSLog(@"Toggling the HUD");
    
    [UIView beginAnimations:@"volumeToolbar" context:nil];
    if (volumeToolbar.alpha==0.0) {
        [volumeToolbar setFrame:CGRectOffset([volumeToolbar frame], 0, +volumeToolbar.frame.size.height)];
        [volumeToolbar setAlpha:1.0];     
    } else {
        [volumeToolbar setFrame:CGRectOffset([volumeToolbar frame], 0, -volumeToolbar.frame.size.height)];
        [volumeToolbar setAlpha:0.0];
   
    }
    [UIView commitAnimations];
}

- (void)refreshLockDisplay {
    MPNowPlayingInfoCenter *infoCenter = [MPNowPlayingInfoCenter defaultCenter];
        
    UIImage *image = [Common getAsset:[NSString stringWithFormat:@"%@-bigIcon.png", [[_QUEUE currentTrack] objectForKey:@"albumKey"]] fromUrl:[NSURL URLWithString:[[_QUEUE currentTrack] objectForKey:@"bigIcon"]]];
    NSMutableDictionary* nowPlayingInfo = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                                           [[_QUEUE currentTrack] objectForKey:@"name"], MPMediaItemPropertyTitle,
                                           [[_QUEUE currentTrack] objectForKey:@"artist"], MPMediaItemPropertyArtist,
                                           [[_QUEUE currentTrack] objectForKey:@"album"], MPMediaItemPropertyAlbumTitle,
                                           @"Suck it, Jay", MPMediaItemPropertyComments,
                                           nil];
    MPMediaItemArtwork* coverart = [[MPMediaItemArtwork alloc] initWithImage:image]; 
    if (coverart != nil) {
        [nowPlayingInfo setObject:coverart forKey:MPMediaItemPropertyArtwork];
    }
    [coverart autorelease];
    
    infoCenter.nowPlayingInfo = nowPlayingInfo;
    [nowPlayingInfo autorelease];

  NSLog(@"Lock Info Set");
//    });
}

// Tell the UITableView to refresh itself. Probably a better way to do this
- (void)refreshQueueDisplay {
    [upcoming reloadData];
    [self.listenersLabel setText:[NSString stringWithFormat:@"%lu Listener%@", (unsigned long)[self.listeners count], [self.listeners count]!=1?@"s":@""]];
}

- (void) enableRequests {
     UIBarButtonItem *btnOld = [[opsToolbar items] objectAtIndex:0];
     UIBarButtonItem *btnNew = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:btnOld.action];
     [btnNew setTag:1];
     NSMutableArray *opsToolbarItems = [NSMutableArray arrayWithArray:opsToolbar.items];
     [opsToolbarItems replaceObjectAtIndex:0 withObject:btnNew];
     [opsToolbar setItems:opsToolbarItems];
    
     [btnNew release];    
}

- (void) displayListeners {
    NSLog(@"Show current listeners");
    
    UITableViewController *listenerView = [[UITableViewController alloc] initWithStyle:UITableViewStylePlain];
    [listenerView.tableView setTag:2];
    [listenerView.tableView setDelegate:self];
    [listenerView.tableView setDataSource:self];
    [listenerView setTitle:@"Now Listening"];

    UIBarButtonItem *done = [[UIBarButtonItem alloc] 
                             initWithTitle:@"Done" 
                             style:UIBarButtonItemStyleDone 
                             target:self action:@selector(dismissListeners)];
    [listenerView.navigationItem setRightBarButtonItem:done];
    [done release];    
    
    listenerController = [[ListenerController alloc] initWithRootViewController:listenerView];
    [listenerController.navigationBar setTintColor:[UIColor colorWithRed:185.0f/255.0f green:80.0f/255.0f blue:0.0f/255.0f alpha:1.0f]];
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {                    
        [listenerController setModalPresentationStyle:UIModalPresentationFormSheet];
        [listenerController setModalTransitionStyle:UIModalTransitionStyleCoverVertical];
        [listenerController setModalInPopover:YES];
    }
    
    [self presentViewController:listenerController animated:YES completion:nil];

    [listenerController release];
    [listenerView release];
}

- (void) dismissListeners {
    [listenerController dismissViewControllerAnimated:NO completion:nil];
    listenerController = nil;
}

#pragma mark Queue UITableView construction

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (tableView.tag==2) {
        return 1;
    } else {
        // Queue
        if (_QUEUE.length>1) {
            return 2;
        } else if (_QUEUE.length>0) {
            return 1;
        } else {
            return 0;
        }
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (tableView.tag==2) {
        // Listeners
        return ([listeners count]);
    } else {
        // Queue
        if (section==0) {
            return 1;
        } else {
            return ([_QUEUE length] - 1);
        }
    }

}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell;    
    
    if (tableView.tag==2) {
        // Listeners
        NSDictionary *listener = [listeners objectAtIndex:indexPath.row];
        
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"ListenerCell"];
        [cell.textLabel setText:[NSString stringWithFormat:@"%@ %@", [listener objectForKey:@"firstName"], [listener objectForKey:@"lastName"]]];

        UIImage *image = [Common getAsset:[NSString stringWithFormat:@"%@.png", [listener objectForKey:@"key"]] fromUrl:[NSURL URLWithString:[listener objectForKey:@"icon"]]];
                
        [cell.imageView setImage:image];
        [cell autorelease];
    } else {
        NSUInteger idx;
        idx = indexPath.row + indexPath.section;
        NSDictionary *track = [_QUEUE trackAt:(int)idx];
        NSString *cellType;

        
        if ((indexPath.row+indexPath.section) == 0) {
            cellType = @"NowPlayingCell";
            cell = (NowPlayingCell*)[track objectForKey:cellType];
        } else {
            cellType = @"UpcomingCell";
            cell = (UpcomingCell*)[track objectForKey:cellType];        
        }
        
        if (cell == nil) {
            // Create the cell
            NSArray *nibObjects = [[NSBundle mainBundle] loadNibNamed:@"NowPlayingCell" owner:self options:nil];
            for (id obj in nibObjects) {
                if ([obj isKindOfClass:[NowPlayingCell class]]) {
                    cell = (NowPlayingCell*)obj;
                    [cell performSelector:@selector(setTrackData:) withObject:track]; 
                    [track setValue:cell forKey:@"NowPlayingCell"];              
                    
                    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {      
                        // Shift the labels
                        CGRect frame = cell.textLabel.frame;
                        frame.origin.x += 20;
                        frame.size.width -= 40;
                        [cell.textLabel setFrame:frame];

                        frame = cell.detailTextLabel.frame;
                        frame.origin.x += 20;
                        frame.size.width -= 40;
                        [cell.detailTextLabel setFrame:frame];                        
                        
                        // Round the corners
                        CALayer *l = [cell layer];
                        [l setMasksToBounds:YES];
                        [l setCornerRadius:20.0];
                        // Add border
                        [l setBorderWidth:4.0];
                        [l setBorderColor:[[UIColor blackColor] CGColor]];        
                    }                    
                }
            }
            
            nibObjects = [[NSBundle mainBundle] loadNibNamed:@"UpcomingCell" owner:self options:nil];            
            for (id obj in nibObjects) {
                if ([obj isKindOfClass:[UpcomingCell class]]) {
                    cell = (UpcomingCell*)obj;
                    
                    cell.textLabel.textColor = [UIColor whiteColor];
                    cell.textLabel.backgroundColor = [UIColor clearColor];
                    cell.detailTextLabel.textColor = [UIColor lightGrayColor];
                    cell.detailTextLabel.backgroundColor = [UIColor clearColor];
                    
                    UIImageView *cellBg = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"UITableViewCell-bg.jpg"]];
                    cell.backgroundView = cellBg;   
                    
                    [cell performSelector:@selector(setTrackData:) withObject:track]; 
                    [track setValue:cell forKey:@"UpcomingCell"];                  
                    
                    [cellBg release];        
                    
                    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {                          
                        CALayer *l = [cell layer];
                        [l setMasksToBounds:YES];
                        [l setCornerRadius:8.0];                        
                        // Add border
                        
                    }
                }
            }
            
            cell = [track objectForKey:cellType];
        }
    }

    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ((tableView.tag != 2) && (indexPath.row+indexPath.section==0)) {
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {                
            return 320.0;
        } else {
            return self.upcoming.frame.size.width;
        }
    } else {
        return 44.0;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {      
        if (tableView.tag!=2) {
            if (section==1) {
                return 10.0;
            } else {
                return 0.0;
            }
        } else {
            return 0.0;
        }
    } else {
        return 0.0;
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *header = [[UIView alloc] init];
    
    if (tableView.tag!=2) {
        if (section==1) {
            [header setFrame:CGRectMake(0, 0, tableView.frame.size.width, 10.0)];
        }
    }
    [header autorelease];
    return header;
}


#pragma mark -
#pragma mark Receive UI interactions


// Receive button presses from the volume toolbar
- (void) handleVolumeToolbar:(id) selected {
    UIBarButtonItem *item = (UIBarButtonItem *)selected;
    
    if (item.tag == 1) {
        [self playStream];
    } else if (item.tag == 2) {
        [self stopStream];        
    } else if (item.tag == 3) {
        
    }
}

// Receive button presses from the operations toolbar
- (void) handleOpsToolbar:(id) selected {
    UIBarButtonItem *item = (UIBarButtonItem *)selected;
    
    if (hostActive) {
        if (item.tag == 1) {
            UINavigationController *navigationController = [[UINavigationController alloc] init];
            
            CollectionBrowser *collection = [[CollectionBrowser alloc] initWithNibName:@"CollectionBrowser" bundle:nil];
            [collection setDataSource:artistData];
            [collection setTitle:@"Artists"];
            [collection setOwner:self];
            
            UIBarButtonItem *done = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:collection action:@selector(close)];
            [collection.navigationItem setRightBarButtonItem:done];
            [done release];
            
            [navigationController pushViewController:collection animated:NO];
            [self presentViewController:navigationController animated:YES completion:nil];

            [collection release];        
            [navigationController release];
        } else if (item.tag == 2) {
            UIActionSheet *ops = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Love it", @"Hate it", nil];
            [ops showInView:self.view];
            
            [ops autorelease];
        }
    } else {
        if (!self.internetActive) {
            [hud setBlockTouches:NO];
            [hud setCaption:@"rrrrradio requires an internet connection."];
            [hud setImage:[UIImage imageNamed:@"11-x"]];
            [hud show];
            
        } else {
            [hud setBlockTouches:NO];
            [hud setCaption:@"rrrrradio cannot be contacted. Probably some more unscheduled maintenance."];
            [hud setImage:[UIImage imageNamed:@"11-x"]];
            [hud show];
            
        }        
    }
}

// Receive button presses from the action menu
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    RDPlayer *player = [[rrrrradioAppDelegate rdioInstance] player];
    
        if (buttonIndex==0) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{                
                    [DataInterface issueCommand:[NSString stringWithFormat:@"/controller.php?r=mark&key=%@&val=1",[player currentTrack]]];
            });
            [hud setBlockTouches:NO];
            [hud setCaption:@"Song loved!"];
            [hud setImage:[UIImage imageNamed:@"heart"]];
            [hud show];
            [hud hideAfter:1.5];
            
        } else if (buttonIndex==1) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{                
                [DataInterface issueCommand:[NSString stringWithFormat:@"/controller.php?r=mark&key=%@&val=-1",[player currentTrack]]];
            });
            [hud setBlockTouches:NO];
            [hud setCaption:@"Song hated!"];
            [hud setImage:[UIImage imageNamed:@"hate"]];
            [hud show];
            [hud hideAfter:1.5];
            
        }
}

// Register for updates to the RDPlayer.position value and move the progress bar accordingly
- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if([keyPath isEqualToString:@"position"]) {
        RDPlayer *player = [[rrrrradioAppDelegate rdioInstance] player];        
        if(player.position > 0) {        
            CGRect frame = [progress frame];     
            
            frame.origin.x = 0.0;
            frame.origin.y = 0.0;
            frame.size.width = ([player position]/[[[_QUEUE currentTrack] objectForKey:@"duration"] doubleValue]) * self.toolbar.frame.size.width;
            
            [progress setFrame:frame];
        }
        
    }    
}

// Get the queue from the web and update the internal queue
// Low priority, background thread, so don't call when you *need* an update
//
// *ALL* this method does is get the updated queue and add new tracks to the internal
// queue. Pointer handling should be handled elsewhere.
- (void)updateQueue {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        NSDictionary *arrayData = [[DataInterface issueCommand:@"controller.php?r=getQueue"] yajl_JSON];
        NSArray *queue = [arrayData objectForKey:@"queue"];   
        [self setListeners:[arrayData objectForKey:@"listeners"]];
        
        int size = [_QUEUE length];
        [_QUEUE updateQueue:queue];
        
        // update the skip value if we aren't playing
        RDPlayer* player = [[rrrrradioAppDelegate rdioInstance] player];        
        if ([player state] != RDPlayerStatePlaying) {
            skip = [[arrayData objectForKey:@"timestamp"] intValue] - [[[queue objectAtIndex:0] objectForKey:@"startplay"] intValue];
            [_QUEUE prune:[_QUEUE length]];
        }
        
        // If the queue size changed, update the display
        if ([_QUEUE length]!=size) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self refreshQueueDisplay];
            });
        }
        
        if ([player state] == RDPlayerStatePlaying) { 
            NSArray* queue = [_QUEUE getTrackKeys];
            int ctrkindex = (int)[queue indexOfObject:[player currentTrack]];
            
            NSLog(@"running RDPlayer:updateQueue:%@ withCurrentTrackAtIndex:%i", queue, ctrkindex);
            if (([queue count]>ctrkindex) && (ctrkindex>=0)) {
                [player.queue add:[_QUEUE getTrackKeys]];
            } else {
                NSLog(@"COULD NOT FIND INDEX");
            }
        }
    });
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView.tag==2) {
        // Listeners
        [tableView deselectRowAtIndexPath:indexPath animated:YES];               
    } else {
        if (indexPath.row==0) {
            [self toggleHUD];
        }
    }
}

#pragma mark -
#pragma mark Split View Delegate code

- (void)splitViewController:(UISplitViewController*)svc popoverController:(UIPopoverController*)pc willPresentViewController:(UIViewController *)aViewController
{
    NSLog(@"pop!");
}

- (void)splitViewController: (UISplitViewController*)svc willHideViewController:(UIViewController *)aViewController withBarButtonItem:(UIBarButtonItem*)barButtonItem forPopoverController: (UIPopoverController*)pc 
{
    // configure barButton
/*    
    UIButton* button = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImage* image = [UIImage imageNamed:@"UIBarButtonAdd.png"];
    [button setImage:image forState:UIControlStateNormal];    
    [button setFrame:CGRectMake(0, 0, image.size.width+10, image.size.width+10)];
    [button addTarget:self action: @selector(pop:) forControlEvents:UIControlEventTouchUpInside];
    
    CALayer *buttonLayer = [button layer];
    [buttonLayer setMasksToBounds:YES];
    [buttonLayer setCornerRadius:10.0];
    [buttonLayer setBorderWidth:1.0];
    [buttonLayer setBorderColor:[[UIColor grayColor] CGColor]];
    
    barButtonItem = [[UIBarButtonItem alloc] initWithCustomView:button];
*/    
    [barButtonItem setTitle:@"Request"];
    
    NSMutableArray * items = [[toolbar items] mutableCopy];
    [items insertObject: barButtonItem atIndex: 0];
    [toolbar setItems: items animated: YES];
    [items release];
    self.popoverController = pc;
}

- (void)splitViewController: (UISplitViewController*)svc willShowViewController:(UIViewController *)aViewController invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem {
    
    NSMutableArray *items = [[toolbar items] mutableCopy];
    [items removeObjectAtIndex:0];
    [toolbar setItems:items animated:YES];
    [items release];
    self.popoverController = nil;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    for (UIView *subview in volumeToolbar.subviews) {
        if ([subview isKindOfClass:[MPVolumeView class]]) {
            [subview setFrame:CGRectMake(0, 0, self.toolbar.frame.size.width-55, 20)];
            [subview setCenter:CGPointMake(((self.toolbar.frame.size.width-55)/2)+45, 22)];
            [subview sizeToFit];
        }
    }
    
    for (UIView *subview in opsToolbar.subviews) {
        if ([subview isKindOfClass:[UIButton class]]) {
            [subview setFrame:CGRectMake(self.opsToolbar.frame.size.width/2-50, self.opsToolbar.frame.size.height/2-12, 100, 24)];
        }
    }
}

- (void)pop: (UIButton *)sender {
    NSLog(@"Pop!");
    [self.popoverController presentPopoverFromRect:sender.frame                                      inView: self.view permittedArrowDirections: UIPopoverArrowDirectionUp                                          animated: YES];
}


#pragma mark -
#pragma mark Network Code
- (void) checkNetworkStatus:(NSNotification *)notice
{
    // called after network status changes
    NetworkStatus internetStatus = [internetReachable currentReachabilityStatus];
    NetworkStatus hostStatus = [hostReachable currentReachabilityStatus];
    
    NSLog(@"** activity update:: internetActive=%i hostActive=%i internetStatus=%@ hostStatus=%@", self.internetActive, self.hostActive, (internetStatus==NotReachable?@"No":@"Yes"), (hostStatus==NotReachable?@"No":@"Yes"));
    
    
    if (internetStatus==NotReachable) {
        self.internetActive = NO;
    } else {
        self.internetActive = YES;
    }
    
    // handle first time callback
    if (hostActive==NO &&
        hostStatus!=NotReachable) {
        NSLog(@"Host is reachable but before it wasn't");
        self.hostActive = YES;
        if (hostStatus == ReachableViaWiFi) {
            [self setNetworkSpeed:ReachableViaWiFi];
        } else {
            [self setNetworkSpeed:ReachableViaWWAN];
        }
        
        if ([[rrrrradioAppDelegate rdioInstance] user] == nil) {
            NSString* savedToken = [[Settings settings] accessToken];
            if(savedToken != nil) {
                NSLog(@"Found access token! %@", savedToken);
//                [[rrrrradioAppDelegate rdioInstance] authorizeUsingAccessToken:savedToken fromController:nil];
            }       
        }
        
        [self reset];        
        
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {                    
            if ([[rrrrradioAppDelegate rdioInstance] user] == nil) {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{                        
                    self.artistData = [NSArray arrayWithArray:[[DataInterface issueCommand:@"data.php?v=newalbums"] yajl_JSON]]; 
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self enableRequests];            
                    });
                });
            }      
        }
        
        int poolingInterval=0;
        if (networkSpeed==ReachableViaWiFi) {
            poolingInterval = 20;
        } else if (networkSpeed==ReachableViaWWAN) {
            poolingInterval = 60;
        }
        
        if (poolingInterval>0) {
            [self enableBackgroundPooling:poolingInterval];            
        }
        
    } else if (hostActive==YES && (
                 hostStatus==NotReachable ||
                                   internetStatus==NotReachable)) {
        NSLog(@"internet suddenly down -- shut it all down");
        self.hostActive = NO;
        self.networkSpeed = NotReachable;
        
        [self stopStream];
        [queueLoader invalidate];
        queueLoader = nil;         
        
        if (internetStatus==NotReachable) {
            [hud setBlockTouches:NO];
            [hud setCaption:@"rrrrradio requires an internet connection."];
            [hud setImage:[UIImage imageNamed:@"11-x"]];
            [hud show];

        } else {
            [hud setBlockTouches:NO];
            [hud setCaption:@"rrrrradio cannot be contacted. Probably some more unscheduled maintenance."];
            [hud setImage:[UIImage imageNamed:@"11-x"]];
            [hud show];
            
            
        }
    } else if (hostStatus != networkSpeed) {
        [self setNetworkSpeed:hostStatus];
        // connection to host changed. update background pooling
        if ([queueLoader isValid]) {
            NSLog(@"Resetting background pooling");
            int poolingInterval = 120;
            if (hostStatus==ReachableViaWiFi) {
                poolingInterval = 20;
            } else if (hostStatus==ReachableViaWWAN) {
                poolingInterval = 60;
            }
            
            [self enableBackgroundPooling:poolingInterval];            
        }
    }
}

#pragma mark ATMHudDelegate
- (void)userDidTapHud:(ATMHud *)_hud {
	[_hud hide];
}

#pragma mark -
#pragma mark RDPlayerDelegate

- (void)rdioPlayerChangedFromState:(RDPlayerState)oldState toState:(RDPlayerState)newState {
    if (newState == 2) {
        NSLog(@"Play State");
        if (oldState == 2) {
            NSLog(@"...new track!");
            [_QUEUE getNext];
            [self refreshQueueDisplay]; 
            [self refreshLockDisplay];               
        }
        // Enter a playing state
        if ((oldState!=2) && (skip>0)) {
            RDPlayer* player = [[rrrrradioAppDelegate rdioInstance] player];            
            NSLog(@"Picking up at %d", skip);
            sleep(1);
            [player seekToPosition:skip];
            skip = -1;
        }
    } else if (newState == 3) {
        NSLog(@"Stopped State");        
        // Enter a stopped state
        if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateBackground) {
            NSLog(@"We're in the background, clean stuff up");
            [self stopStream];
            [self reset];      
            
            if ([queueLoader isValid]) {
                [queueLoader invalidate];                            
                queueLoader = nil;
            }            
        } else 
        if (skip < 0) {
            NSLog(@"New Track! (this code shouldn't ever fire)");
//            NSDictionary* currentTrack = [_QUEUE getNext];
//            [self playTrack:currentTrack];
            [self refreshQueueDisplay];
            [self refreshLockDisplay];
        } else {
            NSLog(@"Stopping. Skip is %d", skip);
        }
    } else {
        NSLog(@"Some other State");
        [self stopStream];
        [self reset];                
    }
	NSLog(@"*** Player changed from state: %d toState: %d", oldState, newState);

}

- (BOOL)rdioIsPlayingElsewhere {
    NSLog(@"*** Rdio is playing elsewhere **");
	return NO;
}


- (void)dealloc
{
    RDPlayer* player = [[rrrrradioAppDelegate rdioInstance] player];
    [player removeObserver:self forKeyPath:@"position"];
    [player removeObserver:self forKeyPath:@"currentTrack"];    
    [player stop];
    
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}


- (void) enableBackgroundPooling:(int) seconds {
    if ([queueLoader isValid]) {
        [queueLoader invalidate];                            
        queueLoader = nil;
    }
        
    if (queueLoader==nil) {
        NSLog(@"Enabling background pooling at a %i second interval", seconds);
        queueLoader = [NSTimer scheduledTimerWithTimeInterval:seconds target:self selector:@selector(updateQueue) userInfo:nil repeats:YES];    
    }

}

#pragma mark -
#pragma mark RdioDelegate methods

- (void)rdioDidAuthorizeUser:(NSDictionary *)user withAccessToken:(NSString *)accessToken {
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                   [user valueForKey:@"key"], @"keys", 
                                   @"isUnlimited", @"extras", 
                                   nil];
    [[rrrrradioAppDelegate rdioInstance] callAPIMethod:@"get" withParameters:params success:nil failure:nil];
    
    [[Settings settings] setUser:[NSString stringWithFormat:@"%@ %@", [user valueForKey:@"firstName"], [user valueForKey:@"lastName"]]];
    [[Settings settings] setAccessToken:accessToken];
    [[Settings settings] setUserKey:[user objectForKey:@"key"]];
    [[Settings settings] setIcon:[user objectForKey:@"icon"]];
    [[Settings settings] save];  

    [self enableRequests];
    
}

- (void)rdioDidLogout {
    [[Settings settings] setUser:nil];
    [[Settings settings] setAccessToken:nil];
    [[Settings settings] setUserKey:nil];
    [[Settings settings] setIcon:nil];
    [[Settings settings] save];      
}

/**
 * Our API call has returned successfully.
 * the data parameter can be an NSDictionary, NSArray, or NSData 
 * depending on the call we made.
 *
 * Here we will inspect the parameters property of the returned RDAPIRequest
 * to see what method has returned.
 */
- (void)rdioRequest:(RDAPIRequest *)request didLoadData:(id)data {
    NSLog(@"Returned data: %@", data);
    NSString *method = [request.parameters objectForKey:@"method"];
    if([method isEqualToString:@"get"]) {
        if ([data objectForKey:[[Settings settings] userKey]]!=nil) {
            // Returned data to see if logged in user has Unlimited account
            if ([[[data objectForKey:[[Settings settings] userKey]] objectForKey:@"isUnlimited"] integerValue] == 0 ) {
                // logout active account
                [[rrrrradioAppDelegate rdioInstance] logout];                
                
                [hud setBlockTouches:NO];
                [hud setCaption:@"rrrrradio requires an Rdio Unlimited account."];
                [hud setImage:[UIImage imageNamed:@"11-x"]];
                [hud show];
                [hud hideAfter:3.0];                            
            }
        } else {
            NSLog(@"some other api result came in");
        }
    }
}

- (void)rdioRequest:(RDAPIRequest *)request didFailWithError:(NSError*)error {
    
}



/**
 * Authentication failed so we should alert the user.
 */
- (void)rdioAuthorizationFailed:(NSString *)message {
    NSLog(@"Rdio authorization failed: %@", message);
}


#pragma mark - View lifecycle

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    /**
     * Make sure we are sent delegate messages.
     */
    [[rrrrradioAppDelegate rdioInstance] setDelegate:self];
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    // Let me know when the app goes foreground/background
    
    // Add HUD
	hud = [[ATMHud alloc] initWithDelegate:self];
    [self.view addSubview:hud.view];
    
    // Add volume slider
    MPVolumeView *volumeView = [[[MPVolumeView alloc] initWithFrame:CGRectMake(0, 0, self.toolbar.frame.size.width-55, 20)] autorelease];
    [volumeView setCenter:CGPointMake(((self.toolbar.frame.size.width-55)/2)+35, 22)];
    [volumeView sizeToFit];
    [volumeToolbar addSubview:volumeView];
    
    // check for internet connection
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkNetworkStatus:) name:kReachabilityChangedNotification object:nil];
    
    internetReachable = [[Reachability reachabilityForInternetConnection] retain];
    [internetReachable startNotifier];
    
    // check if a pathway to a random host exists
    hostReachable = [[Reachability reachabilityWithHostName: @"rrrrradio.com"] retain];
    [hostReachable startNotifier];
    
    // now patiently wait for the notification    
    
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    
    // Build and display the "current listeners" box
    listenersBg = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 100, 24)];
    [listenersBg setBackgroundColor:[UIColor blackColor]];
    // Round the corners
    CALayer *l = [self.listenersBg layer];
    [l setMasksToBounds:YES];
    [l setCornerRadius:8.0];
    // Add border
    [l setBorderWidth:1.0];
    [l setBorderColor:[[UIColor blackColor] CGColor]];    

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {                    
        // iPad specific tweaks
        
        UIView *containerView = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, upcoming.frame.size.width , 40)] autorelease];
        [upcoming setTableHeaderView:containerView];
        
        [upcoming setSeparatorColor:[UIColor clearColor]];
        [upcoming setSeparatorStyle:UITableViewCellSeparatorStyleSingleLine];
    }

    
    listenersLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 4, 80, 16)];
    [listenersLabel setText:@"0 Listeners"];
    [listenersLabel setBackgroundColor:[UIColor clearColor]];
    [listenersLabel setTextColor:[UIColor grayColor]];
    [listenersLabel setFont:[UIFont fontWithName:@"Trebuchet MS" size:12]];
    [listenersLabel setTextAlignment:NSTextAlignmentCenter];
    
    [listenersBg addSubview:listenersLabel];
    
    UIButton *listenerButton = [[UIButton alloc] initWithFrame:CGRectMake(self.opsToolbar.frame.size.width/2-50, self.opsToolbar.frame.size.height/2-12, 100, 24)];
    [listenerButton addTarget:self action:@selector(displayListeners) forControlEvents:UIControlEventTouchUpInside];
    [listenerButton setShowsTouchWhenHighlighted:YES];
    [listenerButton addSubview:listenersBg];
    
    
    [self.opsToolbar addSubview:listenerButton];
    
    [listenersLabel release];
    [listenersBg release];
    [listenerButton release];    

    [super viewDidLoad];
}

-(BOOL) canBecomeFirstResponder {
    return YES;
}

-(void) viewDidAppear:(BOOL)animated {
    [self becomeFirstResponder];
}

-(void) remoteControlReceivedWithEvent:(UIEvent *)event {
    
}


- (void)viewWillDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self];    
}

- (void)viewDidUnload
{
    [[UIApplication sharedApplication] endReceivingRemoteControlEvents];
    [_QUEUE release];
    [listenersBg release];
    [listenersLabel release];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // iPhone: Portrait only
    // iPad: Any orientation
    return ((interfaceOrientation == UIInterfaceOrientationPortrait) ||
            (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad));
}

-(NSUInteger)supportedInterfaceOrientations {
    return (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)?UIInterfaceOrientationMaskAll:UIInterfaceOrientationMaskPortrait;
}

- (BOOL)shouldAutorotate {
    return YES;
}

-(void)backgrounding {
    NSLog(@"Backgrounding");
}

-(void)foregrounding {
    NSLog(@"We're back!");
    
    [[NSUserDefaults standardUserDefaults] synchronize];            
    NSLog(@"Setting value: %@", [[NSUserDefaults standardUserDefaults] stringForKey:@"logout"]);
    
    if ([[[NSUserDefaults standardUserDefaults] stringForKey:@"logout"] isEqualToString:@"1"]) {
        NSLog(@"Resetting user account");
        // logout active account
        [[rrrrradioAppDelegate rdioInstance] logout];
        
        // reset logout flag to 0
        [[NSUserDefaults standardUserDefaults] setBool:0 forKey:@"logout"];
        [[NSUserDefaults standardUserDefaults] synchronize];        
    }
    if (internetActive && hostActive) {
        RDPlayer* player = [[rrrrradioAppDelegate rdioInstance] player];    
        if (player.state != RDPlayerStatePlaying) {
            NSLog(@"Initializing: Reset");
            [self stopStream];
            [self reset];
        } else {
            NSLog(@"Initializing: UpdateQueue");              
            [self updateQueue];        
        }
        if (queueLoader == nil) {
            int poolingInterval=0;
            if (networkSpeed==ReachableViaWiFi) {
                poolingInterval = 20;
            } else if (networkSpeed==ReachableViaWWAN) {
                poolingInterval = 60;
            }
            
            if (poolingInterval>0) {
                [self enableBackgroundPooling:poolingInterval];            
            }        
        }
    }

}

@end
