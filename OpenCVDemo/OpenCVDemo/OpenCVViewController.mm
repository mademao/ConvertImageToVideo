//
//  OpenCVViewController.m
//  OpenCVDemo
//
//  Created by mademao on 2019/1/9.
//  Copyright © 2019 mademao. All rights reserved.
//

#ifdef __cplusplus
#import <opencv2/opencv.hpp>
#import <opencv2/videoio/cap_ios.h>
#endif
#import "OpenCVViewController.h"

@interface OpenCVViewController () <CvVideoCameraDelegate>

@property (nonatomic, strong) CvVideoCamera *videoCamera;
@property (nonatomic, strong) UIImageView *imageView;

@property (nonatomic, strong) UIImageView *showImageView;

@end

@implementation OpenCVViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
//    self.imageView = [[UIImageView alloc] initWithFrame:CGRectZero];
//    self.imageView.backgroundColor = [UIColor whiteColor];
//    [self.view addSubview:self.imageView];
    
    self.imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 150, 200)];
    self.imageView.backgroundColor = [UIColor clearColor];
    self.imageView.layer.backgroundColor = [UIColor clearColor].CGColor;
    self.imageView.layer.borderColor = [UIColor blackColor].CGColor;
    self.imageView.layer.borderWidth = 1.0;
    self.imageView.center = CGPointMake(self.view.frame.size.width / 4.0, 350);
    self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.view addSubview:self.imageView];
    
    self.showImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 150, 200)];
    self.showImageView.backgroundColor = [UIColor clearColor];
    self.imageView.layer.backgroundColor = [UIColor clearColor].CGColor;
    self.showImageView.layer.borderColor = [UIColor blackColor].CGColor;
    self.showImageView.layer.borderWidth = 1.0;
    self.showImageView.center = CGPointMake(self.view.frame.size.width / 4.0 * 3, 350);
    self.showImageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.view addSubview:self.showImageView];
    
    self.videoCamera = [[CvVideoCamera alloc] initWithParentView:self.imageView];
    self.videoCamera.delegate = self;
    self.videoCamera.defaultAVCaptureVideoOrientation = AVCaptureVideoOrientationPortrait;
    self.videoCamera.defaultAVCaptureDevicePosition = AVCaptureDevicePositionBack;
    self.videoCamera.defaultAVCaptureSessionPreset = AVCaptureSessionPreset640x480;
    self.videoCamera.defaultFPS = 30;
    self.videoCamera.recordVideo = YES;
    self.videoCamera.rotateVideo = YES;
    
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.videoCamera start];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.videoCamera stop];
}


#pragma marl - CvVideoCameraDelegate

- (void)processImage:(cv::Mat &)image
{
    cv::Mat gray;
    // 将图像转换为灰度显示
    cv::cvtColor(image, gray, cv::COLOR_BGR2GRAY);
    // 应用高斯滤波器去除小的边缘
    cv::GaussianBlur(gray, gray, cv::Size(5, 5), 1.2, 1.2);
    // 计算与画布边缘
    cv::Mat edges;
    cv::Canny(gray, edges, 0, 50);
    //将image的颜色空间从BGR调整为RGB
    cv::cvtColor(image, image, cv::COLOR_BGR2RGB);
    // 使用白色填充
    image.setTo(cv::Scalar(255, 255, 255, 255));
    // 修改边缘颜色
    image.setTo(cv::Scalar(0, 128, 255, 255), edges);
    
    dispatch_sync(dispatch_get_main_queue(), ^{
        self.showImageView.image = [OpenCVViewController UIImageFromCVMat:image];
    });
}

+ (UIImage *)UIImageFromCVMat:(cv::Mat)cvMat
{
    NSData *data = [NSData dataWithBytes:cvMat.data length:cvMat.elemSize()*cvMat.total()];
    CGColorSpaceRef colorSpace;
    
    if (cvMat.elemSize() == 1) {
        colorSpace = CGColorSpaceCreateDeviceGray();
    } else {
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }
    
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    
    // Creating CGImage from cv::Mat
    CGImageRef imageRef = CGImageCreate(cvMat.cols,                                 //width
                                        cvMat.rows,                                 //height
                                        8,                                          //bits per component
                                        8 * cvMat.elemSize(),                       //bits per pixel
                                        cvMat.step[0],                            //bytesPerRow
                                        colorSpace,                                 //colorspace
                                        kCGImageAlphaNone|kCGBitmapByteOrderDefault,// bitmap info
                                        provider,                                   //CGDataProviderRef
                                        NULL,                                       //decode
                                        false,                                      //should interpolate
                                        kCGRenderingIntentDefault                   //intent
                                        );
    
    
    // Getting UIImage from CGImage
    UIImage *finalImage = [UIImage imageWithCGImage:imageRef scale:[UIScreen mainScreen].scale orientation:UIImageOrientationUp];
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    
    return finalImage;
}

@end
