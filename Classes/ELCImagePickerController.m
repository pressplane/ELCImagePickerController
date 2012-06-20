//
//  ELCImagePickerController.m
//  ELCImagePickerDemo
//
//  Created by Collin Ruffenach on 9/9/10.
//  Copyright 2010 ELC Technologies. All rights reserved.
//

#import "ELCImagePickerController.h"
#import "ELCAsset.h"
#import "ELCAssetCell.h"
#import "ELCAssetTablePicker.h"
#import "ELCAlbumPickerController.h"

#import "UIImage+ScaleAndRotate.h"

@implementation ELCImagePickerController

@synthesize delegate;

-(void)cancelImagePicker {

	if([delegate respondsToSelector:@selector(elcImagePickerControllerDidCancel:)]) {
		[delegate performSelector:@selector(elcImagePickerControllerDidCancel:) withObject:self];
	}
}

-(void)selectedAssets:(NSArray*)_assets {

	NSMutableArray *returnArray = [[NSMutableArray alloc] init];
	
	for(ALAsset *asset in _assets) {
        
        @autoreleasepool {

			NSMutableDictionary *workingDictionary = [[NSMutableDictionary alloc] init];
			[workingDictionary setObject:[asset valueForProperty:ALAssetPropertyType]
                                  forKey:@"ALAssetPropertyType"];
        
            [workingDictionary setObject:(id)asset.defaultRepresentation.fullScreenImage
                                  forKey:@"ALAssetFullScreenImageRef"];
        
			[workingDictionary setObject:[[asset valueForProperty:ALAssetPropertyURLs]
                                          valueForKey:[[[asset valueForProperty:ALAssetPropertyURLs] allKeys]
                                                       objectAtIndex:0]]
                                  forKey:@"ALAssetPropertyURL"];

            [workingDictionary setObject:asset.defaultRepresentation
                                  forKey:@"ALAssetRepresentation"];
            
            [workingDictionary setObject:asset
                                  forKey:@"ALAsset"];

			[returnArray addObject:workingDictionary];        
        }
	}
	
    [self popToRootViewControllerAnimated:NO];
//    [[self parentViewController] dismissModalViewControllerAnimated:YES];
    
	if([delegate respondsToSelector:@selector(elcImagePickerController:didFinishPickingMediaWithInfo:)]) {
		[delegate performSelector:@selector(elcImagePickerController:didFinishPickingMediaWithInfo:) withObject:self withObject:[NSArray arrayWithArray:returnArray]];
	}
}

#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {    
    NSLog(@"ELC Image Picker received memory warning!!!");
    
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload {
    [super viewDidUnload];
}


- (void)dealloc {
    NSLog(@"deallocing ELCImagePickerController");
}

@end
