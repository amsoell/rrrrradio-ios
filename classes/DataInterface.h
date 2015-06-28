//
//  DataInterface.h
//  rrrrradio
//
//  Created by Andy Soell on 5/21/11.
//  Copyright 2011 The Institute for Justice. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface DataInterface : NSObject {
}

+ (NSData*)issueCommand:(NSString*)command;

@end
