//
//  BLImagePlayerView.m
//  BLAdPageView
//
//  Created by 李王强 on 15/5/27.
//  Copyright (c) 2015年 personal. All rights reserved.
//

#import "BLImagePlayerView.h"
#import "PureLayout.h"

#define kStartTag   1000
#define kDefaultScrollInterval  2

@interface BLImagePlayerView() <UIScrollViewDelegate>

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong)NSMutableArray *imageViews;
@property (nonatomic, strong) UIPageControl *pageControl;

@property (nonatomic, assign) NSInteger count;
@property (nonatomic, strong) NSTimer *autoScrollTimer;
@property (nonatomic) UIEdgeInsets edgeInset;

@property (nonatomic, strong) NSArray *pageControlConstraints;
@property (nonatomic, strong) NSArray *scrollViewConstraints;
@property (nonatomic, strong) NSArray *imageViewsConstraints;

@end

@implementation BLImagePlayerView

#pragma mark - Initialize
- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setup];
    }
    return self;
}

-(void)awakeFromNib
{
    [self setup];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}

#pragma mark - Set Up
- (void)setup
{
    //bounds 改变时重绘
    self.contentMode = UIViewContentModeRedraw;
    self.translatesAutoresizingMaskIntoConstraints = NO;
    self.scrollInterval = kDefaultScrollInterval;
    
    // scrollview
    self.scrollView = [UIScrollView newAutoLayoutView];
    self.scrollView.pagingEnabled = YES;
    self.scrollView.bounces = NO;
    self.scrollView.showsHorizontalScrollIndicator = NO;
    self.scrollView.showsVerticalScrollIndicator = NO;
    self.scrollView.directionalLockEnabled = YES;
    self.scrollView.delegate = self;
    
    // UIPageControl
    self.pageControl = [UIPageControl newAutoLayoutView];
    self.pageControl.numberOfPages = self.count;
    self.pageControl.currentPage = 0;
    
    [self addSubview:self.scrollView];
    [self addSubview:self.pageControl];
    
    self.imageViews = [[NSMutableArray alloc]init];
}

#pragma mark - Public Method
// @deprecated use - (void)initWithCount:(NSInteger)count delegate:(id<ImagePlayerViewDelegate>)delegate instead
- (void)configureWithImageURLs:(NSArray *)imageURLs placeholder:(UIImage *)placeholder delegate:(id<BLImagePlayerViewDelegate>)delegate
{
    [self configureWithCount:imageURLs.count delegate:delegate edgeInsets:UIEdgeInsetsZero];
}

// @deprecated use - (void)initWithCount:(NSInteger)count delegate:(id<ImagePlayerViewDelegate>)delegate edgeInsets:(UIEdgeInsets)edgeInsets instead
- (void)configureWithImageURLs:(NSArray *)imageURLs placeholder:(UIImage *)placeholder delegate:(id<BLImagePlayerViewDelegate>)delegate edgeInsets:(UIEdgeInsets)edgeInsets
{
    [self configureWithCount:imageURLs.count delegate:delegate edgeInsets:edgeInsets];
}

- (void)configureWithCount:(NSInteger)count delegate:(id<BLImagePlayerViewDelegate>)delegate
{
    [self configureWithCount:count delegate:delegate edgeInsets:UIEdgeInsetsZero];
}

- (void)configureWithCount:(NSInteger)count delegate:(id<BLImagePlayerViewDelegate>)delegate edgeInsets:(UIEdgeInsets)edgeInsets
{
    self.count = count;
    self.imagePlayerViewDelegate = delegate;
    self.edgeInset = edgeInsets;
    
    if (count == 0) {
        return;
    }
    
    self.pageControl.numberOfPages = count;
    self.pageControl.currentPage = 0;
    
    for (int i = 0; i < count; i++) {
        
        UIImageView *imageView = [UIImageView newAutoLayoutView];
        imageView.contentMode = UIViewContentModeScaleToFill;
        imageView.userInteractionEnabled = YES;
        [imageView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)]];
        imageView.tag = kStartTag + i;
        [self.imagePlayerViewDelegate imagePlayerView:self loadImageForImageView:imageView index:i];
        
        [self.imageViews addObject:imageView];
        [self.scrollView addSubview:imageView];
    }
    
    self.scrollView.contentSize = CGSizeMake(self.scrollView.frame.size.width * count, self.scrollView.frame.size.height);
    self.scrollView.contentInset = UIEdgeInsetsZero;
    
    if ([self.imagePlayerViewDelegate respondsToSelector:@selector(imagePlayerView:didSrollToIndex:)]) {
        
        [self.imagePlayerViewDelegate imagePlayerView:self didSrollToIndex:0];
    }
    
    [self setNeedsUpdateConstraints];
}

