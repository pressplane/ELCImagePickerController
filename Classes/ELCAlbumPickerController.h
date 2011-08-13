//
//  AlbumPickerController.h
//
//  Created by Matt Tuzzolo on 2/15/11.
//  Copyright 2011 ELC Technologies. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ELCAssetTablePicker;


@interface ELCAlbumPickerController : UITableViewController {
	
	NSMutableArray *assetGroups;
	NSOperationQueue *queue;
    
    ELCAssetTablePicker *assetTablePicker;
    
	id parent;
}

@property (nonatomic, assign) id parent;
@property (nonatomic, retain) NSMutableArray *assetGroups;

@property (nonatomic, retain) ELCAssetTablePicker *assetTablePicker;

-(void)selectedAssets:(NSArray*)_assets;

@end

