//
//  CollectionBrowser.h
//  rrrrradioMobile
//
//  Created by Andy Soell on 5/22/11.
//  Copyright 2011 The Institute for Justice. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface CollectionBrowser : UIViewController <UITableViewDataSource,UITableViewDelegate> {
    NSArray *dataSource;
}

- (void) close;

@property (nonatomic, retain) NSArray *dataSource;
@end
