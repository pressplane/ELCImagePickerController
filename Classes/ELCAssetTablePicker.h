//
//  AssetTablePicker.h
//
//  Created by Matt Tuzzolo on 2/15/11.
//  Copyright 2011 ELC Technologies. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ELCAsset.h"
#import <AssetsLibrary/AssetsLibrary.h>

@interface ELCAssetTablePicker : UITableViewController <ELCAssetProtocol>
{
	ALAssetsGroup *__unsafe_unretained assetGroup;
	
	NSMutableArray *elcAssets;
	int selectedAssets;
	
	id __unsafe_unretained parent;
	
	NSOperationQueue *queue;
}

@property (nonatomic, unsafe_unretained) id parent;
@property (nonatomic, unsafe_unretained) ALAssetsGroup *assetGroup;
@property (nonatomic, strong) NSMutableArray *elcAssets;
@property (nonatomic, strong) IBOutlet UILabel *selectedAssetsLabel;

-(int)totalSelectedAssets;
-(void)preparePhotos;

-(void)doneAction:(id)sender;

@end