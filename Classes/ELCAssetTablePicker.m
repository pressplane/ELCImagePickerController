//
//  AssetTablePicker.m
//
//  Created by Matt Tuzzolo on 2/15/11.
//  Copyright 2011 ELC Technologies. All rights reserved.
//

#import "ELCAssetTablePicker.h"
#import "ELCAssetCell.h"
#import "ELCAsset.h"
#import "ELCAlbumPickerController.h"
#import "SVProgressHUD.h"

#define SYSTEM_VERSION_LESS_THAN(v) ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)
#define DEFAULT_MAX_BATCH_SIZE 20

@interface ELCAssetTablePicker() {
    BOOL controllerIsDisappearing;
    int _previousSelectionCount;
}

- (void)scrollTableViewToBottom;

- (NSInteger)assetsPerRow;

@end

@implementation ELCAssetTablePicker

@synthesize parent;
@synthesize selectedAssetsLabel;
@synthesize assetGroup, elcAssets;
@synthesize maxBatchSize;

// called by ELCAlbumPickerController if it gets a library change notification
- (void)resetAssetGroup:(ALAssetsGroup *)newAssetsGroup
{
    self.assetGroup = newAssetsGroup;
    [self.tableView reloadData];
    [self performSelectorInBackground:@selector(preparePhotos) withObject:nil];
}


-(void)viewDidLoad
{        
	[self.tableView setSeparatorColor:[UIColor clearColor]];
	[self.tableView setAllowsSelection:NO];

    NSMutableArray *tempArray = [[NSMutableArray alloc] init];
    self.elcAssets = tempArray;
	
	UIBarButtonItem *doneButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneAction:)];
	[self.navigationItem setRightBarButtonItem:doneButtonItem];
    
	[self.navigationItem setTitle:@"Loading..."];
    
    self.navigationController.navigationBar.barStyle = UIBarStyleBlackTranslucent;

    if (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad) {
        self.wantsFullScreenLayout = YES;
    } else {
        [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleBlackTranslucent;
    }
    _previousSelectionCount = 0;
}

- (void)viewWillAppear:(BOOL)animated
{
    controllerIsDisappearing = NO;
    [self.tableView reloadData];
    [self performSelectorInBackground:@selector(preparePhotos) withObject:nil];
}

-(void)viewWillDisappear:(BOOL)animated {
    // this is used to tell preparePhotos to stop if it's still going
    controllerIsDisappearing = YES;
    
    // since ELCAssetTablePicker never pushes another view controller onto its navigation controller,
    // disappearing always means being popped
    // [self updateSelected];
    
    self.assetGroup = nil;
    self.parent = nil;
    
    [super viewWillDisappear:animated];
}

- (void)didReceiveMemoryWarning
{
    // thumbnails are cached for better scrolling performance, but this uses memory
    for (ELCAsset *asset in self.elcAssets) {
        asset.thumbnail = nil;
    }
}

-(void)preparePhotos
{
    @autoreleasepool {
        @synchronized(self.elcAssets) {
            [self.elcAssets removeAllObjects];
            
            NSInteger numberOfAssets = self.assetGroup.numberOfAssets;
            NSInteger assetsPerRow = [self assetsPerRow];
            NSUInteger numberToLoad;
            
            if (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad) {
                numberToLoad = 10 * assetsPerRow;
            } else {
                numberToLoad = 6 * assetsPerRow;
            }
            
            [self.assetGroup enumerateAssetsWithOptions:NSEnumerationReverse usingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
                // The controller is going away. Quit attempting to load more assets...
                if (controllerIsDisappearing) {
                    *stop = YES;
                    return;
                }
                
                if(result == nil) {
                    // finished enumerating
                    // do some cleanup if the asset group didn't have enough items to fill a screen
                    // TODO some minor duplication from below... could extract
                    if (self.elcAssets.count <= numberToLoad) {
                        [self.tableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:YES];
                        [self.navigationItem performSelectorOnMainThread:@selector(setTitle:) withObject:@"Select Photos" waitUntilDone:YES];
                    }
                    
                    return;
                }
                
                ELCAsset *elcAsset = [[ELCAsset alloc] initWithAsset:result];
                [elcAsset setDelegate:self];
                    
                // Mark all the selected assets
                if ([((ELCAlbumPickerController *)self.parent).alreadySelectedURLs containsObject:elcAsset.url]) {
                    elcAsset.selected = YES;
                }
                
                [self.elcAssets addObject:elcAsset];
                
                // Get tableview into sync with the assets we've now loaded...
                NSInteger currentAssetCount = self.elcAssets.count;
                if (currentAssetCount <= numberToLoad) {
                    // if we just finished doing the first row, scroll to it
                    if (currentAssetCount == assetsPerRow) {
                        [self performSelectorOnMainThread:@selector(scrollTableViewToBottom) withObject:nil waitUntilDone:YES];
                    }
                    
                    if (currentAssetCount == numberToLoad) {
                        // reload the tableView once, when done with the current page
                        // could always reload row by row, but on the first screenful, that looks pretty terrible
                        [self.tableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:YES];
                        [self.navigationItem performSelectorOnMainThread:@selector(setTitle:) withObject:@"Select Photos" waitUntilDone:YES];
                    }
                } else {
                    // After the first screenful has loaded, notify that we finished a row.
                    // This gives rows that got scrolled into view before their assets loaded a chance to update
                    if ((numberOfAssets-currentAssetCount) % assetsPerRow == 0) {
                        NSInteger currentRow = ceilf((float)(numberOfAssets-currentAssetCount) / assetsPerRow) + 1 /* it's the next row that is fully loaded */ + 1 /* header row */;
                        [self performSelectorOnMainThread:@selector(finishedLoadingRow:) withObject:[NSIndexPath indexPathForRow:currentRow inSection:0]  waitUntilDone:YES];
                    }
                }
            }];
        }
        
        self.navigationItem.title = @"Select Photos";
    }
}

