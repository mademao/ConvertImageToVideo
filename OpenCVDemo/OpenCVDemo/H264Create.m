//
//  H264Create.m
//  OpenCVDemo
//
//  Created by mademao on 2019/1/11.
//  Copyright © 2019 mademao. All rights reserved.
//

#include <stdio.h>
#include <stdlib.h>

#include "stdint.h"

#if defined ( __cplusplus)
extern "C"
{
#include "x264.h"
};
#else
#include "x264.h"
#endif

#import "H264Create.h"

#define max(x,y)  (x>y?x:y)
#define min(x,y)  (x<y?x:y)

//#define y(r,g,b)  (((66 * r + 129 * g + 25 * b + 128) >> 8) + 16)
//#define u(r,g,b)  (((-38 * r - 74 * g + 112 * b + 128) >> 8) + 128)
//#define v(r,g,b)  (((112 * r - 94 * g - 18 * b + 128) >> 8) + 128)
#define y(r,g,b)  ((77 * r + 150 * g + 29 * b + 128) >> 8)
#define u(r,g,b)  (((-43 * r - 84 * g + 127 * b + 128) >> 8) + 128)
#define v(r,g,b)  (((127 * r - 106 * g - 21 * b + 128) >> 8) + 128)

#define color(x)  ((unsigned char)((x < 0) ? 0 : ((x > 255) ? 255 : x)))

#define RGBA_YUV420SP   0x00004012
#define BGRA_YUV420SP   0x00004210
#define RGBA_YUV420P    0x00014012
#define BGRA_YUV420P    0x00014210
#define RGB_YUV420SP    0x00003012
#define RGB_YUV420P     0x00013012
#define BGR_YUV420SP    0x00003210
#define BGR_YUV420P     0x00013210
#define ARGB_YUV420SP   0x00004123
#define ARGB_YUV420P    0x00014123

/**
 *   type 0-3位表示b的偏移量
 *        4-7位表示g的偏移量
 *        8-11位表示r的偏移量
 *        12-15位表示rgba一个像素所占的byte
 *        16-19位表示yuv的类型，0为420sp，1为420p
 */
void rgbaToYuv(int width,int height,unsigned char * rgb,unsigned char * yuv,int type){
    const int frameSize = width * height;
    const int yuvType=(type&0x10000)>>16;
    const int byteRgba=(type&0x0F000)>>12;
    const int rShift=(type&0x00F00)>>8;
    const int gShift=(type&0x000F0)>>4;
    const int bShift= (type&0x0000F);
    const int uIndex=0;
    const int vIndex=yuvType; //yuvType为1表示YUV420p,为0表示420sp
    
    int yIndex = 0;
    int uvIndex[2]={frameSize,frameSize+frameSize/4};
    
    unsigned char R, G, B, Y, U, V;
    unsigned int index = 0;
    for (int j = 0; j < height; j++) {
        for (int i = 0; i < width; i++) {
            index = j * width + i;
            
            R = rgb[index*byteRgba+rShift]&0xFF;
            G = rgb[index*byteRgba+gShift]&0xFF;
            B = rgb[index*byteRgba+bShift]&0xFF;
            
            Y = y(R,G,B);
            U = u(R,G,B);
            V = v(R,G,B);
            
            yuv[yIndex++] = color(Y);
            if (j % 2 == 0 && index % 2 == 0) {
                yuv[uvIndex[uIndex]++] =color(U);
                yuv[uvIndex[vIndex]++] =color(V);
            }
        }
    }
}


@implementation H264Create

