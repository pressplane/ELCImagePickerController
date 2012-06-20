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

@interface ELCImagePickerController () {
    NSMutableArray *_selectedAssets;
}
@end

@implementation ELCImagePickerController

@synthesize delegate;


-(void)cancelImagePicker {

	if([delegate respondsToSelector:@selector(elcImagePickerControllerDidCancel:)]) {
		[delegate performSelector:@selector(elcImagePickerControllerDidCancel:) withObject:self];
	}
}

- (void)finishImagePicker
{
    // original version did this stuff but it's not necessary
    //    [self popToRootViewControllerAnimated:NO];
    //    [[self parentViewController] dismissModalViewControllerAnimated:YES];
	
    if([delegate respondsToSelector:@selector(elcImagePickerController:didFinishPickingMediaWithInfo:)]) {
		[delegate performSelector:@selector(elcImagePickerController:didFinishPickingMediaWithInfo:) withObject:self withObject:[self returnArray]];
	}
}

// builds the array of info dictionaries to return
- (NSArray *)returnArray
{
	NSMutableArray *returnArray = [[NSMutableArray alloc] init];
	
	for(ALAsset *asset in _selectedAssets) {
        NSMutableDictionary *workingDictionary = [[NSMutableDictionary alloc] initWithCapacity:2];
//        [workingDictionary setObject:[asset valueForProperty:ALAssetPropertyType]
//                              forKey:@"ALAssetPropertyType"];
        
//            [workingDictionary setObject:(id)asset.defaultRepresentation.fullScreenImage
//                                  forKey:@"ALAssetFullScreenImageRef"];
        
//        [workingDictionary setObject:[[asset valueForProperty:ALAssetPropertyURLs]
//                                      valueForKey:[[[asset valueForProperty:ALAssetPropertyURLs] allKeys]
//                                                   objectAtIndex:0]]
//                              forKey:@"ALAssetPropertyURL"];
        
        [workingDictionary setObject:asset.defaultRepresentation
                              forKey:@"ALAssetRepresentation"];
        
        [workingDictionary setObject:asset
                              forKey:@"ALAsset"];
        
        [returnArray addObject:workingDictionary];
	}

    return [returnArray copy];
}

- (void)updateAssetsSelected:(NSArray*)selected unselected:(NSArray *)unselected
{
    if (!_selectedAssets) {
        _selectedAssets = [[NSMutableArray alloc] initWithCapacity:selected.count];
    }
    
    // remove any assets that are in the selected list but present in unselected
    // (these will be assets that the user unchecked)
    // this is O(n*m), so will suck if you have big groups and lots of selections,
    // if that becomes a problem the thing to do is keep more precise track of unselections and just send those, not the entire group
    for (ALAsset *asset in _selectedAssets) {
        if ([unselected containsObject:asset]) {
            [_selectedAssets removeObject:asset];
        }
    }
    
    [_selectedAssets addObjectsFromArray:selected];
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
