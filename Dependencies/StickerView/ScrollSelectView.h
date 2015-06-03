
#import <UIKit/UIKit.h>

@protocol GLStoryboardSelectViewDelegate;

@interface GLStoryboardSelectView : UIView

@property (nonatomic, strong) UIScrollView  *storyboardView;
@property (nonatomic, assign) id<GLStoryboardSelectViewDelegate> delegateSelect;
@property (nonatomic, assign) NSInteger      picCount;
@property (nonatomic, assign) NSInteger      selectStyleIndex;

- (id)initWithFrameFromPuzzle:(CGRect)frame picCount:(NSInteger)picCount;
- (id)initWithFrameFromBorder:(CGRect)frame;
- (id)initWithFrameFromFilter:(CGRect)frame;
- (id)initWithFrameFromSticker:(CGRect)frame;
- (id)initWithFrameFromFace:(CGRect)frame;
- (id)initWithFrameFromBlurBackground:(CGRect)frame;

+ (void)getDefaultFilelist;

@end

@protocol GLStoryboardSelectViewDelegate <NSObject>

@optional
- (void)didSelectedStoryboardPicCount:(NSInteger)picCount styleIndex:(NSInteger)styleIndex;
- (void)didSelectedBorderIndex:(NSInteger)styleIndex;
- (void)didSelectedFilterIndex:(NSInteger)styleIndex;
- (void)didSelectedStickerIndex:(NSInteger)styleIndex;
- (void)didSelectedFaceIndex:(NSInteger)styleIndex;
- (void)didSelectedBlueBackgroundIndex:(NSInteger)styleIndex;

@end