- (void)finishedLoadingRow:(NSIndexPath *)row
{
    if ([[self.tableView indexPathsForVisibleRows] containsObject:row]) {
        [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:row] withRowAnimation:UITableViewRowAnimationFade];
    }
}

- (void)assetSelected:(ELCAsset*)asset
{
    if (asset.selected)
    {
        [parent select:asset.url];
    }
    else
    {
        [parent deselect:asset.url];
    }

    int totalSelectedAssets = [parent totalSelected];
    
    if (totalSelectedAssets == 0) {
        self.navigationItem.title = @"Select Photos";
    } else if (totalSelectedAssets == 1) {
        self.navigationItem.title = @"1 Photo";
    } else {
        self.navigationItem.title = [NSString stringWithFormat:@"%i Photos", totalSelectedAssets];
    }
    
    if (totalSelectedAssets > self.maxBatchSize) {
        if (totalSelectedAssets > _previousSelectionCount)
        {
            [SVProgressHUD show];
            [SVProgressHUD dismissWithError:[NSString stringWithFormat:@"Maximum upload size reached. %d per batch please", self.maxBatchSize]];
        }
        
        self.navigationItem.rightBarButtonItem.enabled = NO;
        
        if (SYSTEM_VERSION_LESS_THAN(@"5.0")) {
        
            if (self.navigationItem.titleView == nil) {
                
                UILabel *titleLabel = [[UILabel alloc] init];
                
                CGRect frame = CGRectMake(0, 0, [self.navigationItem.title sizeWithFont:[UIFont boldSystemFontOfSize:20.0]].width, 20.0);
                titleLabel.frame = frame;
                
                titleLabel.font = [UIFont boldSystemFontOfSize: 20.0f];
                titleLabel.textAlignment = ([self.title length] < 10 ? UITextAlignmentCenter : UITextAlignmentLeft);
                
                titleLabel.textColor = [UIColor colorWithWhite:1.0 alpha:0.7];
                titleLabel.backgroundColor = [UIColor clearColor];
                
                titleLabel.shadowColor = [UIColor colorWithWhite:0.0 alpha:0.35];
                titleLabel.shadowOffset = CGSizeMake(0.0, -1.0);
                
                titleLabel.text = self.navigationItem.title;
                
                [self.navigationItem setTitleView:titleLabel];
                
                self.navigationItem.rightBarButtonItem.enabled = NO;
            }
            
        } else {
            
            UIColor *textColor = [UIColor colorWithWhite:1.0 alpha:0.7];
            UIColor *shadowColor = [UIColor colorWithWhite:0.0 alpha:0.35];
            
            NSDictionary *titleTextAttributes = [NSDictionary dictionaryWithObjectsAndKeys:textColor, UITextAttributeTextColor, shadowColor, UITextAttributeTextShadowColor, nil];
            
            [self.navigationController.navigationBar setTitleTextAttributes:titleTextAttributes];
        }
        
    } else {
        
        self.navigationItem.rightBarButtonItem.enabled = YES;
            
        if (SYSTEM_VERSION_LESS_THAN(@"5.0")) {
            
            if (self.navigationItem.titleView) {
                [self.navigationItem setTitleView:nil];
            }
            
        } else {
            
            UIColor *textColor = [UIColor colorWithWhite:1.0 alpha:1.0];
            UIColor *shadowColor = [UIColor colorWithWhite:0.0 alpha:1.0];
            
            NSDictionary *titleTextAttributes = [NSDictionary dictionaryWithObjectsAndKeys:textColor, UITextAttributeTextColor, shadowColor, UITextAttributeTextShadowColor, nil];
            
            [self.navigationController.navigationBar setTitleTextAttributes:titleTextAttributes];
        }
    }
    _previousSelectionCount = totalSelectedAssets;
}

