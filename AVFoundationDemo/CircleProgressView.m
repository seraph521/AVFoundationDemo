//
//  CircleProgressView.m
//  AVFoundationDemo
//
//  Created by LT-MacbookPro on 17/6/16.
//  Copyright © 2017年 XFX. All rights reserved.
//

#import "CircleProgressView.h"

@interface CircleProgressView ()

@property(nonatomic,assign) CGFloat progress;

@property(nonatomic,strong) CAShapeLayer * backLayer;

@property(nonatomic,strong) CAShapeLayer * progressLayer;

@end

@implementation CircleProgressView

- (instancetype)initWithFrame:(CGRect)frame{

    self = [super initWithFrame:frame];
    
    if(self){
    
    }
    return self;
}

- (void)drawRect:(CGRect)rect{

    //绘制
    [self drawCycleProgress];
}

- (void)drawCycleProgress{

    //圆心
    CGPoint center = CGPointMake(self.frame.size.width / 2, self.frame.size.height / 2);
    //半径
    CGFloat radius = self.frame.size.width / 2;
    //开始角度
    CGFloat startA = -M_PI_2;
    //结束角度
    CGFloat endA = -M_PI_2 + M_PI * 2 * _progress;
    
    //不存在创建
    if(!_backLayer && self.frame.size.width > 0 && self.frame.size.height >0){
    
        _backLayer = [CAShapeLayer layer];
        _backLayer.frame = self.bounds;
        _backLayer.fillColor = [[UIColor clearColor] CGColor];
        _backLayer.strokeColor = [[UIColor whiteColor] CGColor];
        _backLayer.opacity = 1; //背景颜色的透明度
        _backLayer.lineCap = kCALineCapRound;
        _backLayer.lineWidth = 5;
        
        UIBezierPath * path = [UIBezierPath bezierPathWithArcCenter:center radius:radius startAngle:0 endAngle:2 * M_PI clockwise:YES];
        _backLayer.path = path.CGPath;
        [self.layer addSublayer:_backLayer];
    }
    
    //progressLayer
    _progressLayer = [CAShapeLayer layer];
    _progressLayer.frame = self.bounds;
    _progressLayer.fillColor = [[UIColor clearColor] CGColor];
    _progressLayer.strokeColor = [[UIColor orangeColor] CGColor];
    _progressLayer.opacity = 1; //背景颜色的透明度
    _progressLayer.lineCap = kCALineCapButt;
    _progressLayer.lineWidth = 5;
    UIBezierPath *path = [UIBezierPath bezierPathWithArcCenter:center radius:radius startAngle:startA endAngle:endA clockwise:YES];
    _progressLayer.path =[path CGPath];
    [self.layer addSublayer:_progressLayer];
}

-(void)updateProgressWithValue:(CGFloat)progress
{
    _progress = progress;
    _progressLayer.opacity = 0;
    [self setNeedsDisplay];
}

-(void)resetProgress
{
    [self updateProgressWithValue:0];
}

@end
