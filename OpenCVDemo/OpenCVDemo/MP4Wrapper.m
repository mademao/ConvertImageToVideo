//
//  MP4Wrapper.m
//  OpenCVDemo
//
//  Created by mademao on 2019/1/9.
//  Copyright © 2019 mademao. All rights reserved.
//

#import "MP4Wrapper.h"
#include "mp4record.h"

@implementation MP4Wrapper

+ (void)test
{
    initMp4Encoder("/Users/mademao/Desktop/test1.mp4", 150, 150);
    NSData *data = [NSData dataWithContentsOfFile:@"/Users/mademao/Desktop/H264Create.h264"];
    mp4VEncode((u_int8_t *)(data.bytes), (int)data.length);
    closeMp4Encoder();
//    int initMp4Encoder(const char * filename,int width,int height);
//    int mp4VEncode(uint8_t * data ,int len);
//    int mp4AEncode(uint8_t * data ,int len);
//    void closeMp4Encoder();
}

@end
