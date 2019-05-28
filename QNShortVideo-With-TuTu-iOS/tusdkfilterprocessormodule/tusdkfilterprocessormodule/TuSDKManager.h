//
//  TuSDKManager.h
//  TuSDK-Third-Demo-Base
//
//  Created by tutu on 2019/5/5.
//  Copyright © 2019 KK. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "TuSDKFilterProgressorUIProtocol.h"
#import "TuSDKFramework.h"


//NS_ASSUME_NONNULL_BEGIN
/** 输出帧格式类型*/
typedef NS_ENUM(NSInteger, TuSDKManagerFilterOutputType)
{
    TuSDKManagerFilterOutputType_420YpCbCr8BiPlanarFullRange = 0,   // PixelBuffer
    TuSDKManagerFilterOutputType_420YpCbCr8BiPlanarVideoRange,      // PixelBuffer
    TuSDKManagerFilterOutputType_32BGRA,                            // 32BGRA
    TuSDKManagerFilterOutputTypeGLuint                              // GLuint
};

@class CameraFilterPanelView, CameraBeautyPanelView, PropsPanelView;

@interface TuSDKManager : NSObject<TuSDKFilterProgressorUIProtocol>

/**
 是否初始化
*/
@property (nonatomic, assign, readonly) BOOL isInitSDK;
@property (nonatomic, assign, readonly) BOOL isInitFilterProgress;

/**
 TuSDK美颜处理类
*/
@property (nonatomic, strong, readonly) TuSDKFilterProcessor *filterProcessor;

/**
 滤镜面板
 如果要调整他的位置，可以直接修改其frame
 */
@property (nonatomic, strong, readonly) CameraFilterPanelView *filterView;

/**
 道具面板
 如果要调整他的位置，可以直接修改其frame
 */
@property (nonatomic, strong, readonly) PropsPanelView *propsPanelView;

/**
 美颜面板
 如果要调整他的位置，可以直接修改其frame
 */
@property (nonatomic, strong, readonly) CameraBeautyPanelView *facePanelView;

/**
 是否显示漫画: 默认YES
 */
@property (nonatomic, assign) BOOL isShowCartoonView;

/**
 是否显示控制按钮: 默认YES
 */
@property (nonatomic, assign) BOOL isShowControlButtons;

/**
 是否显示哈哈镜: 默认NO
 */
@property (nonatomic, assign) BOOL isShowDistortingMirror;

/**
 资源bundle --- 默认MainBundle
 */
@property (nonatomic, strong) NSBundle *resourceBundle;

/**
 filterCodes: 滤镜
 */
@property (nonatomic, strong, readonly) NSArray<NSString *> *filterCodes;

/**
 cartoonCodes: 漫画
 */
@property (nonatomic, strong, readonly) NSArray<NSString *> *cartoonCodes;

/**
 beautySkinKeys: 美颜
 */
@property (nonatomic, strong, readonly) NSArray<NSString *> *beautySkinKeys;

/**
 beautyFaceKeys: 美型
 */
@property (nonatomic, strong, readonly) NSArray<NSString *> *beautyFaceKeys;

/**
 videoEditFilterCodes: 视频编辑
 */
@property (nonatomic, strong, readonly) NSArray<NSString *> *videoEditFilterCodes;

/**
 scenceCodes:
 */
@property (nonatomic, strong, readonly) NSArray<NSString *> *scenceCodes;

/**
 单例管理

 @return 单例
 */
+ (instancetype)sharedManager;


/**
 初始化SDK

 @param appKey appkey
 */
- (void)initSdkWithAppKey:(NSString *)appKey;


/**
 给filter添加size

 @param outputSize outputSize
 */
- (void)setOutputSize:(CGSize)outputSize;


/**
 配置信息, 这里默认是录制的功能
 这里会统一配置点击的按钮、和视图
 按钮控制,可以配置是否显示按钮 --- isShowControlButtons, 如果要自己在外面控制, 请设置为NO
 控制视图,这里通配的滤镜+道具+美颜面板, 可以通过filterView、propsPanelView、facePanelView修改其位置
 
 @param superView 滤镜视图需要展示的父视图
 @param outputType 资源输入输出格式 GLuint是opengl的渲染
 */
- (void)configSuperView:(UIView*)superView outputType:(TuSDKManagerFilterOutputType) outputType;

/**
 析构掉滤镜管理器----连同滤镜UI一起移除
 */
- (void)destoryFilterProgress;

/**
 Process a video sample and return result soon
 
 @param pixelBuffer pixelBuffer pixelBuffer Buffer to process
 @return Video PixelBuffer
 */
- (CVPixelBufferRef)syncProcessPixelBuffer:(CVPixelBufferRef)pixelBuffer;


/**
 Process a video sample and return result soon

 @param sampleBuffer SampleBuffer Buffer to process
 @return Video PixelBuffer
 */
- (CVPixelBufferRef)syncProcessSampleBuffer:(CMSampleBufferRef)sampleBuffer;

/**
 在OpenGL线程中调用，在这里可以进行采集图像的二次处理
 @param texture    纹理ID
 @param size      纹理尺寸
 @return           返回的纹理
 */
- (GLuint)syncProcessTexture:(GLuint)texture textureSize:(CGSize)size;

@end

//NS_ASSUME_NONNULL_END
