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
+ (NSString*)issueCommand:(NSString*)command {
    NSString* userKey = [[Settings settings] userKey];  
    NSString*	version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];    
    NSURL *reqURL = [[NSURL alloc] initWithString:[[NSString stringWithFormat:@"http://rrrrradio.com/%@&userKey=%@&client=ios&version=%@&%@", command, userKey, version, [[Settings settings] accessToken]] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    NSLog(@"Data Interface Request: %@", [reqURL absoluteURL]);
    NSString *reqData = [[NSString alloc] initWithContentsOfURL:reqURL];   
    
    [reqURL release];
    [reqData autorelease];
    return reqData;
}

@end
