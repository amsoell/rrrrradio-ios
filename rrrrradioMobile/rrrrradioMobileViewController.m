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

@implementation rrrrradioMobileViewController
@synthesize coverart;
@synthesize song_name;
@synthesize song_artist;
@synthesize song_album;

- (void)playStream {
    if ([[rrrrradioMobileAppDelegate rdioInstance] user] == nil) {
        [[rrrrradioMobileAppDelegate rdioInstance] authorizeFromController:self];
    } else {
        NSLog(@"Current user data: %@", [[rrrrradioMobileAppDelegate rdioInstance] user]);
        
        NSURL *queueURL = [[NSURL alloc] initWithString:@"http://rrrrradio.com/controller.php?r=getQueue"];
        NSString *JSONData = [[NSString alloc] initWithContentsOfURL:queueURL];
        
        NSDictionary *arrayData = [JSONData yajl_JSON];
        NSArray *queue = [arrayData objectForKey:@"queue"];    
        NSDictionary *currentTrack = [queue objectAtIndex:0];
        NSLog(@"Attempting to play %@", [currentTrack yajl_JSONString]);
        
        // Set UI elements
        UIImage *art = [[UIImage alloc] initWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:[currentTrack objectForKey:@"icon"]]]];
        [coverart setImage:art];
        [song_name setText:[currentTrack objectForKey:@"name"]];
        [song_artist setText:[currentTrack objectForKey:@"artist"]];
        [song_album setText:[currentTrack objectForKey:@"album"]];

        
        RDPlayer *player = [[rrrrradioMobileAppDelegate rdioInstance] player];
        [player playSource:[currentTrack objectForKey:@"key"]];
//        [player seekToPosition:((double *)[arrayData objectForKey:@"timestamp"] - (double *)[currentTrack objectForKey:@"startplay"])];
        
        [queueURL release];
        [JSONData release];
    }
}

- (void)dealloc
{
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

/*
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
}
*/

- (void)viewDidUnload
{
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
