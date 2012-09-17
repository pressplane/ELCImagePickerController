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
	ALAsset *_asset;
        NSURL *url;
	UIImageView *overlayView;
	BOOL selected;
	id parent;
}

//@property (nonatomic) ALAsset *asset;
@property (nonatomic) NSURL *url;
@property (nonatomic, unsafe_unretained) id<ELCAssetProtocol> delegate;
@property (nonatomic) BOOL selected;
@property (nonatomic, strong) UIImage *thumbnail;

-(id)initWithAsset:(ALAsset*)_asset;
- (void)toggleSelected;
@end

@protocol ELCAssetProtocol <NSObject>

@optional
- (void)assetSelected:(ELCAsset*)asset;

@end
