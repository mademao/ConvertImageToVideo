//
//  ViewController.m
//  OpenCVDemo
//
//  Created by mademao on 2019/1/9.
//  Copyright © 2019 mademao. All rights reserved.
//

#import "ViewController.h"
#import "OpenCVWrapper.h"
#import "OpenCVViewController.h"
#import "H264Wrapper.h"
#import "MP4Wrapper.h"
#import "H264Create.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];

    /*
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"1" ofType:@"png"];
    UIImage *image = [UIImage imageWithContentsOfFile:filePath];
    
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(50, 50, 150, 150)];
    imageView.layer.borderColor = [UIColor blackColor].CGColor;
    imageView.layer.borderWidth = 1.0;
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.view addSubview:imageView];
    imageView.image = [OpenCVWrapper changeImage:image];
    */
     
//    [OpenCVWrapper createVideo];
    
//    [H264Wrapper testVideoEncoder];
    
//    [MP4Wrapper test];
    
    [H264Create createH264];
    
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    OpenCVViewController *viewController = [[OpenCVViewController alloc] init];
    [self.navigationController pushViewController:viewController animated:YES];
}


@end
