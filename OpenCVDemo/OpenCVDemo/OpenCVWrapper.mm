//
//  OpenCVWrapper.m
//  OpenCVDemo
//
//  Created by mademao on 2019/1/9.
//  Copyright © 2019 mademao. All rights reserved.
//

#ifdef __cplusplus
#import <opencv2/opencv.hpp>
#endif
#import "OpenCVWrapper.h"

using namespace std;
using namespace cv;

@implementation OpenCVWrapper

+ (void)createVideo
{
    
    
    cv::Mat src = cv::imread("/Users/mademao/Desktop/Image/0.jpg");
    char image_name[50];
    int isColor = 1;
    int fps = 20;
    int frameWidth = src.cols;
    int frameHeight = src.rows;
    
    cv::VideoWriter writer("/Users/mademao/Desktop/test.avi",
                           cv::VideoWriter::fourcc('M', 'J', 'P', 'G'),
                           fps,
                           cv::Size(frameWidth, frameHeight),
                           isColor);
    
    cout << "info:" << endl
         << "ff.avi" << endl
         << "Size:" << frameWidth << "*" << frameHeight << endl
         << "fps:" << fps << endl;

    for (NSInteger i = 0; i < 19; i++) {
        
        sprintf(image_name, "/Users/mademao/Desktop/Image/%zd.jpg", i);
        src = cv::imread(image_name);
        
        UIImage *image = [OpenCVWrapper UIImageFromCVMat:src];
        UIImage *image1 = [UIImage imageWithData:[NSData dataWithBytes:src.data length:(&src.dataend - &src.datastart + 1)]];
        
        if (src.empty()) {
            NSLog(@"加载完成");
            break;
        }
        cv::imshow("[src]", src);
//        cv::waitKey(5);
        writer.write(src);
    }
     

    /*
    Mat src=imread("/Users/mademao/Desktop/Image/0.jpg");
    char image_name[50];
    int isColor = 1;
    int fps = 10;
    int frameWidth = src.cols;
    int frameHeight = src.rows;
    
    VideoWriter writer("/Users/mademao/Desktop/test.avi", VideoWriter::fourcc('M', 'J', 'P', 'G'), fps,
                       cv::Size(frameWidth, frameHeight), 0);
    
    cout << "info:" << endl
    << "ff.avi" << endl
    << "Size:" << frameWidth << "*" << frameHeight << endl
    << "fps:" << fps << endl;
    
    
    for (int i = 0; i < 19; i++)
    {
        sprintf(image_name, "/Users/mademao/Desktop/Image/%d.jpg", i);
        src = imread(image_name);
        if (src.empty())
        {
            NSLog(@"全部图像加载完成！");
            break;
        }
//        imshow("【src】", src);
        waitKey(5);
        writer.write(src);
    }
    */
}

+ (UIImage *)changeImage:(UIImage *)image
{
    cv::Mat cvImage = [self cvMatFromUIImage:image];
    if (!cvImage.empty()) {
        cv::Mat gray;
        // 将图像转换为灰度显示
        cv::cvtColor(cvImage, gray, cv::COLOR_RGB2GRAY);
        // 应用高斯滤波器去除小的边缘
        cv::GaussianBlur(gray, gray, cv::Size(5, 5), 1.2, 1.2);
        // 计算与画布边缘
        cv::Mat edges;
        cv::Canny(gray, edges, 0, 50);
        // 使用白色填充
        cvImage.setTo(cv::Scalar::all(225));
        // 修改边缘颜色
        cvImage.setTo(cv::Scalar(0, 128, 255, 255), edges);
        return [self UIImageFromCVMat:cvImage];
    }
    return nil;
}


+ (cv::Mat)cvMatFromUIImage:(UIImage *)image
{
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    CGFloat cols = image.size.width;
    CGFloat rows = image.size.height;
    
    cv::Mat cvMat(rows, cols, CV_8UC4); // 8 bits per component, 4 channels (color channels + alpha)
    
    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // Pointer to  data
                                                    cols,                       // Width of bitmap
                                                    rows,                       // Height of bitmap
                                                    8,                          // Bits per component
                                                    cvMat.step[0],              // Bytes per row
                                                    colorSpace,                 // Colorspace
                                                    kCGImageAlphaNoneSkipLast |
                                                    kCGBitmapByteOrderDefault); // Bitmap info flags
    
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
    CGContextRelease(contextRef);
    
    return cvMat;
}

+ (cv::Mat)cvMatGrayFromUIImage:(UIImage *)image
{
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    CGFloat cols = image.size.width;
    CGFloat rows = image.size.height;
    
    cv::Mat cvMat(rows, cols, CV_8UC1); // 8 bits per component, 1 channels
    
    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // Pointer to data
                                                    cols,                       // Width of bitmap
                                                    rows,                       // Height of bitmap
                                                    8,                          // Bits per component
                                                    cvMat.step[0],              // Bytes per row
                                                    colorSpace,                 // Colorspace
                                                    kCGImageAlphaNoneSkipLast |
                                                    kCGBitmapByteOrderDefault); // Bitmap info flags
    
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
    CGContextRelease(contextRef);
    
    return cvMat;
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
    UIImage *finalImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    
    return finalImage;
}

@end
