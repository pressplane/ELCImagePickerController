//
//  AssetCell.m
//
//  Created by Matt Tuzzolo on 2/15/11.
//  Copyright 2011 ELC Technologies. All rights reserved.
//

#import "ELCAssetCell.h"
#import "ELCAsset.h"

@interface ELCAssetCell () {
    NSInteger assetsPerRow;
    NSMutableArray *imageViews;
    NSMutableArray *overlayViews;
}

@end

@implementation ELCAssetCell

@synthesize rowAssets;

-(id)initWithAssets:(NSArray*)_assets assetsPerRow:(NSInteger)perRow reuseIdentifier:(NSString*)_identifier
{    
	if(self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:_identifier]) {
        assetsPerRow = perRow;
        [self setAssets:_assets];
	}
	
	return self;
}

-(void)setAssets:(NSArray*)_assets
{
    // Nuke old subviews...
	for(UIView *view in [self subviews]) 
    {		
		[view removeFromSuperview];
	}
	
	self.rowAssets = _assets;
    
    imageViews = [[NSMutableArray alloc] initWithCapacity:self.rowAssets.count];
    overlayViews = [[NSMutableArray alloc] initWithCapacity:self.rowAssets.count];

    // Setup views for asset
    for (ELCAsset *asset in self.rowAssets) {
		UIImageView *assetImageView = [[UIImageView alloc] initWithFrame:CGRectZero];
		[assetImageView setContentMode:UIViewContentModeScaleAspectFill];
		[assetImageView setImage:[asset thumbnail]];
		[self addSubview:assetImageView];
        [imageViews addObject:assetImageView];

        assetImageView.userInteractionEnabled = YES;
        [assetImageView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggleSelection:)]];
		
		UIImageView *overlayView = [[UIImageView alloc] initWithFrame:CGRectZero];
		[overlayView setImage:[UIImage imageNamed:@"Overlay.png"]];
		[overlayView setHidden:!asset.isSelected];
        overlayView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        // add the overlay as a subview of the assetImageView, so gesture recognizers work regardless of whether the overlay is shown
		[assetImageView addSubview:overlayView];
        [overlayViews addObject:overlayView];
    }
    
    [self setNeedsLayout];
}

- (void)toggleSelection:(UITapGestureRecognizer *)recognizer
{
    int tappedIndex = [imageViews indexOfObject:recognizer.view];
    if (tappedIndex != NSNotFound) {
        UIImageView *overlayView = [overlayViews objectAtIndex:tappedIndex];
        ELCAsset *elcAsset = [self.rowAssets objectAtIndex:tappedIndex];
        [elcAsset toggleSelected];

        overlayView.hidden = !elcAsset.isSelected;
    }
}


- (void)layoutSubviews
{    
    CGRect frame;
    CGFloat padding = [ELCAssetCell cellPadding];
    frame = CGRectMake(padding, padding/2, 75, 75);
	
	for(int i=0,cnt=self.rowAssets.count;i<cnt;i++) {
        UIImageView *imageView = [imageViews objectAtIndex:i];
        
		[imageView setFrame:frame];
		
		frame.origin.x = frame.origin.x + frame.size.width + padding;
	}
}

+ (CGFloat)cellPadding
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        return 13.0;
    } else {
        return 4.0;
    }
}


@end
