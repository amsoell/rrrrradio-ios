//
//  CollectionBrowser.h
//  rrrrradio
//
//  Created by Andy Soell on 5/22/11.
//  Copyright 2011 The Institute for Justice. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "rrrrradioViewController.h"


@interface CollectionBrowser : UIViewController <UITableViewDataSource,UITableViewDelegate> {
    NSArray *dataSource;
    NSString *indexChars;
    NSMutableArray *indexSize;
    rrrrradioViewController *owner;
}

- (void) close;

@property (nonatomic, retain) NSArray *dataSource;
@property (nonatomic, retain) NSString *indexChars;
@property (nonatomic, retain) NSMutableArray *indexSize;
@property (nonatomic, retain) rrrrradioViewController *owner;

@end
