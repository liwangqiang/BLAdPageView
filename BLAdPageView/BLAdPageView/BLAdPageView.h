//
//  BLAdPageView.h
//  BLAdPageView
//
//  Created by 李王强 on 15/5/27.
//  Copyright (c) 2015年 personal. All rights reserved.
//


#import <UIKit/UIKit.h>

@class BLAdPageView;
typedef void (^JXBAdPageCallback)(NSInteger clickIndex);

@protocol JXBAdPageViewDelegate <NSObject>
/**
 *  加载网络图片使用回调自行调用SDImage
 *
 *  @param imgView
 *  @param imgUrl
 */
- (void)setWebImage:(UIImageView*)imgView imgUrl:(NSString*)imgUrl;
@end

@interface BLAdPageView : UIView
@property(nonatomic,assign)NSInteger                iDisplayTime; //广告图片轮播时停留的时间，默认0秒不会轮播
@property(nonatomic,assign)BOOL                     bWebImage; //设置是否为网络图片
@property(nonatomic,strong)UIPageControl            *pageControl;
@property(nonatomic,assign)id<JXBAdPageViewDelegate>  delegate;

/**
 *  启动函数
 *
 *  @param imageArray 设置图片数组
 *  @param block      block，回调点击
 */
- (void)startAdsWithBlock:(NSArray*)imageArray block:(JXBAdPageCallback)block;
@end
