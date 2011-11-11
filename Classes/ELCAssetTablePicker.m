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

@interface ELCAssetTablePicker()

- (void)scrollTableViewToBottom;

@end

@implementation ELCAssetTablePicker

@synthesize parent;
@synthesize selectedAssetsLabel;
@synthesize assetGroup, elcAssets;

-(void)viewDidLoad {
        
	[self.tableView setSeparatorColor:[UIColor clearColor]];
	[self.tableView setAllowsSelection:NO];

    NSMutableArray *tempArray = [[NSMutableArray alloc] init];
    self.elcAssets = tempArray;
    [tempArray release];
	
	UIBarButtonItem *doneButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneAction:)];
	[self.navigationItem setRightBarButtonItem:doneButtonItem];
    [doneButtonItem release];
    
	[self.navigationItem setTitle:@"Loading..."];
    
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleBlackTranslucent;
    self.navigationController.navigationBar.barStyle = UIBarStyleBlackTranslucent;
    self.wantsFullScreenLayout = YES;
    
    [self.tableView reloadData];
    
	[self performSelectorInBackground:@selector(preparePhotos) withObject:nil];
}

-(void)viewWillDisappear:(BOOL)animated {
    self.assetGroup = nil;
    self.parent = nil;
    
    [super viewWillDisappear:animated];
}

-(void)preparePhotos {
    
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    NSUInteger numberToLoad = [self.tableView indexPathsForVisibleRows].count * 4;
    
    [self.assetGroup enumerateAssetsWithOptions:NSEnumerationReverse usingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) 
     {         
         if(result == nil) {
             return;
         }
         
         ELCAsset *elcAsset = [[ELCAsset alloc] initWithAsset:result];
         [elcAsset setParent:self];
         [self.elcAssets addObject:elcAsset];
         
         //Once we've loaded 24 then we should reload the table data because the screen is full
         if (self.elcAssets.count <= numberToLoad) {
             
             [self.tableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:YES];
             
             if (self.elcAssets.count == numberToLoad-4) {
                 [self.navigationItem performSelectorOnMainThread:@selector(setTitle:) withObject:@"Pick Photos" waitUntilDone:YES];   
             }
             
             if (self.elcAssets.count == 1) {
                 [self performSelectorOnMainThread:@selector(scrollTableViewToBottom) withObject:nil waitUntilDone:YES];                 
             }
         }
         
         [elcAsset release];
     }];

    self.navigationItem.title = @"Pick Photos";
    [pool release];
}

- (void)scrollTableViewToBottom {
    
    int lastRowIndex = [self tableView:nil numberOfRowsInSection:0] - 1;
    if (lastRowIndex >= 0) {
        
        NSIndexPath* lastRowIndexPath = [NSIndexPath indexPathForRow:lastRowIndex inSection:0];
        [self.tableView scrollToRowAtIndexPath:lastRowIndexPath atScrollPosition:UITableViewScrollPositionBottom animated:NO];   
    }
}

- (void)doneAction:(id)sender {
	
	NSMutableArray *selectedAssetsImages = [[NSMutableArray alloc] init];
	    
	for(ELCAsset *elcAsset in self.elcAssets) 
    {		
		if([elcAsset selected]) {
			
			[selectedAssetsImages addObject:[elcAsset asset]];
		}
	}
        
    [(ELCAlbumPickerController*)self.parent selectedAssets:selectedAssetsImages];
    [selectedAssetsImages release];
}

#pragma mark UITableViewDataSource Delegate Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    // Add two rows for the padding rows at the top and bottom of each section
    return ceil([self.assetGroup numberOfAssets] / 4.0) + 2;
}

// ugly
-(NSArray*)assetsForIndexPath:(NSIndexPath*)_indexPath {
    
    int index = (self.assetGroup.numberOfAssets-1)-(_indexPath.row*4);
    
    int minIndex;
    if (index < 3) {
        minIndex = 0;
    } else {
        minIndex = index-3;
    }
    
    // If there's four images in the row
	if((index - minIndex) == 3 && index < self.elcAssets.count) {
        
		return [NSArray arrayWithObjects:[self.elcAssets objectAtIndex:minIndex+3],
				[self.elcAssets objectAtIndex:minIndex+2],
				[self.elcAssets objectAtIndex:minIndex+1],
				[self.elcAssets objectAtIndex:minIndex],
				nil];
	}
    // If there's three images in the row    
	else if ((index - minIndex) == 2 && index < self.elcAssets.count) {
        
		return [NSArray arrayWithObjects:[self.elcAssets objectAtIndex:minIndex+2],
				[self.elcAssets objectAtIndex:minIndex+1],
				[self.elcAssets objectAtIndex:minIndex],
				nil];
	}
    // If there's two images in the row
	else if ((index - minIndex) == 1 && index < self.elcAssets.count) {
        
		return [NSArray arrayWithObjects:[self.elcAssets objectAtIndex:minIndex+1],
				[self.elcAssets objectAtIndex:minIndex],
				nil];
	}
    // If there's one image in the row
	else if ((index - minIndex) == 0 && index < self.elcAssets.count) {
        
		return [NSArray arrayWithObject:[self.elcAssets objectAtIndex:minIndex]];
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
            cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:whitespaceCellIdentifier] autorelease];
        }
        return cell;
    } else if ([indexPath row] == [self tableView:tableView numberOfRowsInSection:[indexPath section]]-1) {
        
        static NSString *whitespaceCellIdentifier = @"ELCCountTableViewCell";
        UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:whitespaceCellIdentifier];
        if (cell == nil) {
            cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:whitespaceCellIdentifier] autorelease];
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
            cell = [[[ELCAssetCell alloc] initWithAssets:[self assetsForIndexPath:updatedIndexPath] reuseIdentifier:CellIdentifier] autorelease];
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
        return 2;
    } else if (indexPath.row == [self tableView:tableView numberOfRowsInSection:indexPath.section]-1) {
        return 50;
    } else {
        return 79;
    }
}

- (int)totalSelectedAssets {
    
    int count = 0;
    
    for(ELCAsset *asset in self.elcAssets) 
    {
		if([asset selected]) 
        {            
            count++;	
		}
	}
    
    return count;
}

- (void)dealloc 
{
    [elcAssets release];
    [selectedAssetsLabel release];
    [super dealloc];    
}

@end
