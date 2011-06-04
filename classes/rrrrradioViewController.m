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
#import <AVFoundation/AVFoundation.h>
#import <QuartzCore/QuartzCore.h>
#import "rrrrradioAppDelegate.h"
#import "CollectionBrowser.h"
#import "MusicQueue.h"
#import "DataInterface.h"
#import "Reachability.h"
#import "Settings.h"


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


#pragma mark -
#pragma mark Audio interaction methods

// Tell the RDPlayer object to start playing a specific track
- (void) playTrack:(NSDictionary *)trackData {
    RDPlayer *player = [[rrrrradioAppDelegate rdioInstance] player];
    [player playSource:[trackData objectForKey:@"key"]];  
    if (skip>0) {
        NSLog(@"Picking up at %d", skip);
        sleep(1);
        [player seekToPosition:skip];    
        skip = -1;
    }
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
            
            NSDictionary* currentTrack =  [_QUEUE getNext];

            [self playTrack:currentTrack];
            
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
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Network unreachable" message:@"rrrrradio requires an internet connection to work properly" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];            
            [alert show];
            [alert release];
        } else {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"rrrrradio unreachable" message:@"rrrrradio cannot be contacted. Probably some more unscheduled maintenance." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
            [alert show];
            [alert release];
            
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
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        if (_QUEUE!=nil) {
            [_QUEUE release];
            _QUEUE = nil;
        }
        sleep(5);
        
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
/*        
        [opsToolbar setFrame:CGRectOffset([opsToolbar frame], 0, -opsToolbar.frame.size.height)];
        [opsToolbar setAlpha:1.0];         
 */
    } else {
        [volumeToolbar setFrame:CGRectOffset([volumeToolbar frame], 0, -volumeToolbar.frame.size.height)];
        [volumeToolbar setAlpha:0.0];
   
/*        
        [opsToolbar setFrame:CGRectOffset([opsToolbar frame], 0, +opsToolbar.frame.size.height)];
        [opsToolbar setAlpha:0.0];    
 */
    }
    [UIView commitAnimations];
}


// Tell the UITableView to refresh itself. Probably a better way to do this
- (void)refreshQueueDisplay {
    [upcoming reloadData];
    [self.listenersLabel setText:[NSString stringWithFormat:@"%i Listener%@", [self.listeners count], [self.listeners count]!=1?@"s":@""]];    
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
    [listenerView setTitle:@"Now Listening"];

    UIBarButtonItem *done = [[UIBarButtonItem alloc] 
                             initWithTitle:@"Done" 
                             style:UIBarButtonItemStyleDone 
                             target:self action:@selector(dismissListeners)];
    [listenerView.navigationItem setRightBarButtonItem:done];
    [done release];    
    
    listenerController = [[UINavigationController alloc] initWithRootViewController:listenerView];
    [listenerController.navigationBar setTintColor:[UIColor colorWithRed:185.0f/255.0f green:80.0f/255.0f blue:0.0f/255.0f alpha:1.0f]];

    [self presentModalViewController:listenerController animated:YES];    
    [listenerController release];
    [listenerView release];
}

- (void) dismissListeners {
    [listenerController dismissModalViewControllerAnimated:YES];
    listenerController = nil;
}

#pragma mark Queue UITableView construction

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return ([_QUEUE length]);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    NSDictionary *track = [_QUEUE trackAt:indexPath.row];     
    
    NSString *cellType;
    UITableViewCell *cell;
    
    if (indexPath.row == 0) {
        cellType = @"NowPlayingCell";
        cell = (NowPlayingCell*)[track objectForKey:cellType];
    } else {
        cellType = @"UpcomingCell";
        cell = (UpcomingCell*)[track objectForKey:cellType];        
    }
    
    if (cell == nil) {
        // Create the now playing cell
        NSArray *nibObjects = [[NSBundle mainBundle] loadNibNamed:@"NowPlayingCell" owner:self options:nil];
        for (id obj in nibObjects) {
            if ([obj isKindOfClass:[NowPlayingCell class]]) {
                cell = (NowPlayingCell*)obj;
                [cell performSelector:@selector(setTrackData:) withObject:track]; 
                [track setValue:cell forKey:@"NowPlayingCell"];                  
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
            }
        }
        
        cell = [track objectForKey:cellType];
    }

    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([indexPath row]==0) return 320.0;
    return 44.0;
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
            [self presentModalViewController:navigationController animated:YES];

            [collection release];        
            [navigationController release];
        } else if (item.tag == 2) {
            UIActionSheet *ops = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Love it", @"Hate it", nil];
            [ops showInView:self.view];
            
            [ops autorelease];
        }
    } else {
        if (!self.internetActive) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Network unreachable" message:@"rrrrradio requires an internet connection to work properly" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];            
            [alert show];
            [alert release];
        } else {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"rrrrradio unreachable" message:@"rrrrradio cannot be contacted. Probably some more unscheduled maintenance." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
            [alert show];
            [alert release];
            
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
        } else if (buttonIndex==1) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{                
                [DataInterface issueCommand:[NSString stringWithFormat:@"/controller.php?r=mark&key=%@&val=-1",[player currentTrack]]];
            });
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
    });
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row==0) {
        [self toggleHUD];
    }
}

