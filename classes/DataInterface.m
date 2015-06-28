//
//  DataInterface.m
//  rrrrradio
//
//  Created by Andy Soell on 5/21/11.
//  Copyright 2011 The Institute for Justice. All rights reserved.
//

#import "DataInterface.h"
#import "Settings.h"

@implementation DataInterface

// Basic wrapper to get the contents of a URL
+ (NSData*)issueCommand:(NSString*)command {
    NSString* userKey = [[Settings settings] userKey];  
    NSString* build = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
    NSString* version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    NSString* accessToken = [[Settings settings] accessToken];
    NSError* lookupError = nil;
    NSURL *reqURL = [[NSURL alloc] initWithString:[[NSString stringWithFormat:@"http://rrrrradio.com/%@&userKey=%@&client=ios&version=%@&build=%@&%@", command, userKey, version, build, accessToken] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    NSLog(@"Data Interface Request: %@", [reqURL absoluteURL]);
    NSString *reqData = [[NSString alloc] initWithContentsOfURL:reqURL encoding:NSUTF8StringEncoding error:&lookupError];
    
    [reqURL release];
    [reqData autorelease];
    return [reqData dataUsingEncoding:NSUTF8StringEncoding];
}

@end
