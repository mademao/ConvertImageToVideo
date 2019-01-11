//
//  H264Wrapper.m
//  OpenCVDemo
//
//  Created by mademao on 2019/1/10.
//  Copyright © 2019 mademao. All rights reserved.
//

#import <opencv2/opencv.hpp>
#import "H264Wrapper.h"

#if defined ( __cplusplus)
extern "C"
{
#include <stdint.h>
#include "x264.h"
};
#else
#include "x264.h"
#endif

using namespace std;
using namespace cv;

#define WIDTH 150
#define HEIGHT 150
#define VENC_FPS 30

typedef struct __X264_ENCODER__
{
    
    x264_t* m_pX264Handle;
    x264_param_t* m_pX264Param;
    
    x264_picture_t* m_pX264Pic_out;
    x264_picture_t* m_pX264Pic_in;
    x264_nal_t* m_pX264Nals;
    int m_x264iNal;
    FILE *m_x264Fp;
}X264Encoder;

void initX264Encoder(X264Encoder &x264Encoder,char *filePath)
{
    x264Encoder.m_x264Fp = fopen(filePath, "wb");
    x264Encoder.m_pX264Param = (x264_param_t *)malloc(sizeof(x264_param_t));
    assert(x264Encoder.m_pX264Param);
    x264_param_default(x264Encoder.m_pX264Param);
    x264_param_default_preset(x264Encoder.m_pX264Param, "veryfast", "zerolatency");
    x264_param_apply_profile(x264Encoder.m_pX264Param, "baseline");
    x264Encoder.m_pX264Param->i_threads = X264_THREADS_AUTO;//X264_SYNC_LOOKAHEAD_AUTO; // 取空缓冲区继续使用不死锁的保证
    
    // 视频选项
    x264Encoder.m_pX264Param->i_width = WIDTH; // 要编码的图像宽度.
    x264Encoder.m_pX264Param->i_height = HEIGHT; // 要编码的图像高度
    
    // 帧率
    x264Encoder.m_pX264Param->b_vfr_input = 0;//0时只使用fps控制帧率
    int m_frameRate = VENC_FPS;
    x264Encoder.m_pX264Param->i_fps_num = m_frameRate; // 帧率分子
    x264Encoder.m_pX264Param->i_fps_den = 1; // 帧率分母
    x264Encoder.m_pX264Param->i_timebase_den = x264Encoder.m_pX264Param->i_fps_num;
    x264Encoder.m_pX264Param->i_timebase_num = x264Encoder.m_pX264Param->i_fps_den;
    x264Encoder.m_pX264Param->b_intra_refresh = 0;
    x264Encoder.m_pX264Param->b_annexb = 1;
    //m_pX264Param->b_repeat_headers = 0;
    x264Encoder.m_pX264Param->i_keyint_max = m_frameRate;
    
    x264Encoder.m_pX264Param->i_csp = X264_CSP_BGR;//X264_CSP_I420;//
    x264Encoder.m_pX264Param->i_log_level = X264_LOG_INFO;//X264_LOG_DEBUG;
    
    x264Encoder.m_x264iNal = 0;
    x264Encoder.m_pX264Nals = NULL;
    x264Encoder.m_pX264Pic_in = (x264_picture_t *)malloc(sizeof(x264_picture_t));
    if (x264Encoder.m_pX264Pic_in == NULL)
    exit(1);
    else
    memset(x264Encoder.m_pX264Pic_in, 0, sizeof(x264_picture_t));
    //x264_picture_alloc(m_pX264Pic_in, X264_CSP_I420, m_pX264Param->i_width, m_pX264Param->i_height);
    x264_picture_alloc(x264Encoder.m_pX264Pic_in, X264_CSP_BGR, x264Encoder.m_pX264Param->i_width, x264Encoder.m_pX264Param->i_height);
    x264Encoder.m_pX264Pic_in->i_type = X264_TYPE_AUTO;
    
    x264Encoder.m_pX264Pic_out = (x264_picture_t *)malloc(sizeof(x264_picture_t));
    if (x264Encoder.m_pX264Pic_out == NULL)
    exit(1);
    else
    memset(x264Encoder.m_pX264Pic_out, 0, sizeof(x264_picture_t));
    x264_picture_init(x264Encoder.m_pX264Pic_out);
    x264Encoder.m_pX264Handle = x264_encoder_open(x264Encoder.m_pX264Param);
    assert(x264Encoder.m_pX264Handle);
}

void convertFrameToX264Img(x264_image_t *x264InImg,Mat &frame)
{
    //RGB方式
    int srcSize = frame.rows*frame.cols;
    x264InImg->plane[0] = frame.data;
    x264InImg->plane[1] = frame.data + srcSize;
    x264InImg->plane[2] = frame.data + srcSize;
}

void encoderImg(X264Encoder &x264Encoder,Mat &frame)
{
    //转换图像格式
    convertFrameToX264Img(&x264Encoder.m_pX264Pic_in->img,frame);
    
    
    x264Encoder.m_pX264Pic_in->i_pts++;
    int ret = x264_encoder_encode(x264Encoder.m_pX264Handle, &x264Encoder.m_pX264Nals, &x264Encoder.m_x264iNal, x264Encoder.m_pX264Pic_in, x264Encoder.m_pX264Pic_out);
    if (ret< 0){
        printf("Error.\n");
        return;
    }
    
    for (int i = 0; i < x264Encoder.m_x264iNal; ++i)
    {
        fwrite(x264Encoder.m_pX264Nals[i].p_payload, 1, x264Encoder.m_pX264Nals[i].i_payload, x264Encoder.m_x264Fp);
    }
}

@implementation H264Wrapper

+ (void)testVideoEncoder
{
    X264Encoder x264Encoder;
    initX264Encoder(x264Encoder,"/Users/mademao/Desktop/H264create.h264");
    
    char image_name[50];
    
    for (NSInteger i = 0; i < 19; i++) {
        
        sprintf(image_name, "/Users/mademao/Desktop/Image/%zd.jpg", i);
        cv::Mat src = cv::imread(image_name);
        
        if (src.empty()) {
            continue;
        }
        encoderImg(x264Encoder, src);
    }
}

@end
