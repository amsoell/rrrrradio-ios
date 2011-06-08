//
//  NowPlayingCell.m
//  rrrrradio
//
//  Created by Andy Soell on 5/15/11.
//  Copyright 2011 The Institute for Justice. All rights reserved.
//

#import "NowPlayingCell.h"
#import <QuartzCore/QuartzCore.h>

@implementation NowPlayingCell
@synthesize textLabel, detailTextLabel, imageView, userView, userImage, userLabel, spinner;
@synthesize trackData;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setTrackData:(NSDictionary *)track {

    [textLabel setText:[track objectForKey:@"name"]];
    [detailTextLabel setText:[track objectForKey:@"artist"]];   
    
    // add user info if available
    if (![[track objectForKey:@"user"] isKindOfClass:[NSNull class]]) {
        NSDictionary *user = [track objectForKey:@"user"];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{    
            // user Icon
            NSString *userArtCachedName = [NSString stringWithFormat:@"%@.png", [user objectForKey:@"key"]];
            NSString *userArtCachedFullPath = [[NSHomeDirectory() stringByAppendingPathComponent:@"Documents"] 
                                               stringByAppendingPathComponent:userArtCachedName];
            UIImage *image = nil;
            if([[NSFileManager defaultManager] fileExistsAtPath:userArtCachedFullPath]) {
                image = [UIImage imageWithContentsOfFile:userArtCachedFullPath];
            } else {
                NSString *artUrl = [user objectForKey:@"icon"];
                image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:artUrl]]];
                // save it to disk
                NSData *imageData = [NSData dataWithData:UIImagePNGRepresentation(image)];
                [imageData writeToFile:userArtCachedFullPath atomically:YES];
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [userImage setImage:image];
                UIColor *borderColor;
                if ([track objectForKey:@"dedicationName"] == nil) {
                    [userLabel setText:[NSString stringWithFormat:@"Requested by %@", [user objectForKey:@"username"]]];
                    borderColor = [UIColor blackColor];
                } else {
                    [userLabel setText:[NSString stringWithFormat:@"Dedicated by %@ to %@", [user objectForKey:@"username"], [track objectForKey:@"dedicationName"]]];
                    borderColor = [UIColor redColor];
                }
                
                [userView setHidden:NO];
                [userImage setHidden:NO];
                [userLabel setHidden:NO];
                
                CGSize maximumSize = CGSizeMake(264, 32);                
                UIFont *userLabelFont = [UIFont fontWithName:@"Trebuchet MS" size:14];                
                CGSize userLabelStringSize = [userLabel.text sizeWithFont:userLabelFont 
                                               constrainedToSize:maximumSize 
                                                   lineBreakMode:userLabel.lineBreakMode];                
                CGRect userLabelFrame = CGRectMake(48, 8, 264, userLabelStringSize.height);
                [userLabel setFrame:userLabelFrame];

                // Round the corners
                CALayer *l = [userImage layer];
                [l setMasksToBounds:YES];
                [l setCornerRadius:6.0];
                
                // Add border
                [l setBorderWidth:1.0];
                [l setBorderColor:[borderColor CGColor]];        

            });
            
        });
        
    }
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{    
        // big icon - see if the image exists on disk
        NSString *albumArtCachedName = [NSString stringWithFormat:@"%@-bigIcon.png", [track objectForKey:@"albumKey"]];
        NSString *albumArtCachedFullPath = [[NSHomeDirectory() stringByAppendingPathComponent:@"Documents"] 
                                            stringByAppendingPathComponent:albumArtCachedName];
        UIImage *image = nil;
        if([[NSFileManager defaultManager] fileExistsAtPath:albumArtCachedFullPath]) {
            image = [UIImage imageWithContentsOfFile:albumArtCachedFullPath];
            NSLog(@"Pulling art from cache");
        } else {
            NSLog(@"Pulling art from web");
            NSString *artUrl = [track objectForKey:@"bigIcon"];
            image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:artUrl]]];
            // save it to disk
            NSData *imageData = [NSData dataWithData:UIImagePNGRepresentation(image)];
            [imageData writeToFile:albumArtCachedFullPath atomically:YES];
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            [imageView setImage:image];   
            [spinner stopAnimating];
        });
    });

}

- (void) reset {
    [spinner startAnimating];
    [textLabel setText:nil];
    [detailTextLabel setText:nil];
    [imageView setImage:nil];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)dealloc
{
    [super dealloc];
}

@end
