
// From http://blog.logichigh.com/2008/06/05/uiimage-fix/

#import <UIKit/UIKit.h>

@interface UIImage (ScaleAndRotate)

- (UIImage *)scaledAndRotatedImageWithMaxResolution:(int)maxResolution;

@end