- (void)setAutoScroll:(BOOL)autoScroll
{
    _autoScroll = autoScroll;
    
    if (autoScroll) {
        if (!self.autoScrollTimer || !self.autoScrollTimer.isValid) {
            self.autoScrollTimer = [NSTimer scheduledTimerWithTimeInterval:self.scrollInterval target:self selector:@selector(handleScrollTimer:) userInfo:nil repeats:YES];
        }
    } else {
        if (self.autoScrollTimer && self.autoScrollTimer.isValid) {
            [self.autoScrollTimer invalidate];
            self.autoScrollTimer = nil;
        }
    }
}

- (void)setScrollInterval:(NSUInteger)scrollInterval
{
    _scrollInterval = scrollInterval;
    
    if (self.autoScrollTimer && self.autoScrollTimer.isValid) {
        [self.autoScrollTimer invalidate];
        self.autoScrollTimer = nil;
    }
    
    self.autoScrollTimer = [NSTimer scheduledTimerWithTimeInterval:self.scrollInterval target:self selector:@selector(handleScrollTimer:) userInfo:nil repeats:YES];
}

- (void)setHidePageControl:(BOOL)hidePageControl
{
    self.pageControl.hidden = hidePageControl;
}

#pragma mark - Override
-(void)updateConstraints
{
    [self configureScrollViewConstraints];
    [self configureImageViewsContraints];
    [self configurePageControlConstraints];
    [super updateConstraints];
}

-(void)layoutSubviews
{
    [super layoutSubviews];
    
    //旋转或改变大小时，正常显示整张图片
#warning 当在播放过程中改变大小时，显示不正常
    NSInteger currentPage = self.pageControl.currentPage;
    CGSize scrollViewSize = self.scrollView.bounds.size;
    
    CGPoint visibleOffset = CGPointMake(scrollViewSize.width * currentPage, 0);
    self.scrollView.contentOffset = visibleOffset;
}

#pragma mark - Event Response
- (void)handleTapGesture:(UIGestureRecognizer *)tapGesture
{
    UIImageView *imageView = (UIImageView *)tapGesture.view;
    NSInteger index = imageView.tag - kStartTag;
    
    if (self.imagePlayerViewDelegate && [self.imagePlayerViewDelegate respondsToSelector:@selector(imagePlayerView:didTapAtIndex:)]) {
        [self.imagePlayerViewDelegate imagePlayerView:self didTapAtIndex:index];
    }
}

- (void)handleScrollTimer:(NSTimer *)timer
{
    if (self.count == 0) {
        return;
    }
    
    NSInteger currentPage = self.pageControl.currentPage;
    NSInteger nextPage = currentPage + 1;
    if (nextPage == self.count) {
        nextPage = 0;
    }
    
    BOOL animated = YES;
    //    if (nextPage == 0) {
    //        animated = NO;
    //    }
    
    UIImageView *imageView = (UIImageView *)[self.scrollView viewWithTag:(nextPage + kStartTag)];
    
    [self.scrollView scrollRectToVisible:imageView.frame animated:animated];
    
    self.pageControl.currentPage = nextPage;
}

