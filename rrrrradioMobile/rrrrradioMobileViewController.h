//
//  rrrrradioMobileViewController.h
//  rrrrradioMobile
//
//  Created by Andy Soell on 5/11/11.
//  Copyright 2011 The Institute for Justice. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface rrrrradioMobileViewController : UIViewController {
    IBOutlet UIImageView *coverart;
    IBOutlet UITextField *song_name;
    IBOutlet UITextField *song_artist;
    IBOutlet UITextField *song_album;
}

- (IBAction)playStream;

@property (nonatomic, retain) IBOutlet UIImageView *coverart;
@property (nonatomic, retain) IBOutlet UITextField *song_name;
@property (nonatomic, retain) IBOutlet UITextField *song_artist;
@property (nonatomic, retain) IBOutlet UITextField *song_album;

@end
