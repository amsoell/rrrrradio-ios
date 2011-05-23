//
//  NowPlayingCell.m
//  rrrrradioMobile
//
//  Created by Andy Soell on 5/15/11.
//  Copyright 2011 The Institute for Justice. All rights reserved.
//

#import "NowPlayingCell.h"


@implementation NowPlayingCell
@synthesize textLabel, detailTextLabel, imageView, spinner;
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
            [self.imageView setImage:image];   
            [spinner stopAnimating];
        });
    });

}

- (void) reset {
    [spinner startAnimating];
    [self.textLabel setText:nil];
    [self.detailTextLabel setText:nil];
    [self.imageView setImage:nil];
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
