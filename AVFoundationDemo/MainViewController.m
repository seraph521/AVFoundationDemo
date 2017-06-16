//
//  MainViewController.m
//  AVFoundationDemo
//
//  Created by LT-MacbookPro on 17/6/15.
//  Copyright © 2017年 XFX. All rights reserved.
//

#import "MainViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "CircleProgressView.h"
#import <AssetsLibrary/AssetsLibrary.h>

#define kScreenWidth [UIScreen mainScreen].bounds.size.width
#define kScreenHeight [UIScreen mainScreen].bounds.size.height

@interface MainViewController ()<AVCaptureFileOutputRecordingDelegate>

@property(nonatomic,strong) AVCaptureSession * session;
//当前设备
@property (nonatomic,strong) AVCaptureDevice * currentDevice;
//输入源
@property (nonatomic,strong) AVCaptureDeviceInput * videoInput;
//输入源
@property (nonatomic,strong) AVCaptureDeviceInput * audioInput;
//照片输出流
@property (nonatomic,strong) AVCaptureStillImageOutput * stillImageOutput;
//视频输出流
@property (nonatomic,strong) AVCaptureMovieFileOutput * movieFileOutput;
//预览图层
@property (nonatomic,strong) AVCaptureVideoPreviewLayer * previewLayer;

@property (strong,nonatomic)  UIImageView *focusCursor; //聚焦光标

@property (strong, nonatomic) UIView * timeView;

@property (strong, nonatomic) UILabel *timelabel;

@property (strong, nonatomic) NSTimer *timer;

@property (nonatomic, assign) CGFloat recordTime;

@property (strong, nonatomic) CircleProgressView * progressView;

@property (nonatomic, assign) RecordState recordState;



@end

@implementation MainViewController

- (UIImageView *)focusCursor{

    if(!_focusCursor ){
    
        _focusCursor = [[UIImageView alloc]initWithFrame:CGRectMake(100, 100, 50, 50)];
        _focusCursor.image = [UIImage imageNamed:@"focusImg"];
        _focusCursor.alpha = 0;
    }
    return _focusCursor;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //设置背景色
    [self.view setBackgroundColor:[UIColor blackColor]];
    //初始化音视频组件
    [self initAVCaptureComponents];
    //设置手动对焦
    [self setupManualFoucs];
    //设置按钮
    [self setupButtons];
}

- (void)initAVCaptureComponents{

    // 0 创建捕获会话
    self.session = [[AVCaptureSession alloc] init];
    if([self.session canSetSessionPreset:AVCaptureSessionPresetHigh]){
       
        [self.session setSessionPreset:AVCaptureSessionPresetHigh];
    }
    // 1 添加视频输入
    // 1.1 获取视频输入设备(摄像头)
    self.currentDevice = [self deviceWithMediaType:AVMediaTypeVideo preferringPosition:AVCaptureDevicePositionBack];
    // 视频 HDR (高动态范围图像)
    // self.currentDevice = YES;
    // 设置最大，最小帧速率
    //self.currentDevice = CMTimeMake(1, 60);
    // 1.2 创建视频输入源
    NSError *error=nil;
    self.videoInput= [[AVCaptureDeviceInput alloc] initWithDevice:self.currentDevice error:&error];
    // 1.3 将视频输入源添加到会话
    if ([self.session canAddInput:self.videoInput]) {
        [self.session addInput:self.videoInput];
        
    }
    // 2 音频的输入
    NSError *audioError=nil;
    AVCaptureDevice *audioCaptureDevice=[[AVCaptureDevice devicesWithMediaType:AVMediaTypeAudio] firstObject];
    self.audioInput = [AVCaptureDeviceInput deviceInputWithDevice:audioCaptureDevice error:&audioError];
    // 2.3 将音频输入源添加到会话
    if ([self.session canAddInput:self.audioInput]) {
        [self.session addInput:self.audioInput];
    }
    // 3 添加视频录制输出
    self.movieFileOutput = [[AVCaptureMovieFileOutput alloc]init];
    // 3.2设置输出对象的一些属性
    AVCaptureConnection *captureConnection=[self.movieFileOutput connectionWithMediaType:AVMediaTypeVideo];
    //设置防抖
    //视频防抖 是在 iOS 6 和 iPhone 4S 发布时引入的功能。到了 iPhone 6，增加了更强劲和流畅的防抖模式，被称为影院级的视频防抖动。相关的 API 也有所改动 (目前为止并没有在文档中反映出来，不过可以查看头文件）。防抖并不是在捕获设备上配置的，而是在 AVCaptureConnection 上设置。由于不是所有的设备格式都支持全部的防抖模式，所以在实际应用中应事先确认具体的防抖模式是否支持：
    if ([captureConnection isVideoStabilizationSupported ]) {
        captureConnection.preferredVideoStabilizationMode=AVCaptureVideoStabilizationModeAuto;
    }
    //预览图层和视频方向保持一致
   // captureConnection.videoOrientation = [self.previewLayer connection].videoOrientation;
    if([self.session canAddOutput:self.movieFileOutput]){
        [self.session addOutput:self.movieFileOutput];
    }
    
    //初始化预览图层
    self.previewLayer = [[AVCaptureVideoPreviewLayer alloc]initWithSession:self.session];
    [self.previewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    self.previewLayer.connection.videoOrientation = AVCaptureVideoOrientationPortrait;
    self.previewLayer.frame = self.view.bounds;
    [self.view.layer addSublayer:self.previewLayer];
    
    [self.session startRunning];
}

- (void)setupManualFoucs{

    [self.view addSubview:self.focusCursor];
    UITapGestureRecognizer *tapGesture= [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tapScreen:)];
    [self.view addGestureRecognizer:tapGesture];
}

