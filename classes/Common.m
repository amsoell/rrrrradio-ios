//
//  Common.m
//  rrrrradio
//
//  Created by Andy Soell on 6/25/12.
//  Copyright (c) 2012 rrrrradio. All rights reserved.
//

#import "Common.h"

@implementation Common

+ (UIImage*)getAsset:(NSString*)assetName fromUrl:(NSURL *)url {
    
    UIImage* image;
    assetName = [[NSHomeDirectory() stringByAppendingPathComponent:@"Library/Caches"] stringByAppendingPathComponent:assetName];
    
    if([[NSFileManager defaultManager] fileExistsAtPath:assetName]) {
        image = [UIImage imageWithContentsOfFile:assetName];
        NSLog(@"Pulling art from cache");
    } else {
        NSLog(@"Pulling art from web");
        [url setResourceValue:[NSNumber numberWithBool:YES] forKey:NSURLIsExcludedFromBackupKey error:nil];
        image = [UIImage imageWithData:[NSData dataWithContentsOfURL:url]];
        // save it to disk
        NSData *imageData = [NSData dataWithData:UIImagePNGRepresentation(image)];
        [imageData writeToFile:assetName atomically:YES];
    }    
    
    return image;
}

@end
