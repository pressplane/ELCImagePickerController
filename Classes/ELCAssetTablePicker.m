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
	
	UIBarButtonItem *doneButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneAction:)] autorelease];
	[self.navigationItem setRightBarButtonItem:doneButtonItem];
	[self.navigationItem setTitle:@"Loading..."];

	[self performSelectorInBackground:@selector(preparePhotos) withObject:nil];
    
    // Show partial while full list loads
	[self.tableView performSelector:@selector(reloadData) withObject:nil afterDelay:.5];
}

-(void)viewWillDisappear:(BOOL)animated {
    self.assetGroup = nil;
    self.parent = nil;
    
    [super viewWillDisappear:animated];
}

-(void)preparePhotos {
    
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    int lastRowNumber = [self tableView:nil numberOfRowsInSection:0] - 1;
    if (lastRowNumber >= 0) {
        NSIndexPath* ip = [NSIndexPath indexPathForRow:lastRowNumber inSection:0];
        [self.tableView scrollToRowAtIndexPath:ip atScrollPosition:UITableViewScrollPositionTop animated:NO];   
    }
    
    NSLog(@"enumerating photos");
    [self.assetGroup enumerateAssetsWithOptions:NSEnumerationReverse usingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) 
     {         
         if(result == nil) 
         {
             return;
         }
         
         ELCAsset *elcAsset = [[[ELCAsset alloc] initWithAsset:result] autorelease];
         [elcAsset setParent:self];
         [self.elcAssets addObject:elcAsset];
     }];    
    NSLog(@"done enumerating photos");
	
	[self.tableView reloadData];
	[self.navigationItem setTitle:@"Pick Photos"];
    [pool release];

}

- (void) doneAction:(id)sender {
	
	NSMutableArray *selectedAssetsImages = [[[NSMutableArray alloc] init] autorelease];
	    
	for(ELCAsset *elcAsset in self.elcAssets) 
    {		
		if([elcAsset selected]) {
			
			[selectedAssetsImages addObject:[elcAsset asset]];
		}
	}
        
    [(ELCAlbumPickerController*)self.parent selectedAssets:selectedAssetsImages];
}

#pragma mark UITableViewDataSource Delegate Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return ceil([self.assetGroup numberOfAssets] / 4.0);
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
    
	// NSLog(@"Getting assets for %d to %d with array count %d", index, maxIndex, [assets count]);
    
	if((index - minIndex) == 3 && index < self.elcAssets.count) {
        
		return [NSArray arrayWithObjects:[self.elcAssets objectAtIndex:minIndex+3],
				[self.elcAssets objectAtIndex:minIndex+2],
				[self.elcAssets objectAtIndex:minIndex+1],
				[self.elcAssets objectAtIndex:minIndex],
				nil];
	}
    
	else if((index - minIndex) == 2 && index < self.elcAssets.count) {
        
		return [NSArray arrayWithObjects:[self.elcAssets objectAtIndex:minIndex+2],
				[self.elcAssets objectAtIndex:minIndex+1],
				[self.elcAssets objectAtIndex:minIndex],
				nil];
	}
    
	else if((index - minIndex) == 1 && index < self.elcAssets.count) {
        
		return [NSArray arrayWithObjects:[self.elcAssets objectAtIndex:minIndex+1],
				[self.elcAssets objectAtIndex:minIndex],
				nil];
	}
    
	else if((index - minIndex) == 0 && index < self.elcAssets.count) {
        
		return [NSArray arrayWithObject:[self.elcAssets objectAtIndex:minIndex]];
	}
    
	return nil;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
        
    ELCAssetCell *cell = (ELCAssetCell*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];

    if (cell == nil) 
    {		        
        cell = [[[ELCAssetCell alloc] initWithAssets:[self assetsForIndexPath:indexPath] reuseIdentifier:CellIdentifier] autorelease];
    }	
	else 
    {		
		[cell setAssets:[self assetsForIndexPath:indexPath]];
	}
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
	return 79;
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
