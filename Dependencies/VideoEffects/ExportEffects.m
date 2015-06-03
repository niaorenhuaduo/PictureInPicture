//
//  ExportEffects
//  PictureInPicture
//
//  Created by Johnny Xu on 5/30/15.
//  Copyright (c) 2015 Future Studio. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <QuartzCore/QuartzCore.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "ExportEffects.h"
#import "GifAnimationLayer.h"
#import "VideoAnimationLayer.h"
#import "StickerView.h"
#import "VideoView.h"

#define DefaultOutputVideoName @"outputMovie.mp4"
#define DefaultOutputAudioName @"outputAudio.caf"

@interface ExportEffects ()
{
}

@property(nonatomic, copy) NSNumber *audioSampleRate;
@property(nonatomic, copy) NSNumber *numberOfAudioChannels;
@property(nonatomic, copy) NSString *audioOutPath;
@property (strong, nonatomic) AVAudioRecorder *audioRecorder;

@property (strong, nonatomic) NSTimer *timerEffect;
@property (strong, nonatomic) AVAssetExportSession *exportSession;

@property (strong, nonatomic) NSMutableArray *gifArray;
@property (strong, nonatomic) NSMutableArray *videoArray;

@end

@implementation ExportEffects
{

}

+ (ExportEffects *)sharedInstance
{
    static ExportEffects *sharedInstance = nil;
    static dispatch_once_t pred;
    dispatch_once(&pred, ^{
        sharedInstance = [[ExportEffects alloc] init];
    });
    
    return sharedInstance;
}

- (id)init
{
    self = [super init];
    
    if (self)
    {
        _audioOutPath = nil;
        _timerEffect = nil;
        _exportSession = nil;
        
        _gifArray = nil;
        _videoArray = nil;
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    if (_exportSession)
    {
        _exportSession = nil;
    }
    
    if (_timerEffect)
    {
        [_timerEffect invalidate];
        _timerEffect = nil;
    }
}

- (void)initGifArray:(NSMutableArray *)gifs withVideoArray:(NSMutableArray *)videos
{
    if (gifs && [gifs count] > 0)
    {
        if (!_gifArray)
        {
            _gifArray = [NSMutableArray arrayWithCapacity:1];
        }
        else
        {
            [_gifArray removeAllObjects];
        }
        
        _gifArray = [NSMutableArray arrayWithArray:gifs];
    }
    
    if (videos && [videos count] > 0)
    {
        if (!_videoArray)
        {
            _videoArray = [NSMutableArray arrayWithCapacity:1];
        }
        else
        {
            [_videoArray removeAllObjects];
        }
        
        _videoArray = [NSMutableArray arrayWithArray:videos];
    }
}

#pragma mark Setup
- (void)setupNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
}

#pragma mark Background tasks
- (void)applicationDidEnterBackground:(NSNotification *)notification
{
//    UIApplication *application = [UIApplication sharedApplication];
    
    UIDevice *device = [UIDevice currentDevice];
    BOOL backgroundSupported = NO;
    if ([device respondsToSelector:@selector(isMultitaskingSupported)])
    {
        backgroundSupported = device.multitaskingSupported;
    }
    
    if (backgroundSupported)
    {
    }
}

- (void)applicationWillEnterForeground:(NSNotification *)notification
{

}

#pragma mark Utility methods
- (NSString *)documentDirectory
{
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = [paths objectAtIndex:0];
	return documentsDirectory;
}

- (NSString *)defaultFilename
{
    time_t timer;
    time(&timer);
    NSString *timestamp = [NSString stringWithFormat:@"%ld", timer];
    return [NSString stringWithFormat:@"%@.mov", timestamp];
}

- (BOOL)existsFile:(NSString *)filename
{
    NSString *path = [self.documentDirectory stringByAppendingPathComponent:filename];
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    BOOL isDirectory;
    return [fileManager fileExistsAtPath:path isDirectory:&isDirectory] && !isDirectory;
}

- (NSString *)nextFilename:(NSString *)filename
{
    static NSInteger fileCounter;
    
    fileCounter++;
    NSString *pathExtension = [filename pathExtension];
    filename = [[[filename stringByDeletingPathExtension] stringByAppendingString:[NSString stringWithFormat:@"-%ld", (long)fileCounter]] stringByAppendingPathExtension:pathExtension];
    
    if ([self existsFile:filename])
    {
        return [self nextFilename:filename];
    }
    
    return filename;
}

