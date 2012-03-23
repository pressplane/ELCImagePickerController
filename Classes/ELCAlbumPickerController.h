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
    
	id __unsafe_unretained parent;
}

@property (nonatomic, unsafe_unretained) id parent;
@property (nonatomic) NSMutableArray *assetGroups;

@property (nonatomic) ELCAssetTablePicker *assetTablePicker;

-(void)selectedAssets:(NSArray*)_assets;

@end

