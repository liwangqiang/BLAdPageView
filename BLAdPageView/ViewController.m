//
//  ViewController.m
//  BLAdPageView
//
//  Created by 李王强 on 15/5/27.
//  Copyright (c) 2015年 personal. All rights reserved.
//

#import "ViewController.h"
#import "BLAdPageView.h"
#import "BLImagePlayerView.h"

@interface ViewController ()<BLImagePlayerViewDelegate>

@property (weak, nonatomic) IBOutlet UIView *adPageViewContainer;
@property (weak, nonatomic) IBOutlet BLImagePlayerView *imagePlayer;
@property (strong, nonatomic)BLAdPageView *adPageView;


@property(nonatomic, strong)NSArray *images;
@end

@implementation ViewController

- (void)viewDidLoad
{
  [super viewDidLoad];
  [self.view addSubview:self.adPageView];
  
  //configure 广告页
  [self.imagePlayer configureWithCount:self.images.count delegate:self];
  self.imagePlayer.scrollInterval = 3.0f;
  self.imagePlayer.autoScroll = YES;
  // adjust pageControl position
  self.imagePlayer.pageControlPosition = ICPageControlPosition_BottomCenter;
  // hide pageControl or not
  self.imagePlayer.hidePageControl = NO;
  self.imagePlayer.imagePlayerViewDelegate = self;
}

-(void)viewDidLayoutSubviews
{
  [super viewDidLayoutSubviews];
  
  self.adPageView.frame = self.adPageViewContainer.frame;
  [self.view layoutIfNeeded];
}

-(void)imagePlayerView:(BLImagePlayerView *)imagePlayerView loadImageForImageView:(UIImageView *)imageView index:(NSInteger)index
{
  imageView.image = [self.images objectAtIndex:index];
}


-(BLAdPageView *)adPageView
{
  if (!_adPageView) {
    
    _adPageView = [[BLAdPageView alloc] init];
    _adPageView.iDisplayTime = 2;
    [_adPageView startAdsWithBlock:@[@"m1",@"m2",@"m3",@"m4",@"m5"] block:^(NSInteger clickIndex){
      NSLog(@"%d",(int)clickIndex);
    }];
  }
  return _adPageView;
}

-(NSArray *)images
{
  if (!_images) {
    _images = @[[UIImage imageNamed:@"m1"],
                [UIImage imageNamed:@"m2"],
                [UIImage imageNamed:@"m3"],
                [UIImage imageNamed:@"m4"],
                [UIImage imageNamed:@"m5"]];
  }
  return _images;
}
@end