#pragma mark -
#pragma mark Split View Delegate code

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
        if ([subview isKindOfClass:[UIImageView class]]) {
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
                [[rrrrradioAppDelegate rdioInstance] authorizeUsingAccessToken:savedToken fromController:nil];
            }       
        }
        
        [self reset];        
        
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {                    
            if ([[rrrrradioAppDelegate rdioInstance] user] == nil) {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{                        
                    self.artistData = [NSArray arrayWithArray:[[DataInterface issueCommand:@"data.php?"] yajl_JSON]]; 
                    
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
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Network unreachable" message:@"rrrrradio requires an internet connection to work properly" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];            
            [alert show];
            [alert release];
        } else {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"rrrrradio unreachable" message:@"rrrrradio cannot be contacted. Probably some more unscheduled maintenance." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
            [alert show];
            [alert release];
            
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

#pragma mark -
#pragma mark RDPlayerDelegate

- (void)rdioPlayerChangedFromState:(RDPlayerState)oldState toState:(RDPlayerState)newState {
    if (newState == 2) {
        // Enter a playing state
    } else if (newState == 3) {
        // Enter a stopped state
        if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateBackground) {
            NSLog(@"We're in the background, clean stuff up");
            [self stopStream];
            [self reset];                
        } else 
        if (skip < 0) {
            NSLog(@"New Track!");
            NSDictionary* currentTrack = [_QUEUE getNext];
            [self playTrack:currentTrack];
            [self refreshQueueDisplay];
            sleep(5);            
        } else {
            NSLog(@"Stopping. Skip is %d", skip);
        }
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
    [[Settings settings] setUser:[NSString stringWithFormat:@"%@ %@", [user valueForKey:@"firstName"], [user valueForKey:@"lastName"]]];
    [[Settings settings] setAccessToken:accessToken];
    [[Settings settings] setUserKey:[user objectForKey:@"key"]];
    [[Settings settings] setIcon:[user objectForKey:@"icon"]];
    [[Settings settings] save];  

    [self enableRequests];
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
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(backgrounding:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(foregrounding:) name:UIApplicationDidBecomeActiveNotification object: nil];
    
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
    self.listenersBg = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 100, 24)];
    [self.listenersBg setBackgroundColor:[UIColor blackColor]];
    // Round the corners
    CALayer *l = [self.listenersBg layer];
    [l setMasksToBounds:YES];
    [l setCornerRadius:8.0];
    // Add border
    [l setBorderWidth:1.0];
    [l setBorderColor:[[UIColor blackColor] CGColor]];        
    
    self.listenersLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 4, 80, 16)];
    [self.listenersLabel setText:@"0 Listeners"];
    [self.listenersLabel setBackgroundColor:[UIColor clearColor]];
    [self.listenersLabel setTextColor:[UIColor grayColor]];
    [self.listenersLabel setFont:[UIFont fontWithName:@"Trebuchet MS" size:12]];
    [self.listenersLabel setTextAlignment:UITextAlignmentCenter];
    
    [listenersBg addSubview:listenersLabel];
    
    UIButton *listenerButton = [[UIButton alloc] initWithFrame:CGRectMake(self.opsToolbar.frame.size.width/2-50, self.opsToolbar.frame.size.height/2-12, 100, 24)];
    [listenerButton addTarget:self action:@selector(displayListeners) forControlEvents:UIControlEventTouchUpInside];
    [listenerButton setShowsTouchWhenHighlighted:YES];
    [listenerButton addSubview:listenersBg];
    
    [self.opsToolbar addSubview:listenerButton];
    
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
    // Return YES for supported orientations
    //return (interfaceOrientation == UIInterfaceOrientationPortrait);
    return YES;
}

-(void)backgrounding:(NSNotification *)notification {
    NSLog(@"Backgrounding");
    [queueLoader invalidate];
    queueLoader = nil;
}

-(void)foregrounding:(NSNotification *)notification {
    NSLog(@"We're back!");
    
    if (internetActive && hostActive) {
        RDPlayer* player = [[rrrrradioAppDelegate rdioInstance] player];    
        if (player.state != RDPlayerStatePlaying) {
            [self reset];
        } else {
            [self updateQueue];        
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
    }

}

@end
