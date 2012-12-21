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
#import "ELCAlbumPickerController.h"

#import "UIImage+ScaleAndRotate.h"

@interface ELCImagePickerController () {
}
@end

@implementation ELCImagePickerController

@synthesize delegate;


-(void)cancelImagePicker {

	if([delegate respondsToSelector:@selector(elcImagePickerControllerDidCancel:)]) {
		[delegate performSelector:@selector(elcImagePickerControllerDidCancel:) withObject:self];
	}
}

- (void)finishImagePicker:(NSSet*)selectedUrls
{
    // original version did this stuff but it's not necessary
    //    [self popToRootViewControllerAnimated:NO];
    //    [[self parentViewController] dismissModalViewControllerAnimated:YES];
	
    if([delegate respondsToSelector:@selector(elcImagePickerController:didFinishPickingMediaWithInfo:)]) {
		[delegate performSelector:@selector(elcImagePickerController:didFinishPickingMediaWithInfo:)
                       withObject:self
                       withObject:[self returnArray:selectedUrls]];
	}
}


- (NSArray *)returnArray:(NSSet*)selectedUrls
{
	NSMutableArray *returnArray = [[NSMutableArray alloc] init];
	
	for (NSURL *url in selectedUrls) 
    {
        NSMutableDictionary *workingDictionary = [[NSMutableDictionary alloc] initWithCapacity:1];
        [workingDictionary setObject:url forKey:@"URL"];
        [returnArray addObject:workingDictionary];
	}

    return [returnArray copy];
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
    //    NSLog(@"deallocing ELCImagePickerController");
}

@end
