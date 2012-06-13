//
//  CollectionBrowser.m
//  rrrrradio
//
//  Created by Andy Soell on 5/22/11.
//  Copyright 2011 The Institute for Justice. All rights reserved.
//

#import "CollectionBrowser.h"
#import "DataInterface.h"
#import <YAJLiOS/YAJL.h>
#import <dispatch/dispatch.h>

@implementation CollectionBrowser
@synthesize dataSource;
@synthesize indexChars;
@synthesize indexSize;
@synthesize owner;

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
        if([[NSFileManager defaultManager] fileExistsAtPath:albumArtCachedFullPath]) {
            UIImage *image = [UIImage imageWithContentsOfFile:albumArtCachedFullPath];
            NSLog(@"Pulling art from cache");
            [cell.imageView setImage:image];            
        } else {
            NSLog(@"Pulling art from web");
            NSString *artUrl = [item objectForKey:@"icon"];
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{                                            
                UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:artUrl]]];
                // save it to disk
                NSData *imageData = [NSData dataWithData:UIImagePNGRepresentation(image)];
                [imageData writeToFile:albumArtCachedFullPath atomically:YES];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [cell.imageView setImage:image];            
                });
            });
        }
    } else if ([[item objectForKey:@"type"] isEqualToString:@"tl"] || [[item objectForKey:@"type"] isEqualToString:@"t"]) {
            if ([[item objectForKey:@"randomable"] intValue] > 0) {
                NSLog(@"randomable");
                cell.textLabel.font = [UIFont boldSystemFontOfSize:20];
            } else {
                NSLog(@"notrandomable");
                cell.textLabel.font = [UIFont systemFontOfSize:20];
            }
        
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
    NSLog(@"Item::%@", item);
    
    if ([[item valueForKey:@"type"] isEqualToString:@"tl"] || [[item valueForKey:@"type"] isEqualToString:@"t"]) {
        // Track selected: Queue it up
        NSString *requestUrl = [NSString stringWithFormat:@"controller.php?r=queue&key=%@", [item valueForKey:@"key"]];
        [[DataInterface issueCommand:requestUrl] yajl_JSON]; 
        [owner updateQueue];
        
        [cell setAccessoryView:nil];
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {            
            [self.navigationController popToRootViewControllerAnimated:YES];
        } else {
            [self dismissModalViewControllerAnimated:YES];
        }
    } else {
        // Artist or album selected
        CollectionBrowser *collection = [[CollectionBrowser alloc] initWithNibName:@"CollectionBrowser" bundle:nil];
        [collection setOwner:self.owner];
        [collection setTitle:[item valueForKey:@"name"]];
        [collection.navigationItem setRightBarButtonItem:self.navigationItem.rightBarButtonItem];        
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{                                
            if ([[item valueForKey:@"type"] isEqualToString:@"al"] || [[item valueForKey:@"type"] isEqualToString:@"a"]) {
                // Album selected -- this data already exists
                
                collection.dataSource = [item objectForKey:@"tracks"];
            } else if ([[item valueForKey:@"type"] isEqualToString:@"rl"] || [[item valueForKey:@"type"] isEqualToString:@"r"]) {
                // Artist selected
                NSString *requestUrl = [NSString stringWithFormat:@"data.php?r=%@", [item valueForKey:@"key"]];
                NSArray *albumInformation = [[DataInterface issueCommand:requestUrl] yajl_JSON];
                
                collection.dataSource = albumInformation;
            } else if ([[item valueForKey:@"type"] isEqualToString:@"nr"]) {
                // New album range selected
                NSString *requestUrl = [NSString stringWithFormat:@"data.php?n=%@&extra=prependartist", [item valueForKey:@"key"]];
                NSArray *albumInformation = [[DataInterface issueCommand:requestUrl] yajl_JSON];
                
                collection.dataSource = albumInformation;
            }

            dispatch_async(dispatch_get_main_queue(), ^{
                
                [cell setAccessoryView:nil];
                [tableView deselectRowAtIndexPath:indexPath animated:YES];        
                
                //Push the new table view on the stack
                [self.navigationController pushViewController:collection animated:YES];
                
                [collection release];    
            });
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
    
    indexChars = [NSString stringWithString:@"#ABCDEFGHIJKLMNOPQRSTUVWXYZ"];
    int currentIndex = 0;
    
    if ([self.title isEqualToString:@"Artists"]) {
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
    };
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [self.navigationController.navigationBar setTintColor:[UIColor colorWithRed:185.0f/255.0f green:80.0f/255.0f blue:0.0f/255.0f alpha:1.0f]];    
    NSLog(@"rotated");
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
    //return (interfaceOrientation == UIInterfaceOrientationPortrait);
    return YES;
}

@end