#pragma mark - Scroll Delegate
-(void)scrollViewDidScroll:(UIScrollView *)scrollView{
    // disable v direction scroll
    if (scrollView.contentOffset.y > 0) {
        [scrollView setContentOffset:CGPointMake(scrollView.contentOffset.x, 0)];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    // when user scrolls manually, stop timer and start timer again to avoid next scroll immediatelly
    if (self.autoScrollTimer && self.autoScrollTimer.isValid) {
        [self.autoScrollTimer invalidate];
    }
    
    if (self.autoScroll) {
        self.autoScrollTimer = [NSTimer scheduledTimerWithTimeInterval:self.scrollInterval target:self selector:@selector(handleScrollTimer:) userInfo:nil repeats:YES];
    }
    
    // update UIPageControl
    CGRect visiableRect = CGRectMake(scrollView.contentOffset.x, scrollView.contentOffset.y, scrollView.bounds.size.width, scrollView.bounds.size.height);
    NSInteger currentIndex = 0;
    for (UIImageView *imageView in scrollView.subviews) {
        if ([imageView isKindOfClass:[UIImageView class]]) {
            if (CGRectContainsRect(visiableRect, imageView.frame)) {
                currentIndex = imageView.tag - kStartTag;
                break;
            }
        }
    }
    
    self.pageControl.currentPage = currentIndex;
    
    if ([self.imagePlayerViewDelegate respondsToSelector:@selector(imagePlayerView:didSrollToIndex:)]) {
        
        [self.imagePlayerViewDelegate imagePlayerView:self didSrollToIndex:currentIndex];
    }
}

#pragma mark - Private Method
-(void)configureImageViewsContraints
{
    [self.imageViewsConstraints autoRemoveConstraints];
    [self.imageViewsConstraints autoInstallConstraints];
}

- (void)configurePageControlConstraints
{
    [self.pageControlConstraints autoRemoveConstraints];
    [self.pageControlConstraints autoInstallConstraints];
}

-(void)configureScrollViewConstraints
{
    [self.scrollViewConstraints autoRemoveConstraints];
    [self.scrollViewConstraints autoInstallConstraints];
}


#pragma mark - Constraints
-(NSArray *)imageViewsConstraints
{
    if (!_imageViewsConstraints) {
        _imageViewsConstraints = [UIView autoCreateConstraintsWithoutInstalling:^{
            
            [[self.imageViews firstObject] autoPinEdgeToSuperviewEdge:ALEdgeLeft];
            
            UIImageView *previousView = nil;
            for (UIImageView *imageView in self.imageViews) {
                [imageView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.scrollView];
                [imageView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.scrollView];
                [imageView autoPinEdgeToSuperviewEdge:ALEdgeTop];
                [imageView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
                if (previousView) {
                    [imageView autoPinEdge:ALEdgeLeft toEdge:ALEdgeRight ofView:previousView];
                }
                previousView = imageView;
            }
            
            [[self.imageViews lastObject] autoPinEdgeToSuperviewEdge:ALEdgeRight];
            
            
        }];
    }
    return _imageViewsConstraints;
}
-(NSArray *)pageControlConstraints
{
    if (!_pageControlConstraints) {
        _pageControlConstraints = [UIView autoCreateConstraintsWithoutInstalling:^{
            
            switch (self.pageControlPosition) {
                case ICPageControlPosition_TopLeft: {
                    [self.pageControl autoPinEdgeToSuperviewEdge:ALEdgeTop];
                    [self.pageControl autoPinEdgeToSuperviewEdge:ALEdgeLeft];
                    break;
                }
                    
                case ICPageControlPosition_TopCenter: {
                    [self.pageControl autoPinEdgeToSuperviewEdge:ALEdgeTop];
                    [self.pageControl autoAlignAxisToSuperviewAxis:ALAxisVertical];
                    break;
                }
                    
                case ICPageControlPosition_TopRight: {
                    [self.pageControl autoPinEdgeToSuperviewEdge:ALEdgeTop];
                    [self.pageControl autoPinEdgeToSuperviewEdge:ALEdgeRight];
                    break;
                }
                    
                case ICPageControlPosition_BottomLeft: {
                    [self.pageControl autoPinEdgeToSuperviewEdge:ALEdgeBottom];
                    [self.pageControl autoPinEdgeToSuperviewEdge:ALEdgeLeft];
                    break;
                }
                    
                case ICPageControlPosition_BottomCenter: {
                    [self.pageControl autoPinEdgeToSuperviewEdge:ALEdgeBottom];
                    [self.pageControl autoAlignAxisToSuperviewAxis:ALAxisVertical];
                    break;
                }
                    
                case ICPageControlPosition_BottomRight: {
                    [self.pageControl autoPinEdgeToSuperviewEdge:ALEdgeBottom];
                    [self.pageControl autoPinEdgeToSuperviewEdge:ALEdgeRight];
                    break;
                }
                    
                default:
                    break;
            }
            
            
        }];
    }
    return _pageControlConstraints;
    
}

-(NSArray *)scrollViewConstraints
{
    if (!_scrollViewConstraints) {
        _scrollViewConstraints = [UIView autoCreateConstraintsWithoutInstalling:^{
            
            [self.scrollView autoPinEdgesToSuperviewEdgesWithInsets:self.edgeInset];
            
        }];
    }
    return _scrollViewConstraints;
    
}

@end

