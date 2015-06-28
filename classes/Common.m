//
//  Common.m
//  rrrrradio
//
//  Created by Andy Soell on 6/25/12.
//  Copyright (c) 2012 rrrrradio. All rights reserved.
//

#import "Common.h"
#include <sys/xattr.h>

@implementation Common

+ (UIImage*)getAsset:(NSString*)assetName fromUrl:(NSURL *)url {
    
    UIImage* image;

    assetName = [[NSHomeDirectory() stringByAppendingPathComponent:@"Library/Caches"] stringByAppendingPathComponent:assetName];
    
    if([[NSFileManager defaultManager] fileExistsAtPath:assetName]) {
        image = [UIImage imageWithContentsOfFile:assetName];
        NSLog(@"Pulling art from cache");
    } else {
        NSLog(@"Pulling art from web: %@", [url absoluteString]);
        
        [self addSkipBackupAttributeToItemAtURL:url];
        image = [UIImage imageWithData:[NSData dataWithContentsOfURL:url]];
        // save it to disk
        NSData *imageData = [NSData dataWithData:UIImagePNGRepresentation(image)];
        [imageData writeToFile:assetName atomically:YES];
    }    
    
    return image;
}

+ (BOOL)addSkipBackupAttributeToItemAtURL:(NSURL *)URL
{
    const char* filePath = [[URL path] fileSystemRepresentation];
    const char* attrName = "com.apple.MobileBackup";
        // First try and remove the extended attribute if it is present
        int result = (int)getxattr(filePath, attrName, NULL, sizeof(u_int8_t), 0, 0);
        if (result != -1) {
            // The attribute exists, we need to remove it
            int removeResult = removexattr(filePath, attrName, 0);
            if (removeResult == 0) {
                NSLog(@"Removed extended attribute on file %@", URL);
            }
        }
        
        // Set the new key
        NSError *error = nil;
        [URL setResourceValue:[NSNumber numberWithBool:YES] forKey:NSURLIsExcludedFromBackupKey error:&error];
        return error == nil;
    }

@end
