//
//  CollectionBrowser.m
//  rrrrradioMobile
//
//  Created by Andy Soell on 5/22/11.
//  Copyright 2011 The Institute for Justice. All rights reserved.
//

#import "CollectionBrowser.h"
#import "DataInterface.h"
#import <YAJLiOS/YAJL.h>

@implementation CollectionBrowser
@synthesize dataSource;
@synthesize indexChars;
@synthesize indexSize;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

/*
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [dataSource count];
}
 */

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if ([self.title isEqualToString:@"Artists"]) {
        return [indexChars length];
    } else {
        return 1;
    }
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    if ([self.title isEqualToString:@"Artists"]) {    
        NSMutableArray *indices = [[NSMutableArray alloc] init];
        for (int i=0;i<[indexChars length];i++) {
            [indices insertObject:[indexChars substringWithRange:NSMakeRange(i, 1)] atIndex:[indices count]];
        }
        
        [indices autorelease];
        return indices;
    } else {
        return [NSArray arrayWithObject:[NSString stringWithString:@""]];
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if ([self.title isEqualToString:@"Artists"]) {    
        return [[indexSize objectAtIndex:section] intValue];
    } else {
        return [dataSource count];
    }
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    int increment = 0;
    if ([self.title isEqualToString:@"Artists"]) {        
        for (int i=0;i<indexPath.section;i++) {
            increment+=[[indexSize objectAtIndex:i] intValue];
        }
    }

    NSDictionary *item = [dataSource objectAtIndex:indexPath.row+increment];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    
    if (cell == nil) {    
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewStylePlain reuseIdentifier:@"cell"];
        [cell autorelease];        
    }
    cell.textLabel.text =  [item objectForKey:@"name"];

    if ([[item objectForKey:@"type"] isEqualToString:@"rl"] || [[item objectForKey:@"type"] isEqualToString:@"r"]) {
        cell.accessoryView = nil;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;   
    } else if ([[item objectForKey:@"type"] isEqualToString:@"al"] || [[item objectForKey:@"type"] isEqualToString:@"a"]) {
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;        
        
        NSString *albumArtCachedName = [NSString stringWithFormat:@"%@-icon.png", [item objectForKey:@"key"]];
        NSString *albumArtCachedFullPath = [[NSHomeDirectory() stringByAppendingPathComponent:@"Documents"] 
                                            stringByAppendingPathComponent:albumArtCachedName];
        UIImage *image = nil;
        if([[NSFileManager defaultManager] fileExistsAtPath:albumArtCachedFullPath]) {
            image = [UIImage imageWithContentsOfFile:albumArtCachedFullPath];
            NSLog(@"Pulling art from cache");
        } else {
            NSLog(@"Pulling art from web");
            NSString *artUrl = [item objectForKey:@"icon"];
            image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:artUrl]]];
            // save it to disk
            NSData *imageData = [NSData dataWithData:UIImagePNGRepresentation(image)];
            [imageData writeToFile:albumArtCachedFullPath atomically:YES];
        }
        
        [cell.imageView setImage:image];
    }

    
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    int increment = 0;
    if ([self.title isEqualToString:@"Artists"]) {        
        for (int i=0;i<indexPath.section;i++) {
            increment+=[[indexSize objectAtIndex:i] intValue];
        }    
    }
     
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    
    UIActivityIndicatorView *activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    [activityView startAnimating];
    [cell setAccessoryView:activityView];
    [activityView release];    
    
    NSDictionary *item = [dataSource objectAtIndex:indexPath.row+increment];
    
    if ([[item valueForKey:@"type"] isEqualToString:@"tl"] || [[item valueForKey:@"type"] isEqualToString:@"t"]) {
        NSString *requestUrl = [NSString stringWithFormat:@"controller.php?key=%@", [item valueForKey:@"key"]];
        [[DataInterface issueCommand:requestUrl] yajl_JSON];        
        
        [cell setAccessoryView:nil];
        [self dismissModalViewControllerAnimated:YES];        
    } else {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{                        
            CollectionBrowser *collection = [[CollectionBrowser alloc] initWithNibName:@"CollectionBrowser" bundle:nil];
            collection.title = [item valueForKey:@"name"];
            
            if ([[item valueForKey:@"type"] isEqualToString:@"al"] || [[item valueForKey:@"type"] isEqualToString:@"a"]) {
                NSString *requestUrl = [NSString stringWithFormat:@"data.php?a=%@", [item valueForKey:@"key"]];
                NSArray *albumInformation = [[DataInterface issueCommand:requestUrl] yajl_JSON];
                
                collection.dataSource = albumInformation;
            } else if ([[item valueForKey:@"type"] isEqualToString:@"rl"] || [[item valueForKey:@"type"] isEqualToString:@"r"]) {
                NSString *requestUrl = [NSString stringWithFormat:@"data.php?r=%@", [item valueForKey:@"key"]];
                NSArray *albumInformation = [[DataInterface issueCommand:requestUrl] yajl_JSON];
                
                collection.dataSource = albumInformation;
            }

            [cell setAccessoryView:nil];
            [tableView deselectRowAtIndexPath:indexPath animated:YES];        
            
            //Push the new table view on the stack
            [self.navigationController pushViewController:collection animated:YES];
            
            [collection release];    
        });
    }
}

- (void) close {
    [self dismissModalViewControllerAnimated:YES];
}

- (void)dealloc
{
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    UIBarButtonItem *done = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(close)];
    [self.navigationItem setRightBarButtonItem:done];
    [done release];
    
    indexChars = [NSString stringWithString:@"#ABCDEFGHIJKLMNOPQRSTUVWXYZ"];
    int currentIndex = 0;
    
    indexSize = [[NSMutableArray alloc] init];
    for (NSDictionary *item in dataSource) {
        NSString *name = [item objectForKey:@"name"];
        if ([name hasPrefix:@"The "]) {
            name = [name substringFromIndex:4];
        } else if ([name hasPrefix:@"A "]) {
            name = [name substringFromIndex:2];
        }

        if (currentIndex<[indexChars length] && [[[name substringWithRange:NSMakeRange(0, 1)] uppercaseString] isEqualToString:[indexChars substringWithRange:NSMakeRange(currentIndex+1, 1)]]) {
            currentIndex++;            
            if ([indexSize count]>currentIndex) {
                //increment
                [indexSize replaceObjectAtIndex:currentIndex withObject:[NSNumber numberWithInt:[[indexSize objectAtIndex:currentIndex] intValue]+1]];               
            } else {
                //initialize
                [indexSize insertObject:[NSNumber numberWithInt:1] atIndex:currentIndex];
            }
        } else {
            if ([indexSize count]>currentIndex) {
                //increment
                [indexSize replaceObjectAtIndex:currentIndex withObject:[NSNumber numberWithInt:[[indexSize objectAtIndex:currentIndex] intValue]+1]];            
            } else {
                //initialize
                [indexSize insertObject:[NSNumber numberWithInt:1] atIndex:currentIndex];
            }
        }
    }
    
    
    // Do any additional setup after loading the view from its nib.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    [indexSize release];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
