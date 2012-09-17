//
//  Asset.m
//
//  Created by Matt Tuzzolo on 2/15/11.
//  Copyright 2011 ELC Technologies. All rights reserved.
//

#import "ELCAsset.h"
#import "ELCAssetTablePicker.h"

@implementation ELCAsset

@synthesize url;
@synthesize delegate;

@synthesize thumbnail;
@synthesize selected;

-(id)initWithAsset:(ALAsset*)asset {
	
	if (self = [super initWithFrame:CGRectMake(0, 0, 0, 0)]) {
		self->_asset = asset;
        self.url = asset.defaultRepresentation.url;
    }
    
	return self;
}

- (void)toggleSelected
{
    selected = !selected;
    
    if ([self.delegate respondsToSelector:@selector(assetSelected:)]) {
        [self.delegate assetSelected:self];
    }
}

- (UIImage *)thumbnail
{
    if (!thumbnail) {
        thumbnail = [UIImage imageWithCGImage:self->_asset.thumbnail];
    }
    return thumbnail;
}

- (void)dealloc 
{    
    self.delegate = nil;
}

@end