- (NSString*)getOutputFilePath
{
    NSString* mp4OutputFile = [NSTemporaryDirectory() stringByAppendingPathComponent:DefaultOutputVideoName];
    return mp4OutputFile;
    
    //    NSString *path = NSTemporaryDirectory();
    //    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    //    formatter.dateFormat = @"yyyyMMddHHmmss";
    //    NSString *nowTimeStr = [formatter stringFromDate:[NSDate dateWithTimeIntervalSinceNow:0]];
    //
    //    NSString *fileName = [[path stringByAppendingPathComponent:nowTimeStr] stringByAppendingString:@".mp4"];
    //    return fileName;
}

#pragma mark - Export Progress Callback
- (void)retrievingExportProgress
{
    if (_exportSession && _exportProgressBlock)
    {
        self.exportProgressBlock([NSNumber numberWithFloat:_exportSession.progress]);
    }
}

#pragma mark - Export Video
- (void)writeExportedVideoToAssetsLibrary:(NSString *)outputPath
{
    __unsafe_unretained typeof(self) weakSelf = self;
    NSURL *exportURL = [NSURL fileURLWithPath:outputPath];
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    if ([library videoAtPathIsCompatibleWithSavedPhotosAlbum:exportURL])
    {
        [library writeVideoAtPathToSavedPhotosAlbum:exportURL completionBlock:^(NSURL *assetURL, NSError *error)
         {
             NSString *message;
             if (!error)
             {
                 message = GBLocalizedString(@"MsgSuccess");
             }
             else
             {
                 message = [error description];
             }
             
             NSLog(@"%@", message);
             
             if (weakSelf.finishVideoBlock)
             {
                 weakSelf.finishVideoBlock(YES, message);
             }
         }];
    }
    else
    {
        NSString *message = GBLocalizedString(@"MsgFailed");;
        NSLog(@"%@", message);
        
        if (_finishVideoBlock)
        {
            _finishVideoBlock(NO, message);
        }
    }
    
    library = nil;
}

#pragma mark - Audio
- (void)setupAudioRecord
{
    // Setup to be able to record global sounds (preexisting app sounds)
    NSError *sessionError = nil;
    if ([[AVAudioSession sharedInstance] respondsToSelector:@selector(setCategory:withOptions:error:)])
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionDuckOthers error:&sessionError];
    else
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:&sessionError];
    
    // Set the audio session to be active
    [[AVAudioSession sharedInstance] setActive:YES error:&sessionError];
    
    if (sessionError)
    {
        self.finishVideoBlock(NO, sessionError.description);
        return;
    }
    
    // Set the number of audio channels, using defaults if necessary.
    NSNumber *audioChannels = (self.numberOfAudioChannels ? self.numberOfAudioChannels : @2);
    NSNumber *sampleRate    = (self.audioSampleRate       ? self.audioSampleRate       : @44100.f);
    
    NSDictionary *audioSettings = @{
                                    AVNumberOfChannelsKey : (audioChannels ? audioChannels : @2),
                                    AVSampleRateKey       : (sampleRate    ? sampleRate    : @44100.0f)
                                    };
    
    
    // Initialize the audio recorder
    // Set output path of the audio file
    NSError *error = nil;
    NSAssert((self.audioOutPath != nil), @"Audio out path cannot be nil!");
    _audioRecorder = [[AVAudioRecorder alloc] initWithURL:[NSURL fileURLWithPath:self.audioOutPath] settings:audioSettings error:&error];
    if (error)
    {
        // Let the delegate know that shit has happened.
        self.finishVideoBlock(NO, error.description);;
        _audioRecorder = nil;
        
        return;
    }
    
    [_audioRecorder prepareToRecord];
    
    // Start recording :P
    [_audioRecorder record];
}

- (void)stopAudioRecord
{
    // Stop the audio recording
    [_audioRecorder stop];
    _audioRecorder = nil;
}

