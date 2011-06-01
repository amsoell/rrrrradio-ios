//
//  rrrrradioAppDelegate.m
//  rrrrradio
//
//  Created by Andy Soell on 5/11/11.
//  Copyright 2011 The Institute for Justice. All rights reserved.
//

#import "rrrrradioAppDelegate.h"
#import "rrrrradioViewController.h"
#import "CollectionBrowser.h"
#import "DataInterface.h"
#import <YAJLiOS/YAJL.h>
#import "Settings.h"

@implementation rrrrradioAppDelegate
@synthesize window=_window;
@synthesize viewController=_viewController;
@synthesize rdio;
@synthesize splitController, navigationController;

+ (Rdio*)rdioInstance {
    return[(rrrrradioAppDelegate*)[[UIApplication sharedApplication] delegate] rdio];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {    
        NSArray *artistData = [NSArray arrayWithArray:[[DataInterface issueCommand:@"data.php?"] yajl_JSON]];

        self.navigationController = [[UINavigationController alloc] init];
        CollectionBrowser *collection = [[CollectionBrowser alloc] initWithNibName:@"CollectionBrowser" bundle:nil];
        [collection setDataSource:artistData];
        [collection setTitle:@"Artists"];
        [collection setOwner:self.viewController];
        [self.navigationController pushViewController:collection animated:NO];   
        [collection release];
        
        splitController = [[UISplitViewController alloc] init];
        self.splitController.viewControllers = [NSArray arrayWithObjects:navigationController, self.viewController, nil];
        
        [self.window addSubview:self.splitController.view];
    } else {
        self.window.rootViewController = self.viewController;
    }
    
    [self.window makeKeyAndVisible];
    
    [application setStatusBarStyle:UIStatusBarStyleBlackOpaque];
    rdio = [[Rdio alloc] initWithConsumerKey:@"q4ybz268x42yttz7k8fsfdn6" andSecret:@"3KEeT5DAVf" delegate:nil];
        
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
     */
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    /*
     Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
     */
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    /*
     Called when the application is about to terminate.
     Save data if appropriate.
     See also applicationDidEnterBackground:.
     */
    
}

- (void)dealloc
{
    [_window release];
    [_viewController release];
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {        
        [self.splitController release];
        [self.navigationController release];    
    }
    [rdio release];
    [super dealloc];
}

@end
