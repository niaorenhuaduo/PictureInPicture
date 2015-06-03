//
//  ExportEffects
//  PictureInPicture
//
//  Created by Johnny Xu on 5/30/15.
//  Copyright (c) 2015 Future Studio. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

typedef void (^SRFinishVideoBlock)(BOOL success, id result);
typedef void (^SRExportProgressBlock)(NSNumber *percentage);

@interface ExportEffects : NSObject

@property (copy, nonatomic) SRFinishVideoBlock finishVideoBlock;
@property (copy, nonatomic) SRExportProgressBlock exportProgressBlock;


+ (ExportEffects *)sharedInstance;

- (void)initGifArray:(NSMutableArray *)gifs withVideoArray:(NSMutableArray *)videos;
- (void)addEffectToVideo:(NSString *)videoFilePath;
- (void)writeExportedVideoToAssetsLibrary:(NSString *)outputPath;

@end
