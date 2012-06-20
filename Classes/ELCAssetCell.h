//
//  AssetCell.h
//
//  Created by Matt Tuzzolo on 2/15/11.
//  Copyright 2011 ELC Technologies. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface ELCAssetCell : UITableViewCell
{
	NSArray *rowAssets;
}

-(id)initWithAssets:(NSArray*)_assets assetsPerRow:(NSInteger)perRow reuseIdentifier:(NSString*)_identifier;
-(void)setAssets:(NSArray*)_assets;

+ (CGFloat)cellPadding;

@property (nonatomic) NSArray *rowAssets;

@end