- (void)addEffectToVideo:(NSString *)videoFilePath
{
    if (isStringEmpty(videoFilePath))
    {
        NSLog(@"videoFilePath is empty!");
        
        if (self.finishVideoBlock)
        {
            self.finishVideoBlock(NO, GBLocalizedString(@"MsgConvertFailed"));
        }
        
        return;
    }
    
    double degrees = 0.0;
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    if ([prefs objectForKey:@"vidorientation"])
        degrees = [[prefs objectForKey:@"vidorientation"] doubleValue];
    
    NSString *videoPath = videoFilePath;
    NSURL *videoURL = getFileURL(videoFilePath); //[NSURL fileURLWithPath:videoPath];
    
//    AVURLAsset *videoAsset = [[AVURLAsset alloc] initWithURL:videoURL options:nil];
    AVAsset *videoAsset = [AVAsset assetWithURL:videoURL];
    
    AVAssetTrack *assetVideoTrack = nil;
    NSArray *assetArray = [videoAsset tracksWithMediaType:AVMediaTypeVideo];
    if ([assetArray count] > 0)
        assetVideoTrack = assetArray[0];
    
    CGSize videoSize = CGSizeZero;
    AVMutableComposition *mixComposition = [AVMutableComposition composition];
    if (assetVideoTrack)
    {
        videoSize = assetVideoTrack.naturalSize;
        
        AVMutableCompositionTrack *compositionVideoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
        [compositionVideoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, videoAsset.duration) ofTrack:assetVideoTrack atTime:kCMTimeZero error:nil];
        [compositionVideoTrack setPreferredTransform:CGAffineTransformMakeRotation(degreesToRadians(degrees))];
    }
    
    NSLog(@"videoSize width: %f, Height: %f", videoSize.width, videoSize.height);
    if (videoSize.height == 0 || videoSize.width == 0)
    {
        if (self.finishVideoBlock)
        {
            self.finishVideoBlock(NO, GBLocalizedString(@"MsgConvertFailed"));
        }
        
        return;
    }
    
    AVMutableCompositionTrack *audioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    if ([[videoAsset tracksWithMediaType:AVMediaTypeAudio] count] > 0)
    {
        AVAssetTrack *assetAudioTrack = [[videoAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
        [audioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, videoAsset.duration) ofTrack:assetAudioTrack atTime:kCMTimeZero error:nil];
    }
    else
    {
        NSLog(@"Reminder: video hasn't audio!");
    }
    
    // 4. Effects
    CALayer *parentLayer = [CALayer layer];
    CALayer *videoLayer = [CALayer layer];
    parentLayer.bounds = CGRectMake(0, 0, videoSize.width, videoSize.height);
    parentLayer.anchorPoint = CGPointMake(0, 0);
    parentLayer.position = CGPointMake(0, 0);
    
    videoLayer.bounds = parentLayer.bounds;
    videoLayer.anchorPoint =  CGPointMake(0.5, 0.5);
    videoLayer.position = CGPointMake(CGRectGetMidX(parentLayer.bounds), CGRectGetMidY(parentLayer.bounds));
    
    parentLayer.geometryFlipped = YES;
//    CGFloat screenScale = [UIScreen mainScreen].scale;
//    parentLayer.sublayerTransform = CATransform3DMakeScale(screenScale, screenScale, 1);
    [parentLayer addSublayer:videoLayer];
    
    // Animation effects
    NSMutableArray *animatedLayers = [[NSMutableArray alloc] init];
    CALayer *animatedLayer = nil;
    
    // 1. Gifs
    if (_gifArray && [_gifArray count] > 0)
    {
        for (StickerView *view in _gifArray)
        {
            NSString *gifPath = view.getFilePath;
            CGRect frame = view.getInnerFrame;
            animatedLayer = [GifAnimationLayer layerWithGifFilePath:gifPath withFrame:frame];
            if (animatedLayer && [animatedLayer isKindOfClass:[GifAnimationLayer class]])
            {
                [animatedLayers addObject:(id)animatedLayer];
            }
        }
    }
    
    
    // 2. Videos
    if (_videoArray && [_videoArray count] > 0)
    {
        for (VideoView *view in _videoArray)
        {
            NSString *videoPath = view.getFilePath;
            CGRect frame = view.getInnerFrame;
            animatedLayer = [VideoAnimationLayer layerWithVideoFilePath:videoPath withFrame:frame];
            if (animatedLayer && [animatedLayer isKindOfClass:[VideoAnimationLayer class]])
            {
                [animatedLayers addObject:(id)animatedLayer];
            }
        }
    }
    
    if (animatedLayers && [animatedLayers count] > 0)
    {
        for (CALayer *animatedLayer in animatedLayers)
        {
            [parentLayer addSublayer:animatedLayer];
        }
    }
    
    // Video composition.
    AVMutableVideoCompositionInstruction *mainInstruciton = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    mainInstruciton.timeRange = CMTimeRangeMake(kCMTimeZero, [videoAsset duration]);
    
    // Fix orientation issue
    AVMutableVideoCompositionLayerInstruction *layerInstruciton = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:assetVideoTrack];
    
    CGFloat rate;
    CGFloat renderW = MIN(videoSize.width, videoSize.height);
    rate = renderW / MIN(assetVideoTrack.naturalSize.width, assetVideoTrack.naturalSize.height);
    CGAffineTransform layerTransform = CGAffineTransformMake(assetVideoTrack.preferredTransform.a, assetVideoTrack.preferredTransform.b, assetVideoTrack.preferredTransform.c, assetVideoTrack.preferredTransform.d, assetVideoTrack.preferredTransform.tx * rate, assetVideoTrack.preferredTransform.ty * rate);
    layerTransform = CGAffineTransformConcat(layerTransform, CGAffineTransformMake(1, 0, 0, 1, 0, -(assetVideoTrack.naturalSize.width - assetVideoTrack.naturalSize.height) / 2.0));
    layerTransform = CGAffineTransformScale(layerTransform, rate, rate);
    [layerInstruciton setTransform:layerTransform atTime:kCMTimeZero];
    [layerInstruciton setOpacity:0.0 atTime:[videoAsset duration]];
    
    mainInstruciton.layerInstructions = [NSArray arrayWithObject:layerInstruciton];
    
    AVMutableVideoComposition *mainComposition = [AVMutableVideoComposition videoComposition];
    mainComposition.instructions = [NSArray arrayWithObject:mainInstruciton]; //@[mainInstruciton];
    mainComposition.animationTool = [AVVideoCompositionCoreAnimationTool videoCompositionCoreAnimationToolWithPostProcessingAsVideoLayer:videoLayer inLayer:parentLayer];
    mainComposition.frameDuration = CMTimeMake(1, 30);
    mainComposition.renderSize = videoSize;
    
    // Make a video composition.
