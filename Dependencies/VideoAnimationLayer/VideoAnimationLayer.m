//
//  VideoAnimationLayer
//  VideoReflection
//
//  Created by Johnny Xu on 5/22/15.
//  Copyright (c) 2015 Future Studio. All rights reserved.
//

#import "VideoAnimationLayer.h"
#import "MIMovieVideoSampleAccessor.h"

@interface VideoAnimationLayer()
{
}

@property (nonatomic,assign) NSUInteger currentVideoFrameIndex;
@property (strong, nonatomic) NSMutableArray *imageVideoFrames;
@property (assign, nonatomic) CGFloat videoDuration;

@end

@implementation VideoAnimationLayer

- (id)init
{
    self = [super init];
    
    if (self)
    {
        _currentVideoFrameIndex = NSNotFound;
        _videoDuration = 0;
        _imageVideoFrames = nil;
        
        self.cornerRadius = CGRectGetWidth(self.frame)/2;
        self.borderWidth = 2.0;
        self.borderColor = kLightBlue.CGColor;
        self.masksToBounds = YES;
    }
    return self;
}

+ (id)layerWithVideoFilePath:(NSString *)filePath withFrame:(CGRect)frame
{
    VideoAnimationLayer *layer = [self layer];
    layer.frame = frame;
    layer.cornerRadius = CGRectGetWidth(frame)/2;
    layer.borderWidth = 2.0;
    layer.borderColor = kLightBlue.CGColor;
    layer.masksToBounds = YES;
//    layer.backgroundColor = [UIColor whiteColor].CGColor;
    layer.videoFilePath = filePath;
    
    return layer;
}

+ (BOOL)needsDisplayForKey:(NSString *)key
{
    return [key isEqualToString:@"currentVideoFrameIndex"];
}

- (void)display
{
    NSUInteger index = [(VideoAnimationLayer *)[self presentationLayer] currentVideoFrameIndex];
    if (index == NSNotFound)
    {
        return;
    }
    
    NSLog(@"display frame index: %lu", (unsigned long)index);
    
    if (_imageVideoFrames && [_imageVideoFrames count] > 0)
    {
        [CATransaction begin];
        [CATransaction setDisableActions:YES];
        self.contents = (id)_imageVideoFrames[index];
        [CATransaction commit];
    }
}

- (void)setVideoFilePath:(NSString *)videoFilePath
{
    if (!isStringEmpty(videoFilePath))
    {
        _videoFilePath = videoFilePath;
        _videoDuration = [self captureVideoSample:getFileURL(_videoFilePath)];
        
        [self setCurrentVideoFrameIndex:0];
        [self display];
        
        [self startAnimation];
    }
}

#pragma mark - Animation
- (void)startAnimation
{
    int repeatCount = 1;
    CFTimeInterval interval = 0.1;
    CAKeyframeAnimation *animContents = [CAKeyframeAnimation animationWithKeyPath:@"contents"];
    animContents.duration = _videoDuration;
    animContents.values = [NSArray arrayWithArray:_imageVideoFrames];
    animContents.beginTime = interval;
    animContents.repeatCount = repeatCount;
    animContents.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
    animContents.removedOnCompletion = NO;
    animContents.delegate = self;
    [animContents setValue:@"stop" forKey:@"TAG"];
    [self addAnimation:animContents forKey:@"contents"];
}

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag
{
    NSString *tag = [anim valueForKey:@"TAG"];
    if ([tag isEqualToString:@"stop"])
    {
//        self.contents = nil;
        _currentVideoFrameIndex = NSNotFound;
        
        NSLog(@"animationDidStop for Video");
    }
}

#pragma mark - Capture Video Sample
- (CGFloat)captureVideoSample:(NSURL *)videoURL
{
    if (_imageVideoFrames)
    {
        [_imageVideoFrames removeAllObjects];
    }
    else
    {
        _imageVideoFrames = [[NSMutableArray alloc] initWithCapacity:100];
    }
    
    AVURLAsset *videoAsset = [AVURLAsset URLAssetWithURL:videoURL options:nil];
    MIMovieVideoSampleAccessor *sampleAccessor = [[MIMovieVideoSampleAccessor alloc]  initWithMovie:videoAsset
                                                                                    firstSampleTime:kCMTimeZero
                                                                                             tracks:nil
                                                                                      videoSettings:nil
                                                                                   videoComposition:nil];
    
    // Calc & Show precentage
    CGFloat totalSeconds = sampleAccessor.assetDuration.value / sampleAccessor.assetDuration.timescale;
    while (TRUE)
    {
        MICMSampleBuffer *buffer = [sampleAccessor nextSampleBuffer];
        if (!buffer)
        {
            return totalSeconds;
        }
        
        // Get frame image
        CMSampleBufferRef sampleBuffer = buffer.CMSampleBuffer;
        UIImage *thumbnail = imageFromSampleBuffer(sampleBuffer);
        if (thumbnail)
        {
            [_imageVideoFrames addObject:(id)[thumbnail CGImage]];
        }
    }
    
    return totalSeconds;
}

@end
