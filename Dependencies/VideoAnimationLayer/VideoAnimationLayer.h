//
//  VideoAnimationLayer
//  VideoReflection
//
//  Created by Johnny Xu on 5/22/15.
//  Copyright (c) 2015 Future Studio. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

@interface VideoAnimationLayer : CALayer
{
}

@property (nonatomic,strong) NSString *videoFilePath;

+ (id)layerWithVideoFilePath:(NSString *)filePath withFrame:(CGRect)frame;
- (void)startAnimation;

@end
