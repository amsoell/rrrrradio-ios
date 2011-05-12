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

@implementation rrrrradioMobileViewController
@synthesize coverart;
@synthesize song_name;
@synthesize song_artist;
@synthesize playbutton;
@synthesize trackmask;
@synthesize skip;
@synthesize _QUEUE;
@synthesize queueLoader;

- (void) playTrack:(NSDictionary *)trackData {
    // Set UI elements
    
    UIImage *art = [[UIImage alloc] initWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:[trackData objectForKey:@"bigIcon"]]]];
    [coverart setImage:art];
    [song_name setText:[trackData objectForKey:@"name"]];
    [song_artist setText:[trackData objectForKey:@"artist"]];
    
    RDPlayer *player = [[rrrrradioMobileAppDelegate rdioInstance] player];
    [player playSource:[trackData objectForKey:@"key"]];  
    
    [art release];
}

- (void)playStream {
    if ([[rrrrradioMobileAppDelegate rdioInstance] user] == nil) {
        [[rrrrradioMobileAppDelegate rdioInstance] authorizeFromController:self];
    } else {
        [playbutton setImage:[UIImage imageNamed:@"trackbg.png"] forState:UIControlStateNormal];
        
        RDPlayer *player = [[rrrrradioMobileAppDelegate rdioInstance] player];
        [player setDelegate:self];        
        [player addObserver:self forKeyPath:@"position" options:NSKeyValueObservingOptionNew context:nil];        
        
        NSLog(@"Current user data: %@", [[rrrrradioMobileAppDelegate rdioInstance] user]);
        NSDictionary* currentTrack =  [_QUEUE getNext];

        [self playTrack:currentTrack];
        queueLoader = [NSTimer scheduledTimerWithTimeInterval:15 target:self selector:@selector(updateQueue) userInfo:nil repeats:YES];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
/*    
    RDPlayer *player = [[rrrrradioMobileAppDelegate rdioInstance] player];

    if([keyPath isEqualToString:@"position"]) {
        if(player.position > 0) {
            [song_position setText:[NSString stringWithFormat:@"%f",[player position]]];
        }
    }
*/ 
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
#pragma mark RDPlayerDelegate

- (void)skipButton {

 
}

- (void)rdioPlayerChangedFromState:(RDPlayerState)oldState toState:(RDPlayerState)newState {
    if (newState == 2) {
        [playbutton setHidden:YES];
/*            
            NSLog(@"Jump to %i", skip);
            sleep(2);
            [player seekToPosition:skip];   
*/
    } else if (newState == 3) {
        NSDictionary* currentTrack = [_QUEUE getNext];
        [self playTrack:currentTrack];
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

#pragma mark - View lifecycle

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [trackmask setImage:[UIImage imageNamed:@"trackbg.png"]];
    
    NSURL *queueURL = [[NSURL alloc] initWithString:@"http://rrrrradio.com/controller.php?r=getQueue"];
    NSString *JSONData = [[NSString alloc] initWithContentsOfURL:queueURL];
    
    NSDictionary *arrayData = [JSONData yajl_JSON];
    NSArray *queue = [arrayData objectForKey:@"queue"];    
    
    _QUEUE = [[MusicQueue alloc] initWithTrackData:queue];
 
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
