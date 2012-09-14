//
//  rrrrradioSplitViewController.m
//  rrrrradio
//
//  Created by Andy Soell on 9/14/12.
//  Copyright (c) 2012 rrrrradio. All rights reserved.
//

#import "rrrrradioSplitViewController.h"

@interface rrrrradioSplitViewController ()

@end

@implementation rrrrradioSplitViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // iPhone: Portrait only
    // iPad: Any orientation
    return ((interfaceOrientation == UIInterfaceOrientationPortrait) ||
            (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad));
}

-(NSUInteger)supportedInterfaceOrientations {
    NSLog(@"testing: svc");
    return UIInterfaceOrientationMaskAll;
}

- (BOOL)shouldAutorotate {
    return YES;
}


@end
