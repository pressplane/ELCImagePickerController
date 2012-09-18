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

@interface ELCAlbumPickerController ()
{
    int curIdx;
}
- (void)loadAssetGroupsWithCompletionBlock:(void (^)(void))completionBlock;

@end


@implementation ELCAlbumPickerController

@synthesize parent, assetGroups, assetLibrary;

@synthesize assetTablePicker;
@synthesize alreadySelectedURLs;


#pragma mark - Init

- (id)initWithAssetLibrary:(ALAssetsLibrary *)library
{
    self = [super initWithNibName:nil bundle:[NSBundle mainBundle]];
    if (self) {
        self.assetLibrary = library;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(assetLibraryDidChange:) name:ALAssetsLibraryChangedNotification object:nil];
    }
    return self;
}


// From the docs:
// When you receive this notification, you should discard any cached information and query the assets library again.
// You should consider invalid any ALAsset, ALAssetsGroup, or ALAssetRepresentation objects you are referencing
// So, ask the parent to give us a new asset group and then reload data
- (void)assetLibraryDidChange:(NSNotification *)notification
{
    NSInteger indexOfCurrentAssetGroup = NSNotFound;
    if (self.assetTablePicker) {
        // indexOfCurrentAssetGroup = [self.assetGroups indexOfObject:self.assetTablePicker.assetGroup];
        indexOfCurrentAssetGroup = self->curIdx;
    }
    
    [self loadAssetGroupsWithCompletionBlock:^{
        if (indexOfCurrentAssetGroup != NSNotFound) {
            ALAssetsGroup *newGroup = [self.assetGroups objectAtIndex:indexOfCurrentAssetGroup];
            [newGroup setAssetsFilter:[ALAssetsFilter allPhotos]];
            if (self.assetTablePicker.isViewLoaded && self.assetTablePicker.view.window)
            {
                [self.assetTablePicker performSelectorOnMainThread:@selector(resetAssetGroup:)
                                                        withObject:newGroup
                                                     waitUntilDone:YES];
            }
            else
            {
                [self.assetTablePicker resetAssetGroup:newGroup];
            }
        }
    }];
    
    
}

- (void)loadAssetGroupsWithCompletionBlock:(void (^)(void))completionBlock
{
    //self.assetGroups = [[NSMutableArray alloc] init];
    NSMutableArray *loadingGroups = [[NSMutableArray alloc] init];
    
    if (self.assetLibrary == nil) {
        self.assetLibrary = [[ALAssetsLibrary alloc] init];
    }
    
    // int libraryGroupTypes = ALAssetsGroupLibrary | ALAssetsGroupAlbum | ALAssetsGroupEvent | ALAssetsGroupFaces | ALAssetsGroupSavedPhotos;
    // [self.assetLibrary enumerateGroupsWithTypes:libraryGroupTypes usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
    [self.assetLibrary enumerateGroupsWithTypes:ALAssetsGroupAll usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
        // nil group indicates the enumeration has finished
        if (group == nil)
        {
            [loadingGroups sortUsingFunction:compareGroupsUsingSelector context:nil];
            self.assetGroups = loadingGroups;

            // Reload albums
            if (self.isViewLoaded && self.view.window)
            {
                [self performSelectorOnMainThread:@selector(reloadTableView)
                                       withObject:nil
                                    waitUntilDone:YES];

                if (completionBlock != nil) 
                {
                    completionBlock();
                }
            }
            else
            {
                if (completionBlock != nil) 
                {
                    completionBlock();
                }

                [self reloadTableView];
            }
            
            return;
        }

        [loadingGroups addObject:group];
    } failureBlock:^(NSError *error) {
        NSString *errorMessage;
        NSString *errorTitle;
        
        // If we encounter a location services error, prompt the user to enable location services
        if ([error code] == ALAssetsLibraryAccessUserDeniedError) {
            errorMessage = [NSString stringWithFormat:@"It looks like you've disabled location services for this app. To add photos, enable \"Location Services\" for %@ in your device's \"Settings\" App.",[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleName"]];
            errorTitle = @"Oops!";
        } else if ([error code] == ALAssetsLibraryAccessGloballyDeniedError) {
            errorMessage = @"It looks like you've disabled location services on your device. To add photos, enable \"Location Services\" in your device's \"Settings\" App.";
            errorTitle = @"Oops!";
        } else {
            errorMessage = [NSString stringWithFormat:@"Album Error: %@", [error localizedDescription]];
            errorTitle = @"Error";
        }

        UIAlertView * alert = [[UIAlertView alloc] initWithTitle:errorTitle
                                                         message:errorMessage
                                                        delegate:nil
                                               cancelButtonTitle:@"Ok"
                                               otherButtonTitles:nil];
        [alert show];

        NSLog(@"A problem occured %@", [error description]);
    }];
}

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
    
    self.navigationController.navigationBar.barStyle = UIBarStyleBlackTranslucent;
    
    if (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad) {
        self.wantsFullScreenLayout = YES;
    }
    
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleBlackTranslucent;
    
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self.parent action:@selector(cancelImagePicker)];
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(finishPicking)];
	self.navigationItem.leftBarButtonItem = cancelButton;
    self.navigationItem.rightBarButtonItem = doneButton;

    [self loadAssetGroupsWithCompletionBlock:nil];
}

