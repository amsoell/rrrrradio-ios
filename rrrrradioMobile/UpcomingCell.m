//
//  UpcomingCell.m
//  rrrrradioMobile
//
//  Created by Andy Soell on 5/18/11.
//  Copyright 2011 The Institute for Justice. All rights reserved.
//

#import "UpcomingCell.h"
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
    NSLog(@"User data: %@", [track objectForKey:@"user"]);
    if (![[track objectForKey:@"user"] isKindOfClass:[NSNull class]]) {
        NSDictionary *user = [track objectForKey:@"user"];

        textLabel.frame = CGRectMake(50, 1, 226, 21);
        detailTextLabel.frame = CGRectMake(50, 20, 226, 21);
        
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
                [self.userView setImage:image];
                
                // Round the corners
                CALayer * l = [self.userView layer];
                [l setMasksToBounds:YES];
                [l setCornerRadius:4.0];
                
                // Add border
                [l setBorderWidth:1.0];
                [l setBorderColor:[[UIColor blackColor] CGColor]];        
            });
            
        });
        
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{    
        // little icon - see if the image exists on disk
        NSString *albumArtCachedName = [NSString stringWithFormat:@"%@-icon.png", [track objectForKey:@"key"]];
        NSString *albumArtCachedFullPath = [[NSHomeDirectory() stringByAppendingPathComponent:@"Documents"] 
                                            stringByAppendingPathComponent:albumArtCachedName];
        UIImage *image = nil;
        if([[NSFileManager defaultManager] fileExistsAtPath:albumArtCachedFullPath]) {
            image = [UIImage imageWithContentsOfFile:albumArtCachedFullPath];
        } else {
            NSString *artUrl = [track objectForKey:@"icon"];
            image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:artUrl]]];
            // save it to disk
            NSData *imageData = [NSData dataWithData:UIImagePNGRepresentation(image)];
            [imageData writeToFile:albumArtCachedFullPath atomically:YES];
        }
                
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.imageView setImage:image];
            [spinner stopAnimating];
        });
        
        // Get the big one in advance
        albumArtCachedName = [NSString stringWithFormat:@"%@-bigIcon.png", [track objectForKey:@"key"]];
        albumArtCachedFullPath = [[NSHomeDirectory() stringByAppendingPathComponent:@"Documents"] 
                                            stringByAppendingPathComponent:albumArtCachedName];
        image = nil;
        if(![[NSFileManager defaultManager] fileExistsAtPath:albumArtCachedFullPath]) {
            NSString *artUrl = [track objectForKey:@"bigIcon"];
            image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:artUrl]]];
            // save it to disk
            NSData *imageData = [NSData dataWithData:UIImagePNGRepresentation(image)];
            [imageData writeToFile:albumArtCachedFullPath atomically:YES];
        }
        
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