-(void)tapScreen:(UITapGestureRecognizer *)tapGesture{

    CGPoint point = [tapGesture locationInView:self.view];
    //将UI坐标转化为摄像头坐标
    CGPoint cameraPoint= [self.previewLayer captureDevicePointOfInterestForPoint:point];
    [self setFocusCursorWithPoint:point];
    [self focusAtPoint:cameraPoint];
}

-(void)setFocusCursorWithPoint:(CGPoint)point{
    self.focusCursor.center=point;
    self.focusCursor.transform=CGAffineTransformMakeScale(1.5, 1.5);
    self.focusCursor.alpha=1.0;
    [UIView animateWithDuration:1.0 animations:^{
        self.focusCursor.transform=CGAffineTransformIdentity;
    } completion:^(BOOL finished) {
        self.focusCursor.alpha=0;
        
    }];
}

//对某一点进行对焦
- (void) focusAtPoint:(CGPoint)point{

    AVCaptureDevice *device = self.currentDevice;
    
    //还原曝光值
    [self resetExposureMode];
    
    if (device.isFocusPointOfInterestSupported && [device isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
        
        [self changeDeviceProperty:^(AVCaptureDevice *captureDevice) {
            device.focusPointOfInterest = point;
            device.focusMode = AVCaptureFocusModeAutoFocus;
        }];

    }

}


//修改设备属性需要先锁定

- (void)changeDeviceProperty:(void(^)(AVCaptureDevice * captureDevice))propertyChange{

    AVCaptureDevice *captureDevice= [self.videoInput device];
    NSError *error;
    //注意改变设备属性前一定要首先调用lockForConfiguration:调用完之后使用unlockForConfiguration方法解锁
    if ([captureDevice lockForConfiguration:&error]) {
        propertyChange(captureDevice);
        [captureDevice unlockForConfiguration];
    }else{
        NSLog(@"设置设备属性过程发生错误，错误信息：%@",error.localizedDescription);
    }
}


- (void)resetExposureMode
{
    NSError * error;
    
    if ([self.currentDevice lockForConfiguration:&error] ) {
        if ([self.currentDevice isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure] ) {
            self.currentDevice.exposureMode = AVCaptureExposureModeContinuousAutoExposure;
        }
        [self.currentDevice unlockForConfiguration];
    }else {
        NSLog( @"Could not lock device for configuration: %@", error );
    }
}

- (void)setupButtons{
    
    //录制圆形进度条
    CircleProgressView * progressView = [[CircleProgressView alloc] initWithFrame:CGRectMake(kScreenWidth / 2 - 30, kScreenHeight - 85, 60, 60)];
    progressView.backgroundColor = [UIColor clearColor];
    self.progressView = progressView;
    [self.view addSubview:progressView];
    //开始录制按钮
    UIButton * recodeBtn = [[UIButton alloc] init];
    [recodeBtn setBackgroundColor:[UIColor redColor]];
    recodeBtn.frame = CGRectMake(kScreenWidth / 2 - 25, kScreenHeight - 80, 50, 50);
    recodeBtn.layer.cornerRadius = 50 / 2;
    recodeBtn.layer.masksToBounds = YES;
    [recodeBtn addTarget:self action:@selector(startRecode) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:recodeBtn];
    //切换摄像头按钮
    
    //闪光灯按钮
    
    //录制时间
    self.timeView = [[UIView alloc] init];
    self.timeView.frame = CGRectMake((kScreenWidth - 100)/2, 16, 100, 34);
    self.timeView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.7];
    self.timeView.layer.cornerRadius = 4;
    self.timeView.layer.masksToBounds = YES;
    [self.view addSubview:self.timeView];
    self.timeView.hidden = YES;
    
    UIView *redPoint = [[UIView alloc] init];
    redPoint.frame = CGRectMake(0, 0, 6, 6);
    redPoint.layer.cornerRadius = 3;
    redPoint.layer.masksToBounds = YES;
    redPoint.center = CGPointMake(25, 17);
    redPoint.backgroundColor = [UIColor redColor];
    [self.timeView addSubview:redPoint];
    
    self.timelabel =[[UILabel alloc] init];
    self.timelabel.font = [UIFont systemFontOfSize:13];
    self.timelabel.textColor = [UIColor whiteColor];
    self.timelabel.frame = CGRectMake(40, 8, 40, 28);
    [self.timeView addSubview:self.timelabel];
}

