//
//  CircleProgressView.h
//  AVFoundationDemo
//
//  Created by LT-MacbookPro on 17/6/16.
//  Copyright © 2017年 XFX. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CircleProgressView : UIView

- (instancetype)initWithFrame:(CGRect) frame;
-(void)updateProgressWithValue:(CGFloat)progress;
-(void)resetProgress;

@end
