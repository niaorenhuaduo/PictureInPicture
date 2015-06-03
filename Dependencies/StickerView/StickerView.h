
#import <UIKit/UIKit.h>
#import "UIView+Frame.h"
//#import "UIImage+Utility.h"
#import "CircleView.h"

@interface StickerView : UIView

+ (void)setActiveStickerView:(StickerView*)view;

- (UIImageView*)imageView;
- (id)initWithImage:(UIImage *)image;
- (void)setScale:(CGFloat)scale;
- (void)setScale:(CGFloat)scaleX andScaleY:(CGFloat)scaleY;

@end
