//
//  MainViewController.h
//  AVFoundationDemo
//
//  Created by LT-MacbookPro on 17/6/15.
//  Copyright © 2017年 XFX. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger,RecordState){

    RecordStateInit = 0,
    RecordStateRecording,
    RecordStatePause,
    RecordStateFinsh
};

@interface MainViewController : UIViewController

@end
