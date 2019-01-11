//
//  OpenCVWrapper.h
//  OpenCVDemo
//
//  Created by mademao on 2019/1/9.
//  Copyright © 2019 mademao. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVKit/AVKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface OpenCVWrapper : NSObject

+ (void)createVideo;

+ (UIImage *)changeImage:(UIImage *)image;

@end

NS_ASSUME_NONNULL_END