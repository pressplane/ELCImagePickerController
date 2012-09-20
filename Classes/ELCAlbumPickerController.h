//
//  AlbumPickerController.h
//
//  Created by Matt Tuzzolo on 2/15/11.
//  Copyright 2011 ELC Technologies. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ELCAssetTablePicker, ALAssetsLibrary;

@interface ELCAlbumPickerController : UITableViewController {
	NSMutableArray *assetGroups;
	NSOperationQueue *queue;
    
    ELCAssetTablePicker *assetTablePicker;
    
	id __unsafe_unretained parent;
}

@property (nonatomic, unsafe_unretained) id parent;
@property (nonatomic, strong) ALAssetsLibrary *assetLibrary;
@property (nonatomic, strong) NSMutableArray *assetGroups;

@property (nonatomic, strong) ELCAssetTablePicker *assetTablePicker;

@property (nonatomic, strong) NSSet *alreadySelectedURLs;

// Provide our own asset library so the Asset URLs will live on!
- (id)initWithAssetLibrary:(ALAssetsLibrary *)library maxBatchSize:(int)batchSize;

- (void)updateAssetsSelected:(NSArray*)selected unselected:(NSArray *)unselected;
- (void)finishPicking;

@end

