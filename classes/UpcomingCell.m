//
//  UpcomingCell.m
//  rrrrradio
//
//  Created by Andy Soell on 5/18/11.
//  Copyright 2011 The Institute for Justice. All rights reserved.
//

#import "UpcomingCell.h"
#import "Common.h"
#import <QuartzCore/QuartzCore.h>

@implementation UpcomingCell
@synthesize textLabel, detailTextLabel, imageView, userView, spinner;
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
    [self.textLabel setText:[track objectForKey:@"name"]];
    [self.detailTextLabel setText:[track objectForKey:@"artist"]];   
    
    // add user info if available
    if (![[track objectForKey:@"user"] isKindOfClass:[NSNull class]]) {
        NSDictionary *user = [track objectForKey:@"user"];

        textLabel.frame = CGRectMake(50, 1, 226, 21);
        detailTextLabel.frame = CGRectMake(50, 20, 226, 21);
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{    
            // user Icon
            UIImage *image = [Common getAsset:[NSString stringWithFormat:@"%@.png", [user objectForKey:@"key"]] fromUrl:[NSURL URLWithString:[user objectForKey:@"icon"]]];
            
            UIColor *borderColor;
            if ([track objectForKey:@"dedicationName"] == nil) {
                borderColor = [UIColor blackColor];
            } else {
                borderColor = [UIColor redColor];
                NSLog(@"dedicated to: %@", [track objectForKey:@"dedicationName"]);
                NSLog(@"detail: %@", track);
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.userView setImage:image];
                
                // Round the corners
                CALayer * l = [self.userView layer];
                [l setMasksToBounds:YES];
                [l setCornerRadius:4.0];
                
                // Add border
                [l setBorderWidth:1.0];
                [l setBorderColor:[borderColor CGColor]];        
            });
            
        });
        
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{    
        // little icon - see if the image exists on disk
        UIImage *image = [Common getAsset:[NSString stringWithFormat:@"%@-icon.png", [track objectForKey:@"albumKey"]] fromUrl:[NSURL URLWithString:[track objectForKey:@"icon"]]];
                
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.imageView setImage:image];
            [spinner stopAnimating];
        });
        
        // Get the big one in advance
        [Common getAsset:[NSString stringWithFormat:@"%@-bigIcon.png", [track objectForKey:@"albumKey"]] fromUrl:[NSURL URLWithString:[track objectForKey:@"bigIcon"]]];
    });
}

- (void) reset {
    [spinner startAnimating];
    [self.textLabel setText:nil];
    [self.detailTextLabel setText:nil];
    [self.imageView setImage:nil];
    [self.userView setImage:nil];
    textLabel.frame = CGRectMake(50, 1, 270, 21);
    detailTextLabel.frame = CGRectMake(50, 20, 270, 21);
    
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
