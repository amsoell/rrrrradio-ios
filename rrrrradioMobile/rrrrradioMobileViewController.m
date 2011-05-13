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
#import "rrrrradioMobileAppDelegate.h"
#import "MusicQueue.h"
#import "Settings.h"

@implementation rrrrradioMobileViewController
@synthesize coverart;
@synthesize song_name;
@synthesize song_artist;
@synthesize playbutton;
@synthesize trackmask;
@synthesize artmask;
@synthesize skip;
@synthesize _QUEUE;
@synthesize queueLoader;
@synthesize upcoming;
@synthesize progress;

- (void) playTrack:(NSDictionary *)trackData {
    // Set UI elements
    
    [self refreshQueueDisplay];
    
    RDPlayer *player = [[rrrrradioMobileAppDelegate rdioInstance] player];
    [player playSource:[trackData objectForKey:@"key"]];  
    if (skip>0) {
        sleep(1);
        [player seekToPosition:skip];    
        skip = -1;
    }
}

- (void)playStream {
    if ([[rrrrradioMobileAppDelegate rdioInstance] user] == nil) {
        [[rrrrradioMobileAppDelegate rdioInstance] authorizeFromController:self];
    } else {
        [playbutton setImage:[UIImage imageNamed:@"ajax-loader-large-dark.gif"] forState:UIControlStateNormal];
        
        RDPlayer *player = [[rrrrradioMobileAppDelegate rdioInstance] player];
        [player setDelegate:self];        
        [player addObserver:self forKeyPath:@"position" options:NSKeyValueObservingOptionNew context:nil];        
        
        NSLog(@"Current user data: %@", [[rrrrradioMobileAppDelegate rdioInstance] user]);
        NSDictionary* currentTrack =  [_QUEUE getNext];

        [self playTrack:currentTrack];
        queueLoader = [NSTimer scheduledTimerWithTimeInterval:15 target:self selector:@selector(updateQueue) userInfo:nil repeats:YES];
    }
}

- (void)refreshQueueDisplay {
    // current track in the spotlight
    NSDictionary *currentTrack = [_QUEUE currentTrack];
    UIImage *art = [[UIImage alloc] initWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:[currentTrack objectForKey:@"bigIcon"]]]];
    [coverart setImage:art];
    [song_name setText:[currentTrack objectForKey:@"name"]];
    [song_artist setText:[currentTrack objectForKey:@"artist"]];
    [art release];    
    
    // populate next two songs
    [upcoming reloadData];


    
    
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    RDPlayer *player = [[rrrrradioMobileAppDelegate rdioInstance] player];

    if([keyPath isEqualToString:@"position"]) {
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

- (void)updateQueue {
    NSURL *queueURL = [[NSURL alloc] initWithString:@"http://rrrrradio.com/controller.php?r=getQueue"];
    NSString *JSONData = [[NSString alloc] initWithContentsOfURL:queueURL];
    
    NSLog(@"Running update queue");    
    
    NSDictionary *arrayData = [JSONData yajl_JSON];
    NSArray *queue = [arrayData objectForKey:@"queue"];    

    [_QUEUE updateQueue:queue];
    
    [queueURL release];
    [JSONData release];
}

#pragma mark -
#pragma mark Table View: Queue

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return ([_QUEUE length] - 1);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"icon"];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle: UITableViewCellStyleSubtitle reuseIdentifier:@"track"];

        cell.textLabel.textColor = [UIColor whiteColor];
        cell.textLabel.backgroundColor = [UIColor clearColor];
        cell.detailTextLabel.textColor = [UIColor lightGrayColor];
        cell.detailTextLabel.backgroundColor = [UIColor clearColor];
        
        UIImageView *cellBg = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"UITableViewCell-bg.jpg"]];
        cell.backgroundView = cellBg;   
        [cellBg release];        
    }

    
    NSDictionary *track = [_QUEUE trackAt:indexPath.row+1];    
    cell.textLabel.text = [track objectForKey:@"name"];    
    cell.detailTextLabel.text = [track objectForKey:@"artist"];    

    UIImage *art = [[UIImage alloc] initWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:[track objectForKey:@"icon"]]]];
    cell.imageView.image = art;


    [cell autorelease];       
    [art release];

    return cell;
}

#pragma mark -
#pragma mark RDPlayerDelegate

- (void)rdioPlayerChangedFromState:(RDPlayerState)oldState toState:(RDPlayerState)newState {
    if (newState == 2) {
        [playbutton setHidden:YES];
        [artmask setHidden:YES];
    } else if (newState == 3) {
        NSDictionary* currentTrack = [_QUEUE getNext];
        [self playTrack:currentTrack];
        
        [self refreshQueueDisplay];
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

#pragma mark -
#pragma mark RdioDelegate methods

- (void)rdioDidAuthorizeUser:(NSDictionary *)user withAccessToken:(NSString *)accessToken {
    [[Settings settings] setUser:[NSString stringWithFormat:@"%@ %@", [user valueForKey:@"firstName"], [user valueForKey:@"lastName"]]];
    [[Settings settings] setAccessToken:accessToken];
    [[Settings settings] setUserKey:[user objectForKey:@"key"]];
    [[Settings settings] setIcon:[user objectForKey:@"icon"]];
    [[Settings settings] save];  
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
    NSURL *queueURL = [[NSURL alloc] initWithString:@"http://rrrrradio.com/controller.php?r=getQueue"];
    NSString *JSONData = [[NSString alloc] initWithContentsOfURL:queueURL];
    
    NSDictionary *arrayData = [JSONData yajl_JSON];
    NSArray *queue = [arrayData objectForKey:@"queue"];    
    _QUEUE = [[MusicQueue alloc] initWithTrackData:queue];
    
    skip = [[arrayData objectForKey:@"timestamp"] intValue] - [[[queue objectAtIndex:0] objectForKey:@"startplay"] intValue];
    
    [self refreshQueueDisplay];
 
    [JSONData release];
    [queueURL release];
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

@end
