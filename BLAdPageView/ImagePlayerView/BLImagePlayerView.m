//
//  BLImagePlayerView.m
//  BLAdPageView
//
//  Created by 李王强 on 15/5/27.
//  Copyright (c) 2015年 personal. All rights reserved.
//

#import "BLImagePlayerView.h"

#define kStartTag   1000
#define kDefaultScrollInterval  2

@interface BLImagePlayerView() <UIScrollViewDelegate>

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, assign) NSInteger count;
@property (nonatomic, strong) NSTimer *autoScrollTimer;
@property (nonatomic, strong) NSMutableArray *pageControlConstraints;
@property (nonatomic, strong) NSMutableArray *scrollViewConstraints;
@property (nonatomic) UIEdgeInsets edgeInset;
@property (nonatomic, strong) UIPageControl *pageControl;

@end

@implementation BLImagePlayerView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self _init];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self _init];
    }
    return self;
}

-(void)awakeFromNib
{
    [self _init];
}

- (id)init
{
    self = [super init];
    if (self) {
        [self _init];
    }
    return self;
}

- (void)_init
{
    //bounds 改变时重绘
    self.contentMode = UIViewContentModeRedraw;
    
    self.translatesAutoresizingMaskIntoConstraints = NO;
    self.scrollInterval = kDefaultScrollInterval;
    
    // scrollview
    self.scrollView = [[UIScrollView alloc] init];
    [self addSubview:self.scrollView];
    
    self.scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    self.scrollView.pagingEnabled = YES;
    self.scrollView.bounces = NO;
    self.scrollView.showsHorizontalScrollIndicator = NO;
    self.scrollView.showsVerticalScrollIndicator = NO;
    self.scrollView.directionalLockEnabled = YES;
    
    self.scrollView.delegate = self;
    
    // UIPageControl
    self.pageControl = [[UIPageControl alloc] init];
    self.pageControl.translatesAutoresizingMaskIntoConstraints = NO;
    self.pageControl.numberOfPages = self.count;
    self.pageControl.currentPage = 0;
    [self addSubview:self.pageControl];
}


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
    
    CGFloat startX = self.scrollView.bounds.origin.x;
    CGFloat width = self.bounds.size.width - edgeInsets.left - edgeInsets.right;
    CGFloat height = self.bounds.size.height - edgeInsets.top - edgeInsets.bottom;
    
    for (int i = 0; i < count; i++) {
        startX = i * width;
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(startX, 0, width, height)];
        imageView.tag = kStartTag + i;
        imageView.contentMode = UIViewContentModeScaleToFill;
        imageView.userInteractionEnabled = YES;
        imageView.translatesAutoresizingMaskIntoConstraints = NO;
        [imageView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)]];
        
        
        [self.imagePlayerViewDelegate imagePlayerView:self loadImageForImageView:imageView index:i];
        
        [self.scrollView addSubview:imageView];
    }
    
    self.scrollView.contentSize = CGSizeMake(self.scrollView.frame.size.width * count, self.scrollView.frame.size.height);
    self.scrollView.contentInset = UIEdgeInsetsZero;
    
    if ([self.imagePlayerViewDelegate respondsToSelector:@selector(imagePlayerView:didSrollToIndex:)]) {
        
        [self.imagePlayerViewDelegate imagePlayerView:self didSrollToIndex:0];
    }
    
    [self setNeedsUpdateConstraints];
}

