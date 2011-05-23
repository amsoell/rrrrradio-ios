//
//  rrrrradioMobileViewController.m
//  rrrrradioMobile
//
//  Created by Andy Soell on 5/11/11.
//  Copyright 2011 The Institute for Justice. All rights reserved.
//

#import "rrrrradioMobileViewController.h"
#import <Rdio/Rdio.h>
#import <YAJLiOS/YAJL.h>
#import <MediaPlayer/MPVolumeView.h>
#import "rrrrradioMobileAppDelegate.h"
#import "CollectionBrowser.h"
#import "MusicQueue.h"
#import "DataInterface.h"
#import "Settings.h"

@implementation rrrrradioMobileViewController
@synthesize skip;
@synthesize _QUEUE;
@synthesize queueLoader;
@synthesize upcoming;
@synthesize progress;
@synthesize volumeToolbar;
@synthesize opsToolbar;
@synthesize blackout;
@synthesize artistData;

#pragma mark -
#pragma mark Audio interaction methods

// Tell the RDPlayer object to start playing a specific track
- (void) playTrack:(NSDictionary *)trackData {
    RDPlayer *player = [[rrrrradioMobileAppDelegate rdioInstance] player];
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
    if ([[rrrrradioMobileAppDelegate rdioInstance] user] == nil) {
        [[rrrrradioMobileAppDelegate rdioInstance] authorizeFromController:self];
    } else {
        RDPlayer *player = [[rrrrradioMobileAppDelegate rdioInstance] player];
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
}

// Stop the audio playback and reset the system back to infant state
- (void)stopStream {
    RDPlayer *player = [[rrrrradioMobileAppDelegate rdioInstance] player];
    
    skip = [player position];
    CGRect frame = [progress frame];
    frame.origin.x = -320;
    
    [progress setFrame:frame];
    [player stop];
    [_QUEUE cancelPlayback];

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
    NSDictionary *arrayData = [[DataInterface issueCommand:@"controller.php?r=getQueue"] yajl_JSON];
    NSArray *queue = [arrayData objectForKey:@"queue"];    
    _QUEUE = [[MusicQueue alloc ] initWithTrackData:queue];
    
    skip = [[arrayData objectForKey:@"timestamp"] intValue] - [[[queue objectAtIndex:0] objectForKey:@"startplay"] intValue];
    NSLog(@"--skip: %d", skip);
    
    [self refreshQueueDisplay];    
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
        
        [opsToolbar setFrame:CGRectOffset([opsToolbar frame], 0, -opsToolbar.frame.size.height)];
        [opsToolbar setAlpha:1.0];         
    } else {
        [volumeToolbar setFrame:CGRectOffset([volumeToolbar frame], 0, -volumeToolbar.frame.size.height)];
        [volumeToolbar setAlpha:0.0];
        
        [opsToolbar setFrame:CGRectOffset([opsToolbar frame], 0, +opsToolbar.frame.size.height)];
        [opsToolbar setAlpha:0.0];    
    }
    [UIView commitAnimations];
}


// Tell the UITableView to refresh itself. Probably a better way to do this
- (void)refreshQueueDisplay {
    [upcoming reloadData];
/*
    for (UITableViewCell *cell in [upcoming visibleCells]) {
        [cell setNeedsDisplay];
    }
*/ 
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

#pragma mark Queue UITableView construction

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return ([_QUEUE length]);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    NSDictionary *track = [_QUEUE trackAt:indexPath.row];   
    NSLog(@"Loading: %@", track);    
    
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
    
    if (item.tag == 1) {
        UINavigationController *navigationController = [[UINavigationController alloc] init];
        
        CollectionBrowser *collection = [[CollectionBrowser alloc] initWithNibName:@"CollectionBrowser" bundle:nil];
        [collection setDataSource:artistData];
        [collection setTitle:@"Artists"];
        
        [navigationController pushViewController:collection animated:NO];        
        [self presentModalViewController:navigationController animated:YES];

        [collection release];        
        [navigationController release];
    } else if (item.tag == 2) {
        UIActionSheet *ops = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Love it", @"Hate it", nil];
        [ops showInView:self.view];
        
        [ops autorelease];
    }
}

// Receive button presses from the action menu
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    RDPlayer *player = [[rrrrradioMobileAppDelegate rdioInstance] player];
    
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
        RDPlayer *player = [[rrrrradioMobileAppDelegate rdioInstance] player];        
        
        float x = [player position]/[[[_QUEUE currentTrack] objectForKey:@"duration"] doubleValue] *320 - 320;
        if (x>0) x = 0; // Don't let it go too far to the right;
        
        if(player.position > 0) {
            CGRect frame = [progress frame];
            frame.origin.x = x;
            frame.origin.y = 0.0;
            
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

        int size = [_QUEUE length];
        [_QUEUE updateQueue:queue];
        
        // update the skip value if we aren't playing
        RDPlayer* player = [[rrrrradioMobileAppDelegate rdioInstance] player];        
        if ([player state] != RDPlayerStatePlaying) {
            skip = [[arrayData objectForKey:@"timestamp"] intValue] - [[[queue objectAtIndex:0] objectForKey:@"startplay"] intValue];
            [_QUEUE prune:[_QUEUE length]];
        }
        
        // If the queue size changed, update the display
        if ([_QUEUE length]!=size) {
            [self refreshQueueDisplay];
        }
    });
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row==0) {
        [self toggleHUD];
    }
}

#pragma mark -

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
        } else if (skip < 0) {
            NSLog(@"New Track!");
            NSDictionary* currentTrack = [_QUEUE getNext];
            [self playTrack:currentTrack];
            [self refreshQueueDisplay];
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
    RDPlayer* player = [[rrrrradioMobileAppDelegate rdioInstance] player];
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


- (void) enableBackgroundPooling {
    if (queueLoader==nil) {
        NSLog(@"Enabling background pooling");
        queueLoader = [NSTimer scheduledTimerWithTimeInterval:15 target:self selector:@selector(updateQueue) userInfo:nil repeats:YES];    
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
    [[rrrrradioMobileAppDelegate rdioInstance] setDelegate:self];
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    NSLog(@"View Did Load");
    
    // Initialize the player pieces
    [self reset];    
    
    // Let me know when the app goes foreground/background
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(backgrounding:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(foregrounding:) name:UIApplicationDidBecomeActiveNotification object: nil];
    
    // Add volume slider
    MPVolumeView *volumeView = [[[MPVolumeView alloc] initWithFrame:CGRectMake(0, 0, 265, 20)] autorelease];
    [volumeView setCenter:CGPointMake(170, 22)];
    [volumeView sizeToFit];
    [volumeToolbar addSubview:volumeView];
    
    if ([[rrrrradioMobileAppDelegate rdioInstance] user] == nil) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{                        
            self.artistData = [NSArray arrayWithArray:[[DataInterface issueCommand:@"data.php?"] yajl_JSON]]; 

            [self enableRequests];            
        });

    }
 
    [super viewDidLoad];
}

- (void)viewDidUnload
{
    [_QUEUE release];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

-(void)backgrounding:(NSNotification *)notification {
    NSLog(@"Backgrounding");
    [queueLoader invalidate];
    queueLoader = nil;
}

-(void)foregrounding:(NSNotification *)notification {
    NSLog(@"We're back!");
    
    [self updateQueue];        
    [self enableBackgroundPooling];    

}

@end
