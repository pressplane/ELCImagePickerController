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

#define SYSTEM_VERSION_LESS_THAN(v) ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)

@interface ELCAssetTablePicker()

- (void)scrollTableViewToBottom;

- (NSInteger)assetsPerRow;

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
    
    self.navigationController.navigationBar.barStyle = UIBarStyleBlackTranslucent;

    if (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad) {
        self.wantsFullScreenLayout = YES;
    } else {
        [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleBlackTranslucent;
    }
    
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
    
    // Isn't happy on iOS 4, so just hardcoding it
    // NSUInteger numberToLoad = [self.tableView indexPathsForVisibleRows].count * 4;
    
    NSUInteger numberToLoad;
    
    if (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad) {
        numberToLoad = 10 * [self assetsPerRow];   
    } else {
        numberToLoad = 6 * [self assetsPerRow];   
    }
    
    [self.assetGroup enumerateAssetsWithOptions:NSEnumerationReverse usingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) 
     {         
         if(result == nil) {
             return;
         }
         
         ELCAsset *elcAsset = [[ELCAsset alloc] initWithAsset:result];
         [elcAsset setDelegate:self];
         [self.elcAssets addObject:elcAsset];
         
         //Once we've loaded the numberToLoad then we should reload the table data because the screen is full
         if (self.elcAssets.count <= numberToLoad) {
             
             [self.tableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
             
             if (self.elcAssets.count == numberToLoad-[self assetsPerRow]) {
                 [self.navigationItem performSelectorOnMainThread:@selector(setTitle:) withObject:@"Select Photos" waitUntilDone:YES];   
             }
             
             if (self.elcAssets.count == 1) {
                 [self performSelectorOnMainThread:@selector(scrollTableViewToBottom) withObject:nil waitUntilDone:YES];
             }
         }
         
         [elcAsset release];
     }];

    self.navigationItem.title = @"Select Photos";
    [pool release];
}

- (void)assetSelected:(ELCAsset*)asset
{
    NSLog(@"total selected assets: %i", [self totalSelectedAssets]);
    
    int totalSelectedAssets = [self totalSelectedAssets];
    
    if (totalSelectedAssets == 0) {
        self.navigationItem.title = @"Select Photos";
    } else if (totalSelectedAssets == 1) {
        self.navigationItem.title = @"1 Photo";
    } else {
        self.navigationItem.title = [NSString stringWithFormat:@"%i Photos", totalSelectedAssets];
    }
    
    if (totalSelectedAssets > 20) {
         
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
                [titleLabel release];
                
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
}

- (void)scrollTableViewToBottom {
    
    int lastRowIndex = [self tableView:nil numberOfRowsInSection:0] - 1;
    if (lastRowIndex >= 0) {
        
        NSIndexPath* lastRowIndexPath = [NSIndexPath indexPathForRow:lastRowIndex inSection:0];
        [self.tableView scrollToRowAtIndexPath:lastRowIndexPath atScrollPosition:UITableViewScrollPositionBottom animated:NO];   
    }
}

-(void)scrollToBottom {

    int lastRowNumber = [self tableView:nil numberOfRowsInSection:0] - 1;
    if (lastRowNumber >= 0) {
        NSIndexPath* ip = [NSIndexPath indexPathForRow:lastRowNumber inSection:0];
        [self.tableView scrollToRowAtIndexPath:ip atScrollPosition:UITableViewScrollPositionTop animated:NO];   
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

- (NSInteger)assetsPerRow
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        return 6;
    } else {
        return 4;
    }
}

#pragma mark UITableViewDataSource Delegate Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    // Add two rows for padding at the top and bottom of each section
    return ceil(((CGFloat)[self.assetGroup numberOfAssets]) / ((CGFloat)[self assetsPerRow])) + 2;
}

// ugly
-(NSArray*)assetsForIndexPath:(NSIndexPath*)_indexPath {
    
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