-(void)updateConstraints
{
    [self configureImageViewsContraints];
    [self configurePageControlConstraints];
    [self configureScrollViewConstraints];
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

- (void)handleTapGesture:(UIGestureRecognizer *)tapGesture
{
    UIImageView *imageView = (UIImageView *)tapGesture.view;
    NSInteger index = imageView.tag - kStartTag;
    
    if (self.imagePlayerViewDelegate && [self.imagePlayerViewDelegate respondsToSelector:@selector(imagePlayerView:didTapAtIndex:)]) {
        [self.imagePlayerViewDelegate imagePlayerView:self didTapAtIndex:index];
    }
}

#pragma mark - auto scroll
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



- (void)setHidePageControl:(BOOL)hidePageControl
{
    self.pageControl.hidden = hidePageControl;
}




#pragma mark - scroll delegate
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

#pragma mark - constraints

-(void)configureImageViewsContraints{
    
    NSMutableDictionary *viewsDictionary = [NSMutableDictionary dictionary];
    NSMutableArray *imageViewNames = [NSMutableArray array];
    [viewsDictionary setValue:self.scrollView forKey:@"scrollView"];
    
    for (int i = kStartTag; i < kStartTag + self.count; i++) {
        
        
        NSString *imageViewName = [NSString stringWithFormat:@"imageView%d", i - kStartTag];
        [imageViewNames addObject:imageViewName];
        
        UIImageView *imageView = (UIImageView *)[self.scrollView viewWithTag:i];
        [viewsDictionary setObject:imageView forKey:imageViewName];
        
        
        //删除旧的
        [imageView removeConstraints:imageView.constraints];
        
        [imageView addConstraint:[NSLayoutConstraint constraintWithItem:imageView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:self.bounds.size.height]];
        
    }
    
    if (self.count) {
        
        [self.scrollView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"V:|-0-[%@]-0-|", [imageViewNames objectAtIndex:0]]
                                                                                options:kNilOptions
                                                                                metrics:nil
                                                                                  views:viewsDictionary]];
        
        NSMutableString *hConstraintString = [NSMutableString string];
        [hConstraintString appendString:@"H:|-0"];
        for (NSString *imageViewName in imageViewNames) {
            [hConstraintString appendFormat:@"-[%@(==scrollView)]-0",imageViewName];
        }
        [hConstraintString appendString:@"-|"];
        
        [self.scrollView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:hConstraintString
                                                                                options:NSLayoutFormatAlignAllTop
                                                                                metrics:nil
                                                                                  views:viewsDictionary]];
    }
    
}

- (void)configurePageControlConstraints
{
    [self removeConstraints:self.pageControlConstraints];
    [self addConstraints:self.pageControlConstraints];
    
}

-(void)configureScrollViewConstraints
{
    [self removeConstraints:self.scrollViewConstraints];
    [self addConstraints:self.scrollViewConstraints];
}

-(NSMutableArray *)pageControlConstraints
{
    if (!_pageControlConstraints) {
        
        _pageControlConstraints = [[NSMutableArray alloc]init];
        
        NSString *vFormat = nil;
        NSString *hFormat = nil;
        
        
        switch (self.pageControlPosition) {
            case ICPageControlPosition_TopLeft: {
                vFormat = @"V:|-0-[pageControl]";
                hFormat = @"H:|-[pageControl]";
                break;
            }
                
            case ICPageControlPosition_TopCenter: {
                vFormat = @"V:|-0-[pageControl]";
                hFormat = @"H:|[pageControl]|";
                break;
            }
                
            case ICPageControlPosition_TopRight: {
                vFormat = @"V:|-0-[pageControl]";
                hFormat = @"H:[pageControl]-|";
                break;
            }
                
            case ICPageControlPosition_BottomLeft: {
                vFormat = @"V:[pageControl]-0-|";
                hFormat = @"H:|-[pageControl]";
                break;
            }
                
            case ICPageControlPosition_BottomCenter: {
                vFormat = @"V:[pageControl]-0-|";
                hFormat = @"H:|[pageControl]|";
                break;
            }
                
            case ICPageControlPosition_BottomRight: {
                vFormat = @"V:[pageControl]-0-|";
                hFormat = @"H:[pageControl]-|";
                break;
            }
                
            default:
                break;
        }
        
        
        NSArray *pageControlVConstraints = [NSLayoutConstraint constraintsWithVisualFormat:vFormat
                                                                                   options:kNilOptions
                                                                                   metrics:nil
                                                                                     views:@{@"pageControl": self.pageControl}];
        
        NSArray *pageControlHConstraints = [NSLayoutConstraint constraintsWithVisualFormat:hFormat
                                                                                   options:kNilOptions
                                                                                   metrics:nil
                                                                                     views:@{@"pageControl": self.pageControl}];
        [_pageControlConstraints addObjectsFromArray:pageControlVConstraints];
        [_pageControlConstraints addObjectsFromArray:pageControlHConstraints];
        
        
    }
    return _pageControlConstraints;
    
}



-(NSMutableArray *)scrollViewConstraints
{
    if (!_scrollViewConstraints) {
        
        _scrollViewConstraints = [[NSMutableArray alloc]init];
        
        [_scrollViewConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"V:|-%d-[scrollView]-%d-|", (int)self.edgeInset.top, (int)self.edgeInset.bottom]
                                                                                            options:kNilOptions
                                                                                            metrics:nil
                                                                                              views:@{@"scrollView": self.scrollView}]];
        [_scrollViewConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"H:|-%d-[scrollView]-%d-|", (int)self.edgeInset.left, (int)self.edgeInset.right]
                                                                                            options:kNilOptions
                                                                                            metrics:nil
                                                                                              views:@{@"scrollView": self.scrollView}]];
    }
    
    return _scrollViewConstraints;
    
}

@end

