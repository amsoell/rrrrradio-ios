//
//  rrrrradioAppDelegate.m
//  rrrrradio
//
//  Created by Andy Soell on 5/11/11.
//  Copyright 2011 The Institute for Justice. All rights reserved.
//
//  Several icons from the Glyphish icon set,
//  with kind permission of Joseph Wain.
//  You can get them here: http://glyphish.com/
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
@synthesize splitController, navigationController, mainController;

+ (Rdio*)rdioInstance {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults]; 
    NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"]; 
    
    [defaults setObject:version forKey:@"version"];

    
    return[(rrrrradioAppDelegate*)[[UIApplication sharedApplication] delegate] rdio];
}

void uncaughtExceptionHandler(NSException *exception) {
    [FlurryAnalytics logError:@"Uncaught" message:@"Crash!" exception:exception];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
//    NSSetUncaughtExceptionHandler(&uncaughtExceptionHandler); 
    [FlurryAnalytics setAppVersion:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"]];    
    [FlurryAnalytics startSession:@"PMLKQP2STQCRL1C2VBG5"];
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {    
        NSArray *artistData = [NSArray arrayWithArray:[[DataInterface issueCommand:@"data.php?v=newalbums"] yajl_JSON]];

        navigationController = [[UINavigationController alloc] init];
        [navigationController.navigationBar setTintColor:[UIColor colorWithRed:185.0f/255.0f green:80.0f/255.0f blue:0.0f/255.0f alpha:1.0f]];
        
        CollectionBrowser *collection = [[CollectionBrowser alloc] initWithNibName:@"CollectionBrowser" bundle:nil];
        [collection setDataSource:artistData];
        [collection setTitle:@"Artists"];
        [collection setOwner:self.viewController];
        [self.navigationController pushViewController:collection animated:NO];   
        [collection release];

        mainController = [[rrrrradioViewController alloc] initWithNibName:@"rrrrradioViewControllerIpad" bundle:nil];        
        
        splitController = [[UISplitViewController alloc] init];
        [splitController setDelegate:self.mainController];        
        
        splitController.viewControllers = [NSArray arrayWithObjects:navigationController, mainController, nil];
        
        [self.window addSubview:splitController.view];
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
    NSLog(@"applicationWillResignActive");    
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
     */
    NSLog(@"applicationDidEnterBackground");
    [self.viewController backgrounding];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    /*
     Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
     */
    NSLog(@"applicationWillEnterForeground");    
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
    NSLog(@"applicationDidBecomeActive");
    [self.viewController foregrounding];
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
        [splitController release];
        [navigationController release]; 
        [mainController release];
    }
    [rdio release];
    [super dealloc];
}






@end