+ (void)createH264
{
    int ret;
    int i, j;
    
    FILE *fp_dst = fopen("/Users/mademao/Desktop/H264Create.h264", "wb");
    
    int frame_num = 19;
    int width = 150, height = 150;
    
    int iNal = 0;
    x264_nal_t *pNals = NULL;
    x264_t *pHandle = NULL;
    x264_picture_t *pPic_in = (x264_picture_t *)malloc(sizeof(x264_picture_t));
    x264_picture_t *pPic_out = (x264_picture_t *)malloc(sizeof(x264_picture_t));
    x264_param_t *pParam = (x264_param_t *)malloc(sizeof(x264_param_t));
    
    if (fp_dst == NULL) {
        printf("Error open file.\n");
        return;
    }
    
    x264_param_default(pParam);
    pParam->i_width = width;
    pParam->i_height = height;
    pParam->i_threads = X264_SYNC_LOOKAHEAD_AUTO;
    pParam->i_csp = X264_CSP_I420;
    int fps = 10;
    pParam->i_fps_num = (int)(fps * 1000 + .5);
    pParam->i_fps_den = 1000;
    pParam->i_timebase_den = pParam->i_fps_num;
    pParam->i_timebase_num = pParam->i_fps_den;
    
    x264_param_apply_profile(pParam, x264_profile_names[5]);
    
    pHandle = x264_encoder_open(pParam);
    
    x264_picture_init(pPic_out);
    ret = x264_picture_alloc(pPic_in, X264_CSP_I420, pParam->i_width, pParam->i_height);
    
    for (i = 0; i < frame_num; i++) {
        UIImage *image = [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"/Users/mademao/Desktop/Image/%d.jpg", i]];
        unsigned char *data = [self getColorDataWithImage:image];
        
        
        int size = pParam->i_width * pParam->i_height;
        
        unsigned char *yuv = (unsigned char *)malloc(sizeof(unsigned char) * size / 4 * 6);
        rgbaToYuv(width, height, data, yuv, ARGB_YUV420P);
        
        pPic_in->img.plane[0] = yuv;
        pPic_in->img.plane[1] = yuv + size;
        pPic_in->img.plane[2] = yuv + size / 4 * 5;
        
        
        
        pPic_in->i_pts = i;
        
        ret = x264_encoder_encode(pHandle, &pNals, &iNal, pPic_in, pPic_out);
        
        if (ret< 0){
            printf("Error.\n");
            return;
        }
        
        printf("Succeed encode frame: %5d\n",i);
        
        for (j = 0; j < iNal; j++) {
            fwrite(pNals[j].p_payload, 1, pNals[j].i_payload, fp_dst);
        }
        
        free(data);
        free(yuv);
    }
    
    i = 0;
    
    while (1) {
        ret = x264_encoder_encode(pHandle, &pNals, &iNal, NULL, pPic_out);
        if(ret == 0){
            break;
        }
        printf("Flush 1 frame.\n");
        for (j = 0; j < iNal; ++j){
            fwrite(pNals[j].p_payload, 1, pNals[j].i_payload, fp_dst);
        }
        i++;
    }
    
    
    x264_picture_clean(pPic_in);
    x264_encoder_close(pHandle);
    pHandle = NULL;
    
    free(pPic_in);
    free(pPic_out);
    free(pParam);
    
    fclose(fp_dst);
}

+ (unsigned char *)getColorDataWithImage:(UIImage *)image
{
    CGImageRef inImage = image.CGImage;
    CGContextRef cgctx = [self newARGBBitmapContextFromImage:inImage];
    if (cgctx == NULL) {
        return nil;
    }
    
    size_t width = CGImageGetWidth(inImage);
    size_t height = CGImageGetHeight(inImage);
    CGRect rect = {{0,0},{width,height}};

    CGContextDrawImage(cgctx, rect, inImage);
    
    unsigned char* data = CGBitmapContextGetData (cgctx);
    
    CGContextRelease(cgctx);
    if (data != NULL) {
        return data;
    }
    
    return nil;
}

+ (CGContextRef)newARGBBitmapContextFromImage:(CGImageRef)inImage {
    CGContextRef    context = NULL;
    CGColorSpaceRef colorSpace;
    void *          bitmapData;
    int             bitmapByteCount;
    int             bitmapBytesPerRow;
    
    // Get image width, height. We'll use the entire image.
    size_t pixelsWide = CGImageGetWidth(inImage);
    size_t pixelsHigh = CGImageGetHeight(inImage);
    
    // Declare the number of bytes per row. Each pixel in the bitmap in this
    // example is represented by 4 bytes; 8 bits each of red, green, blue, and
    // alpha.
    bitmapBytesPerRow   = (int)(pixelsWide * 4);
    bitmapByteCount     =(int)(bitmapBytesPerRow * pixelsHigh);
    
    // Use the generic RGB color space.
    colorSpace = CGColorSpaceCreateDeviceRGB();
    
    if (colorSpace == NULL)
    {
        fprintf(stderr, "Error allocating color space\n");
        return NULL;
    }
    
    // Allocate memory for image data. This is the destination in memory
    // where any drawing to the bitmap context will be rendered.
    bitmapData = malloc( bitmapByteCount );
    if (bitmapData == NULL)
    {
        fprintf (stderr, "Memory not allocated!");
        CGColorSpaceRelease( colorSpace );
        return NULL;
    }
    
    // Create the bitmap context. We want pre-multiplied ARGB, 8-bits
    // per component. Regardless of what the source image format is
    // (CMYK, Grayscale, and so on) it will be converted over to the format
    // specified here by CGBitmapContextCreate.
    context = CGBitmapContextCreate (bitmapData,
                                     pixelsWide,
                                     pixelsHigh,
                                     8,      // bits per component
                                     bitmapBytesPerRow,
                                     colorSpace,
                                     kCGImageAlphaPremultipliedFirst);
    if (context == NULL)
    {
        free (bitmapData);
        fprintf (stderr, "Context not created!");
    }
    // Make sure and release colorspace before returning
    CGColorSpaceRelease( colorSpace );
    return context;
}

@end
