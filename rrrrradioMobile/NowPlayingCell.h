//
//  NowPlayingCell.h
//  rrrrradioMobile
//
//  Created by Andy Soell on 5/15/11.
//  Copyright 2011 The Institute for Justice. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface NowPlayingCell : UITableViewCell {
    IBOutlet UILabel *textLabel;
    IBOutlet UILabel *detailTextLabel;
    IBOutlet UIImageView *imageView;
    IBOutlet UIActivityIndicatorView *spinner;
    NSDictionary *trackData;
}

- (void) reset;

@property (nonatomic, retain) IBOutlet UILabel *textLabel;
@property (nonatomic, retain) IBOutlet UILabel *detailTextLabel;
@property (nonatomic, retain) IBOutlet UIImageView *imageView;
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView *spinner;
@property (nonatomic, retain) NSDictionary *trackData;



@end