-(void)reloadTableView
{
	[self.tableView reloadData];
}

- (void)updateAssetsSelected:(NSArray*)selected unselected:(NSArray *)unselected
{
	[(ELCImagePickerController*)parent updateAssetsSelected:selected unselected:unselected];
    
    // Now, update alreadySelectedUrls so selection state can be preserved.
    // TODO would be much better to combine this with ELCImagePickerController's tracking of selected assets
    NSMutableSet *newAlreadySelected = [self.alreadySelectedURLs mutableCopy];
    for (NSURL *assetUrl in unselected) {
        [newAlreadySelected removeObject:assetUrl];
    }
    for (NSURL *assetUrl in selected) {
        [newAlreadySelected addObject:assetUrl];
    }
    self.alreadySelectedURLs = newAlreadySelected;
}

- (void)finishPicking
{
    [(ELCImagePickerController *)parent finishImagePicker];
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return (assetGroups == nil) ? 0 : [assetGroups count];
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
    }
    
    // Get count
    ALAssetsGroup *g = (ALAssetsGroup*)[assetGroups objectAtIndex:indexPath.row];
    [g setAssetsFilter:[ALAssetsFilter allPhotos]];
    NSInteger gCount = [g numberOfAssets];
    
    cell.textLabel.text = [NSString stringWithFormat:@"%@",[g valueForProperty:ALAssetsGroupPropertyName]];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"(%d)",gCount];
    cell.detailTextLabel.textColor = [UIColor grayColor];
    // [cell.imageView setImage:[UIImage imageWithCGImage:[(ALAssetsGroup*)[assetGroups objectAtIndex:indexPath.row] posterImage]]];
    [cell.imageView setImage:[UIImage imageWithCGImage:[g posterImage]]];
	[cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
	
    return cell;
}

#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    ALAssetsGroup *newGroup;
    if (assetGroups != nil && [assetGroups count] > indexPath.row)
    {
        self->curIdx = indexPath.row;
        newGroup = [assetGroups objectAtIndex:self->curIdx];
    }
    else
    {
        return;
    }

    ELCAssetTablePicker *tempAssetTablePicker = [[ELCAssetTablePicker alloc] initWithNibName:@"ELCAssetTablePicker" bundle:[NSBundle mainBundle]];
	self.assetTablePicker = tempAssetTablePicker;
	assetTablePicker.parent = self;

    // Move me
    assetTablePicker.assetGroup = newGroup;
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
    [[NSNotificationCenter defaultCenter] removeObserver:self name:ALAssetsLibraryChangedNotification object:nil];
    
    self.assetTablePicker.assetGroup = nil;
    
    
}

@end