//开始录制
- (void)startRecode{
    
    [self writeDataTofile];
}

- (void)writeDataTofile{
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)lastObject]; //@"/Users/lt-macbookpro/Desktop/video";//[self createVideoFilePath];
    NSString *videoName = [NSString stringWithFormat:@"%@.mp4", [NSUUID UUID].UUIDString];
    NSString *videopath = [path stringByAppendingPathComponent:videoName];
    NSURL *  videoUrl = [NSURL fileURLWithPath:videopath];
    [self.movieFileOutput startRecordingToOutputFileURL:videoUrl recordingDelegate:self];
}


#pragma mark - AVCaptureFileOutputRecordingDelegate

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didStartRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray *)connections{
    
    self.timeView.hidden = NO;
    self.recordState = RecordStateRecording;
      self.timer = [NSTimer scheduledTimerWithTimeInterval:TIMER_INTERVAL target:self selector:@selector(refreshTimeLabel) userInfo:nil repeats:YES];
}

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error
{
    
    //if ([XCFileManager isExistsAtPath:[self.videoUrl path]]) {
        
        self.recordState = RecordStateFinsh;
        //剪裁成正方形
        //[self cutVideoWithFinished:nil];
        
   // }
    ALAssetsLibrary *assetsLibrary=[[ALAssetsLibrary alloc]init];
    [assetsLibrary writeVideoAtPathToSavedPhotosAlbum:outputFileURL completionBlock:^(NSURL *assetURL, NSError *error) {
        if (error) {
            NSLog(@"保存视频到相簿过程中发生错误，错误信息：%@",error.localizedDescription);
        }
    
        NSLog(@"成功保存视频到相簿.");
    }];
    
}


- (void)refreshTimeLabel{

    _recordTime += TIMER_INTERVAL;

    [self.progressView updateProgressWithValue:_recordTime/RECORD_MAX_TIME];
    self.timelabel.text = [self changeToVideotime:_recordTime ];
    [self.timelabel sizeToFit];
    if (_recordTime > RECORD_MAX_TIME) {
        [self stopRecord];
    }
}

- (NSString *)changeToVideotime:(CGFloat)videocurrent {
    
    return [NSString stringWithFormat:@"%02li:%02li",lround(floor(videocurrent/60.f)),lround(floor(videocurrent/1.f))%60];
    
}

- (void)stopRecord
{
    [self.movieFileOutput stopRecording];
    [self.session stopRunning];
    [self.timer invalidate];
    self.timer = nil;
}
#pragma mark - 获取置顶位置的摄像头

- (AVCaptureDevice *)deviceWithMediaType:(NSString *)mediaType preferringPosition:(AVCaptureDevicePosition)position{

    NSArray * devices = [AVCaptureDevice devicesWithMediaType:mediaType];
    AVCaptureDevice * captureDevice = devices.firstObject;
    
    for ( AVCaptureDevice *device in devices ) {
        if ( device.position == position ) {
            captureDevice = device;
            break;
        }
    }
    return captureDevice;
}


@end
