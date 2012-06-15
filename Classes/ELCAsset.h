//
//  Asset.h
//
//  Created by Matt Tuzzolo on 2/15/11.
//  Copyright 2011 ELC Technologies. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AssetsLibrary/AssetsLibrary.h>

@protocol ELCAssetProtocol;

@interface ELCAsset : UIView {
	ALAsset *asset;
	UIImageView *overlayView;
	BOOL selected;
	id parent;
}

@property (nonatomic) ALAsset *asset;
@property (nonatomic, unsafe_unretained) id<ELCAssetProtocol> delegate;

@property (nonatomic) BOOL selected;

-(id)initWithAsset:(ALAsset*)_asset;

@end

@protocol ELCAssetProtocol <NSObject>

@optional
- (void)assetSelected:(ELCAsset*)asset;

@end