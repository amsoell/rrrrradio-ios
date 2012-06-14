//
//  rrrrradioAppDelegate.h
//  rrrrradio
//
//  Created by Andy Soell on 5/11/11.
//  Copyright 2011 The Institute for Justice. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Rdio/Rdio.h>
#import "CollectionBrowser.h"
#import "rrrrradioViewController.h"

@class rrrrradioViewController;

@interface rrrrradioAppDelegate : NSObject <UIApplicationDelegate> {
    Rdio *rdio;
    UISplitViewController *splitController;
    UINavigationController *navigationController;
    rrrrradioViewController *mainController;
}

+ (Rdio*)rdioInstance;
void uncaughtExceptionHandler(NSException *exception);

@property (readonly) Rdio *rdio;
@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet rrrrradioViewController *viewController;
@property (nonatomic, retain) UISplitViewController *splitController;
@property (nonatomic, retain) UINavigationController *navigationController;
@property (nonatomic, retain) rrrrradioViewController *mainController;

@end
