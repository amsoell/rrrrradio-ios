//
//  rrrrradioMobileAppDelegate.h
//  rrrrradioMobile
//
//  Created by Andy Soell on 5/11/11.
//  Copyright 2011 The Institute for Justice. All rights reserved.
//

#import <UIKit/UIKit.h>

@class rrrrradioMobileViewController;

@interface rrrrradioMobileAppDelegate : NSObject <UIApplicationDelegate> {

}

@property (nonatomic, retain) IBOutlet UIWindow *window;

@property (nonatomic, retain) IBOutlet rrrrradioMobileViewController *viewController;

@end