- (void)scrollTableViewToBottom
{
    
    int lastRowIndex = [self tableView:nil numberOfRowsInSection:0] - 1;
    if (lastRowIndex >= 0) {
        
        NSIndexPath* lastRowIndexPath = [NSIndexPath indexPathForRow:lastRowIndex inSection:0];
        [self.tableView scrollToRowAtIndexPath:lastRowIndexPath atScrollPosition:UITableViewScrollPositionBottom animated:NO];   
    }
}


- (void)doneAction:(id)sender
{
    [(ELCAlbumPickerController*)self.parent finishPicking];
}

- (NSInteger)assetsPerRow
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        return 6;
    } else {
        return 4;
    }
}

#pragma mark UITableViewDataSource Delegate Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    
    // Add two rows for padding at the top and bottom of each section
    return ceil(((CGFloat)[self.assetGroup numberOfAssets]) / ((CGFloat)[self assetsPerRow])) + 2;
}


- (NSArray*)assetsForIndexPath:(NSIndexPath*)_indexPath
{
    
    int index = (self.assetGroup.numberOfAssets-1)-(_indexPath.row*[self assetsPerRow]);
    
    int minIndex;
    if (index < ([self assetsPerRow]-1)) {
        minIndex = 0;
    } else {
        minIndex = index-([self assetsPerRow]-1);
    }
    
    NSMutableArray *assetArray = [NSMutableArray array];
    // If there's four images in the row
    
    if (index < self.elcAssets.count) {
        for (NSInteger i=(index - minIndex); i > -1; i--) {
            
//            NSLog(@"building asset at index %d", minIndex+i);
            
            [assetArray addObject:[self.elcAssets objectAtIndex:minIndex+i]];
        }
		return assetArray;
    }
    
	return nil;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if ([indexPath row] == 0)
    {
        static NSString *whitespaceCellIdentifier = @"WhitespaceTableViewCell";
        UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:whitespaceCellIdentifier];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:whitespaceCellIdentifier];
        }
        return cell;
        
    } else if ([indexPath row] == [self tableView:tableView numberOfRowsInSection:[indexPath section]]-1) {
        
        static NSString *whitespaceCellIdentifier = @"ELCCountTableViewCell";
        UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:whitespaceCellIdentifier];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:whitespaceCellIdentifier];
            cell.textLabel.textAlignment = UITextAlignmentCenter;
            cell.textLabel.textColor = [UIColor grayColor];
            cell.textLabel.font = [UIFont systemFontOfSize:19];
        }
        
        cell.textLabel.text = [NSString stringWithFormat:@"%i Photos", self.assetGroup.numberOfAssets];
        
        return cell;
        
    } else {
    
        static NSString *CellIdentifier = @"Cell";
            
        ELCAssetCell *cell = (ELCAssetCell*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];

        NSIndexPath *updatedIndexPath = [NSIndexPath indexPathForRow:indexPath.row-1 inSection:indexPath.section];
        
        if (cell == nil) 
        {		        
            cell = [[ELCAssetCell alloc] initWithAssets:[self assetsForIndexPath:updatedIndexPath] assetsPerRow:[self assetsPerRow] reuseIdentifier:CellIdentifier];
        }	
        else 
        {		
            [cell setAssets:[self assetsForIndexPath:updatedIndexPath]];
        }
        
        return cell;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (([indexPath row] == 0)) {
        
        return [ELCAssetCell cellPadding]/2;
        
    } else if (indexPath.row == [self tableView:tableView numberOfRowsInSection:indexPath.section]-1) {
        
        return 50;
        
    } else {
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            return 89;
        } else {
            return 79;            
        }
    }
}

@end
