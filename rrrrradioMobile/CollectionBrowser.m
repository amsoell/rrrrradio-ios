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

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [dataSource count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *item = [dataSource objectAtIndex:indexPath.row];
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
     
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    
    UIActivityIndicatorView *activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    [activityView startAnimating];
    [cell setAccessoryView:activityView];
    [activityView release];    
    
    NSDictionary *item = [dataSource objectAtIndex:indexPath.row];
    
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
    
    // Do any additional setup after loading the view from its nib.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
