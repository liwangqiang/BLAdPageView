//
//  BLAdPageView.m
//  BLAdPageView
//
//  Created by 李王强 on 15/5/27.
//  Copyright (c) 2015年 personal. All rights reserved.
//


#import "BLAdPageView.h"

@interface BLAdPageView()<UIScrollViewDelegate>
@property (nonatomic,assign)int                 indexShow;
@property (nonatomic,copy)NSArray               *arrImage;
@property (nonatomic,strong)UIScrollView        *scView;
@property (nonatomic,strong)UIImageView         *imgPrev;
@property (nonatomic,strong)UIImageView         *imgCurrent;
@property (nonatomic,strong)UIImageView         *imgNext;
@property (nonatomic,strong)NSTimer             *myTimer;
@property (nonatomic,assign)JXBAdPageCallback   myBlock;
@end

@implementation BLAdPageView

- (id)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    [self setup];
  }
  return self;
}

- (void)setup {
  
  self.contentMode = UIViewContentModeRedraw;
  
  [self.scView addSubview:self.imgPrev];
  [self.scView addSubview:self.imgCurrent];
  [self.scView addSubview:self.imgNext];
  
  [self addSubview:self.scView];
  [self addSubview:self.pageControl];
 
}

-(void)layoutSubviews
{
  // 不使用autolayout布局
  CGSize pageSize = self.bounds.size;
  
  self.scView.frame = self.bounds;
  self.scView.contentSize = CGSizeMake(pageSize.width * 3, pageSize.height);
  
  self.imgPrev.frame = self.bounds;
  self.imgCurrent.frame = CGRectMake(pageSize.width, 0, pageSize.width, pageSize.height);
  self.imgNext.frame = CGRectMake(2 * pageSize.width, 0, pageSize.width, pageSize.height);
  
  self.pageControl.frame = CGRectMake((pageSize.width - self.pageControl.bounds.size.width)/2, pageSize.height - self.pageControl.bounds.size.height - 10, self.pageControl.bounds.size.width, self.pageControl.bounds.size.height);
}

/**
 *  启动函数
 *
 *  @param imageArray 图片数组
 *  @param block      click回调
 */
- (void)startAdsWithBlock:(NSArray*)imageArray block:(JXBAdPageCallback)block {
  if(imageArray.count <= 1)
    _scView.contentSize = CGSizeMake(self.bounds.size.width, self.bounds.size.height);
  _pageControl.numberOfPages = imageArray.count;
  _arrImage = imageArray;
  _myBlock = block;
  [self reloadImages];
}

/**
 *  点击广告
 */
- (void)tapAds
{
  if (_myBlock != NULL) {
    _myBlock(_indexShow);
  }
}

/**
 *  加载图片顺序
 */
- (void)reloadImages {
  if (_indexShow >= (int)_arrImage.count)
    _indexShow = 0;
  if (_indexShow < 0)
    _indexShow = (int)_arrImage.count - 1;
  int prev = _indexShow - 1;
  if (prev < 0)
    prev = (int)_arrImage.count - 1;
  int next = _indexShow + 1;
  if (next > _arrImage.count - 1)
    next = 0;
  _pageControl.currentPage = _indexShow;
  NSString* prevImage = [_arrImage objectAtIndex:prev];
  NSString* curImage = [_arrImage objectAtIndex:_indexShow];
  NSString* nextImage = [_arrImage objectAtIndex:next];
  if(_bWebImage)
  {
    if(_delegate && [_delegate respondsToSelector:@selector(setWebImage:imgUrl:)])
    {
      [_delegate setWebImage:_imgPrev imgUrl:prevImage];
      [_delegate setWebImage:_imgCurrent imgUrl:curImage];
      [_delegate setWebImage:_imgNext imgUrl:nextImage];
    }
    else
    {
      _imgPrev.image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:prevImage]]];
      _imgCurrent.image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:curImage]]];
      _imgNext.image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:nextImage]]];
    }
  }
  else
  {
    _imgPrev.image = [UIImage imageNamed:prevImage];
    _imgCurrent.image = [UIImage imageNamed:curImage];
    _imgNext.image = [UIImage imageNamed:nextImage];
  }
  [_scView scrollRectToVisible:CGRectMake(self.bounds.size.width, 0, self.bounds.size.width, self.bounds.size.height) animated:NO];
  
  if (_iDisplayTime > 0)
    [self startTimerPlay];
}

/**
 *  切换图片完毕事件
 *
 *  @param scrollView
 */
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
  if (_myTimer)
    [_myTimer invalidate];
  if (scrollView.contentOffset.x >=self.bounds.size.width*2)
    _indexShow++;
  else if (scrollView.contentOffset.x < self.bounds.size.width)
    _indexShow--;
  [self reloadImages];
}

- (void)startTimerPlay {
  _myTimer = [NSTimer scheduledTimerWithTimeInterval:_iDisplayTime target:self selector:@selector(doImageGoDisplay) userInfo:nil repeats:NO];
}

/**
 *  轮播图片
 */
- (void)doImageGoDisplay {
  [_scView scrollRectToVisible:CGRectMake(self.bounds.size.width * 2, 0, self.bounds.size.width, self.bounds.size.height) animated:YES];
  _indexShow++;
  [self performSelector:@selector(reloadImages) withObject:nil afterDelay:0.3];
}


-(UIScrollView *)scView
{
  if (!_scView) {
    _scView = [[UIScrollView alloc]init];
    _scView.delegate = self;
    _scView.pagingEnabled = YES;
    _scView.bounces = NO;
    _scView.showsHorizontalScrollIndicator = NO;
    _scView.showsVerticalScrollIndicator = NO;
    
    UITapGestureRecognizer* tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAds)];
    [_scView addGestureRecognizer:tap];
  }
  return _scView;
}


#pragma mark - Getter and Setter
-(UIImageView *)imgPrev
{
  if (!_imgPrev) {
    _imgPrev = [[UIImageView alloc] init];
  }
  return _imgPrev;
}

-(UIImageView *)imgCurrent
{
  if (!_imgCurrent) {
    _imgCurrent = [[UIImageView alloc]init];
  }
  return _imgCurrent;
}

-(UIImageView *)imgNext
{
  if (!_imgNext) {
    _imgNext = [[UIImageView alloc]init];
  }
  return _imgNext;
}

-(UIPageControl *)pageControl
{
  if (!_pageControl) {
    _pageControl = [[UIPageControl alloc] init];
    _pageControl.currentPageIndicatorTintColor = [UIColor redColor];
    _pageControl.pageIndicatorTintColor = [UIColor whiteColor];
  }
  return _pageControl;
}



@end
