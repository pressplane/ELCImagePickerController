//
//  AlbumPickerController.m
//
//  Created by Matt Tuzzolo on 2/15/11.
//  Copyright 2011 ELC Technologies. All rights reserved.
//

#import <AssetsLibrary/AssetsLibrary.h>
#import "ELCAlbumPickerController.h"
#import "ELCImagePickerController.h"
#import "ELCAssetTablePicker.h"

@implementation ELCAlbumPickerController

@synthesize parent, assetGroups;

@synthesize assetTablePicker;


#pragma mark -
#pragma mark View lifecycle

static int compareGroupsUsingSelector(id p1, id p2, void *context)
{
    id value1 = [p1 valueForProperty:ALAssetsGroupPropertyType];
    id value2 = [p2 valueForProperty:ALAssetsGroupPropertyType];
    
    return [value2 compare:value1];
}

- (void)viewDidLoad {
    [super viewDidLoad];
	
	[self.navigationItem setTitle:@"Albums"];
    
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleBlackTranslucent;
    self.navigationController.navigationBar.barStyle = UIBarStyleBlackTranslucent;
    
    if (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad) {
        self.wantsFullScreenLayout = YES;
    } 
    
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self.parent action:@selector(cancelImagePicker)];
	[self.navigationItem setRightBarButtonItem:cancelButton];
	[cancelButton release];

    NSMutableArray *tempArray = [[NSMutableArray alloc] init];
	self.assetGroups = tempArray;
    [tempArray release];

    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];        
    [library enumerateGroupsWithTypes:ALAssetsGroupAll 
                           usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
                               if (group == nil) 
                               {
                                   return;
                               }
                               
                               [self.assetGroups addObject:group];
                               [self.assetGroups sortUsingFunction:compareGroupsUsingSelector context:nil];
                               
                               // Keep this line!  w/o it the asset count is broken for some reason.  Makes no sense
                               NSLog(@"count: %d for %@ (%@)", [group numberOfAssets], [group valueForProperty:ALAssetsGroupPropertyName] ,[group valueForProperty:ALAssetsGroupPropertyType]);
                               
                               // Reload albums
                               [self performSelectorOnMainThread:@selector(reloadTableView) 
                                                      withObject:nil 
                                                   waitUntilDone:YES];
                           }
                         failureBlock:^(NSError *error) {
                             
                             NSString *errorMessage;
                             NSString *errorTitle;
                             
                             // If we encounter a location services error, prompt the user to enable location services
                             if ([error code] == ALAssetsLibraryAccessUserDeniedError) {
                                 errorMessage = [NSString stringWithFormat:@"It looks like you've disabled location services for this app. To add photos, enable \"Location Services\" for %@ in your device's \"Settings\" App.",[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleName"]];
                                 errorTitle = [NSString stringWithString:@"Oops!"];
                             } else if ([error code] == ALAssetsLibraryAccessGloballyDeniedError) {
                                 errorMessage = [NSString stringWithString:@"It looks like you've disabled location services on your device. To add photos, enable \"Location Services\" in your device's \"Settings\" App."]; 
                                 errorTitle = [NSString stringWithString:@"Oops!"];
                             } else {
                                 errorMessage = [NSString stringWithFormat:@"Album Error: %@", [error localizedDescription]];
                                 errorTitle = [NSString stringWithString:@"Error"];
                             }
                             
                             UIAlertView * alert = [[UIAlertView alloc] initWithTitle:errorTitle
                                                                              message:errorMessage
                                                                             delegate:nil 
                                                                    cancelButtonTitle:@"Ok" 
                                                                    otherButtonTitles:nil];
                             [alert show];
                             [alert release];
                             
                             NSLog(@"A problem occured %@", [error description]);                                   
                         }];
}

-(void)reloadTableView {
	
	[self.tableView reloadData];
}

-(void)selectedAssets:(NSArray*)_assets {
	
	[(ELCImagePickerController*)parent selectedAssets:_assets];
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return [assetGroups count];
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier] autorelease];
    }
    
    // Get count
    ALAssetsGroup *g = (ALAssetsGroup*)[assetGroups objectAtIndex:indexPath.row];
    [g setAssetsFilter:[ALAssetsFilter allPhotos]];
    NSInteger gCount = [g numberOfAssets];
    
    cell.textLabel.text = [NSString stringWithFormat:@"%@",[g valueForProperty:ALAssetsGroupPropertyName]];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"(%d)",gCount];
    cell.detailTextLabel.textColor = [UIColor grayColor];
    [cell.imageView setImage:[UIImage imageWithCGImage:[(ALAssetsGroup*)[assetGroups objectAtIndex:indexPath.row] posterImage]]];
	[cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
	
    return cell;
}

#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
    ELCAssetTablePicker *tempAssetTablePicker = [[ELCAssetTablePicker alloc] initWithNibName:@"ELCAssetTablePicker" bundle:[NSBundle mainBundle]];
    
	self.assetTablePicker = tempAssetTablePicker;
    [tempAssetTablePicker release];
    
	assetTablePicker.parent = self;

    // Move me    
    assetTablePicker.assetGroup = [assetGroups objectAtIndex:indexPath.row];
    [assetTablePicker.assetGroup setAssetsFilter:[ALAssetsFilter allPhotos]];
    
	[self.navigationController pushViewController:assetTablePicker animated:YES];
//	[picker release];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	return 57;
}

#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    // Relinquish ownership any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    // Relinquish ownership of anything that can be recreated in viewDidLoad or on demand.
    // For example: self.myOutlet = nil;
}


- (void)dealloc 
{	
//	[assetGroups release];
    
    
    self.assetTablePicker.assetGroup = nil;
    [assetTablePicker release];
    
    self.assetGroups = nil;
    
    [super dealloc];
}

@end