//    AVMutableVideoCompositionInstruction *passThroughInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
//    passThroughInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, [videoAsset duration]);
//    
//    AVMutableVideoCompositionLayerInstruction *passThroughLayer = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:assetVideoTrack];
//    passThroughInstruction.layerInstructions = [NSArray arrayWithObject:passThroughLayer];
//    
//    AVMutableVideoComposition *videoComposition = [AVMutableVideoComposition videoComposition];
//    videoComposition.instructions = [NSArray arrayWithObject:passThroughInstruction];
//    videoComposition.animationTool = [AVVideoCompositionCoreAnimationTool videoCompositionCoreAnimationToolWithPostProcessingAsVideoLayer:videoLayer inLayer:parentLayer];
//    videoComposition.frameDuration = CMTimeMake(1, 30); // 30 fps
//    videoComposition.renderSize =  videoSize;
    
    NSString *exportPath = [self getOutputFilePath];
    NSURL *exportURL = [NSURL fileURLWithPath:[self returnFormatString:exportPath]];
    
    // Delete old file
    unlink([exportPath UTF8String]);
    
    if (animatedLayers)
    {
        [animatedLayers removeAllObjects];
        animatedLayers = nil;
    }
    
    _exportSession = [[AVAssetExportSession alloc] initWithAsset:mixComposition presetName:AVAssetExportPresetHighestQuality];
    [_exportSession setOutputFileType:[[[UIDevice currentDevice] systemVersion] floatValue] >= 6.0 ? AVFileTypeMPEG4 : AVFileTypeQuickTimeMovie];
    [_exportSession setOutputURL:exportURL];
    [_exportSession setShouldOptimizeForNetworkUse:YES];
    
    if (mainComposition)
    {
        _exportSession.videoComposition = mainComposition;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        // Progress monitor
        _timerEffect = [NSTimer scheduledTimerWithTimeInterval:0.3f
                                                        target:self
                                                      selector:@selector(retrievingExportProgress)
                                                      userInfo:nil
                                                       repeats:YES];
    });
    
    __block typeof(self) blockSelf = self;
    [blockSelf.exportSession exportAsynchronouslyWithCompletionHandler:^(void) {
        switch ([blockSelf.exportSession status])
        {
            case AVAssetExportSessionStatusCompleted:
            {
                [[NSFileManager defaultManager] removeItemAtPath:videoPath error:nil];
                
                // Close timer
                [blockSelf.timerEffect invalidate];
                blockSelf.timerEffect = nil;

                // Save video to Album
                [self writeExportedVideoToAssetsLibrary:exportPath];
                
                NSLog(@"Export Successful: %@", exportPath);
                break;
            }
                
            case AVAssetExportSessionStatusFailed:
            {
                // Close timer
                [blockSelf.timerEffect invalidate];
                blockSelf.timerEffect = nil;

                if (self.finishVideoBlock)
                {
                    self.finishVideoBlock(NO, GBLocalizedString(@"MsgConvertFailed"));
                }
                
                NSLog(@"Export failed: %@, %@", [[blockSelf.exportSession error] localizedDescription], [blockSelf.exportSession error]);
                break;
            }
                
            case AVAssetExportSessionStatusCancelled:
            {
                NSLog(@"Canceled: %@", blockSelf.exportSession.error);
                break;
            }
            default:
                break;
        }
    }];
}

// Convert 'space' char
- (NSString *)returnFormatString:(NSString *)str
{
    return [str stringByReplacingOccurrencesOfString:@" " withString:@""];
}

@end
