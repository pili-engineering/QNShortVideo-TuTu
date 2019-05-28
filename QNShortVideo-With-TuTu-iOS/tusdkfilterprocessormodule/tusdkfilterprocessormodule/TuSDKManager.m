//
//  TuSDKManager.m
//  TuSDK-Third-Demo-Base
//
//  Created by tutu on 2019/5/5.
//  Copyright © 2019 KK. All rights reserved.
//

#import "TuSDKManager.h"

// TuSDK mark - 文件引入
#import <TuSDKVideo/TuSDKVideo.h>

#import "CameraFilterPanelView.h"
#import "PropsPanelView.h"
#import "CameraBeautyPanelView.h"

// TuSDK mark - 定义参数名
// 滤镜参数默认值键
static NSString * const kFilterParameterDefaultKey = @"default";
// 滤镜参数最大值键
static NSString * const kFilterParameterMaxKey = @"max";


@interface TuSDKManager()<TuSDKFilterProcessorMediaEffectDelegate>

/** superView */
@property (nonatomic, weak) UIView *filterSuperView;

/** outputType */
@property (nonatomic, assign) TuSDKManagerFilterOutputType outputType;

// TuSDK mark - 初始化数据
// 直播滤镜列表
@property (nonatomic, strong) NSArray *videoFilters;


// TuSDK mark - 滤镜、贴纸、微整形按钮
@property (nonatomic, strong) UIButton *filterBtn;
@property (nonatomic, strong) UIButton *stickerBtn;
@property (nonatomic, strong) UIButton *faceBtn;

// TuSDK mark - 滤镜参数默认值
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSDictionary *> *filterParameterDefaultDic;

@end



@implementation TuSDKManager

/**
 创建TuSDKManager对象
 */
+ (instancetype)sharedManager {
    static id instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[TuSDKManager alloc]init];
    });
    return instance;
}

- (instancetype)init {
    if (self = [super init]) {
        _isShowCartoonView = YES;
        _isShowDistortingMirror = NO;
        _isShowControlButtons = YES;
    }
    return self;
}

- (void)initSdkWithAppKey:(NSString *)appKey {
    [TuSDK setLogLevel:lsqLogLevelDEBUG];
    [TuSDK initSdkWithAppKey:appKey];
    _isInitSDK = YES;
}

- (void)setOutputSize:(CGSize)outputSize {
    [self.filterProcessor setOutputSize:outputSize];
}

- (void)configSuperView:(UIView*)superView outputType:(TuSDKManagerFilterOutputType)outputType {
    
    [self destoryFilterProgress];
    _filterSuperView = superView;
    _outputType = outputType;
    
    [self initFilterProcessor];
    if (self.isShowControlButtons) {
        [self initFilterStickerBtn];
    }
    [self initNormalView];
    _filterParameterDefaultDic = [NSMutableDictionary dictionary];
    _isInitFilterProgress = YES;
}


- (void)destoryFilterProgress {
    
    [_filterProcessor destory];
    _filterProcessor = nil;
    _isInitFilterProgress = NO;
    _filterBtn = nil;
    _filterView = nil;
    _faceBtn = nil;
    _facePanelView = nil;
    _stickerBtn = nil;
    _propsPanelView = nil;
}

#pragma mark - TuSDKFilterProcessor output
- (CVPixelBufferRef)syncProcessPixelBuffer:(CVPixelBufferRef)pixelBuffer {
    
    if (!_isInitSDK) {
         @throw [NSException exceptionWithName:@"TuSDK-Error" reason:@"can't init sdk, pelease check TuSDKManager.h" userInfo:nil];
        return nil;
    }
    
    if (!_isInitFilterProgress) {
        @throw [NSException exceptionWithName:@"TuSDK-Error" reason:@"can't configSuperView, pelease check TuSDKManager.h" userInfo:nil];
        return nil;
    }
    
    CVPixelBufferRef newPixelBuffer =  [_filterProcessor syncProcessPixelBuffer:pixelBuffer];
    [_filterProcessor destroyFrameData];
    return newPixelBuffer;
}

- (CVPixelBufferRef)syncProcessSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    if (!_isInitSDK) {
        @throw [NSException exceptionWithName:@"TuSDK-Error" reason:@"can't init sdk, pelease check TuSDKManager.h" userInfo:nil];
        return nil;
    }
    
    if (!_isInitFilterProgress) {
        @throw [NSException exceptionWithName:@"TuSDK-Error" reason:@"can't configSuperView, pelease check TuSDKManager.h" userInfo:nil];
        return nil;
    }
    
    CVPixelBufferRef newPixelBuffer =  [_filterProcessor syncProcessVideoSampleBuffer:sampleBuffer];
    [_filterProcessor destroyFrameData];
    return newPixelBuffer;
}

- (GLuint)syncProcessTexture:(GLuint)texture textureSize:(CGSize)size {
    if (!_isInitSDK) {
        @throw [NSException exceptionWithName:@"TuSDK-Error" reason:@"can't init sdk, pelease check TuSDKManager.h" userInfo:nil];
        return 0;
    }
    
    if (!_isInitFilterProgress) {
        @throw [NSException exceptionWithName:@"TuSDK-Error" reason:@"can't configSuperView, pelease check TuSDKManager.h" userInfo:nil];
        return 0;
    }
    GLuint newTexture = [_filterProcessor syncProcessTexture:texture textureSize:size];
    return newTexture;
}


#pragma mark - TuSDKFilterProcessor delegate

/**
 滤镜/微整形 参数个数
 
 @return  滤镜/微整形参数数量
 */
- (NSInteger)numberOfParamter:(id<CameraFilterPanelProtocol>)filterPanel {
    // 美颜视图面板
    if (filterPanel == _facePanelView)
    {
        switch (_facePanelView.selectedTabIndex) {
            case 0: // 美颜
            {
                return [_filterProcessor mediaEffectsWithType:TuSDKMediaEffectDataTypeSkinFace].count > 0 ? 1 : 0;
            }
            default:
            {
                // 微整形特效
                TuSDKMediaPlasticFaceEffect *effect = [_filterProcessor mediaEffectsWithType:TuSDKMediaEffectDataTypePlasticFace].firstObject;
                return effect.filterArgs.count;
            }
        }
        
    } else {
        // 滤镜视图面板
        switch (_filterView.selectedTabIndex) {
            case 1: // 漫画
            {
                return 0;
            }
            case 0: { // 滤镜
                TuSDKMediaFilterEffect *effect = [_filterProcessor mediaEffectsWithType:TuSDKMediaEffectDataTypeFilter].firstObject;
                return effect.filterArgs.count;
            }
        }
    }
    
    return 0;
    
}

/**
 滤镜/微整形参数名称
 
 @param index 滤镜索引
 @return  滤镜/微整形参数名称
 */
- (NSString *)filterPanel:(id<CameraFilterPanelProtocol>)filterPanel paramterNameAtIndex:(NSUInteger)index {
    
    // 美颜视图面板
    if (filterPanel == _facePanelView) {
        switch (_facePanelView.selectedTabIndex) {
            case 0: // 精准美颜、极度美颜
            {
                return _facePanelView.selectedSkinKey;
            }
            default:
            {
                // 微整形
                TuSDKMediaPlasticFaceEffect *effect = [_filterProcessor mediaEffectsWithType:TuSDKMediaEffectDataTypePlasticFace].firstObject;
                return effect.filterArgs[index].key;
            }
        }
        
    } else {
        // 滤镜视图面板
        switch (_filterView.selectedTabIndex) {
            case 1: // 漫画
            {
                return 0;
            }
            case 0:  // 滤镜
            {
                TuSDKMediaFilterEffect *effect = [_filterProcessor mediaEffectsWithType:TuSDKMediaEffectDataTypeFilter].firstObject;
                return effect.filterArgs[index].key;
            }
        }
    }
    
    return @"";
}

/**
 滤镜/微整形参数值
 
 @param index  滤镜/微整形参数索引
 @return  滤镜/微整形参数百分比
 */
- (double)filterPanel:(id<CameraFilterPanelProtocol>)filterPanel percentValueAtIndex:(NSUInteger)index {
    
    // 美颜视图面板
    if (filterPanel == _facePanelView) {
        switch (_facePanelView.selectedTabIndex) {
            case 0: // 精准美颜，极度美颜
            {
                TuSDKMediaSkinFaceEffect *effect = [_filterProcessor mediaEffectsWithType:TuSDKMediaEffectDataTypeSkinFace].firstObject;
                return [effect argWithKey:_facePanelView.selectedSkinKey].precent;
            }
            default:
            {
                // 微整形
                TuSDKMediaPlasticFaceEffect *effect = [_filterProcessor mediaEffectsWithType:TuSDKMediaEffectDataTypePlasticFace].firstObject;
                return effect.filterArgs[index].precent;
            }
        }
        
    } else {
        // 滤镜视图面板
        switch (_filterView.selectedTabIndex) {
            case 1: // 漫画
            {
                return 0;
            }
            case 0:
            {
                TuSDKMediaFilterEffect *effect = [_filterProcessor mediaEffectsWithType:TuSDKMediaEffectDataTypeFilter].firstObject;
                return effect.filterArgs[index].precent;
            }
        }
    }
    
    return 0;
}


#pragma mark - RecordFilterPanelDelegate
/** 应用美颜特效 */
- (void)applySkinFaceEffect;
{
    /** 初始化美肤特效 */
    TuSDKMediaSkinFaceEffect *skinFaceEffect = [[TuSDKMediaSkinFaceEffect alloc] initUseSkinNatural:_facePanelView.useSkinNatural];
    [_filterProcessor addMediaEffect:skinFaceEffect];
    
    [self updateSkinFaceDefaultParameters];
    
}

/**
 滤镜面板切换标签回调
 
 @param filterPanel 滤镜面板
 @param tabIndex 标签索引
 */
- (void)filterPanel:(id<CameraFilterPanelProtocol>)filterPanel didSwitchTabIndex:(NSInteger)tabIndex {
    
}

/**
 滤镜面板选中回调
 
 @param filterPanel 滤镜面板
 @param code 滤镜码
 */
- (void)filterPanel:(id<CameraFilterPanelProtocol>)filterPanel didSelectedFilterCode:(NSString *)code {
    
    // 美颜视图面板
    if (filterPanel == _facePanelView)
    {
        switch (_facePanelView.selectedTabIndex)
        {
            case 0: // 精准美颜、 极度美颜
            {
                // 如果是切换美颜
                if ([code isEqualToString:self.beautySkinKeys[0]])
                {
                    [self applySkinFaceEffect];
                    
                }else {
                    
                    if ([_filterProcessor mediaEffectsWithType:TuSDKMediaEffectDataTypeSkinFace].count == 0)
                        [self applySkinFaceEffect];
                }
                
                break;
            }
            default:
            {
                // 微整形
                if ([_filterProcessor mediaEffectsWithType:TuSDKMediaEffectDataTypePlasticFace].count == 0) {
                    TuSDKMediaPlasticFaceEffect *plasticFaceEffect = [[TuSDKMediaPlasticFaceEffect alloc] init];
                    [_filterProcessor addMediaEffect:plasticFaceEffect];
                    [self updatePlasticFaceDefaultParameters];
                    return;
                }
                break;
            }
        }
        
    }else {
        
        // 滤镜视图面板
        switch (_filterView.selectedTabIndex)
        {
            case 1: // 漫画
            {
                TuSDKMediaComicEffect *effect = [[TuSDKMediaComicEffect alloc] initWithEffectCode:code];
                [_filterProcessor addMediaEffect:effect];
                
                break;
            }
            case 0: { // 滤镜
                TuSDKMediaFilterEffect *effect = [[TuSDKMediaFilterEffect alloc] initWithEffectCode:code];
                [_filterProcessor addMediaEffect:effect];
                break;
            }
            default:
                break;
        }
    }
}

/**
 滤镜面板值变更回调
 
 @param filterPanel 滤镜面板
 @param percentValue 滤镜参数变更数值
 @param index 滤镜参数索引
 */
- (void)filterPanel:(id<CameraFilterPanelProtocol>)filterPanel didChangeValue:(double)percentValue paramterIndex:(NSUInteger)index {
    
    // 美颜视图面板
    if (filterPanel == _facePanelView)
    {
        switch (_facePanelView.selectedTabIndex)
        {
            case 0: // 精准美颜,极致美颜
            {
                TuSDKMediaSkinFaceEffect *effect = [_filterProcessor mediaEffectsWithType:TuSDKMediaEffectDataTypeSkinFace].firstObject;
                [effect submitParameterWithKey:_facePanelView.selectedSkinKey argPrecent:percentValue];
                
                break;
            }
            default: {
                // 微整形
                TuSDKMediaPlasticFaceEffect *effect = [_filterProcessor mediaEffectsWithType:TuSDKMediaEffectDataTypePlasticFace].firstObject;
                [effect submitParameter:index argPrecent:percentValue];
                break;
            }
        }
        
    } else {
        // 滤镜视图面板
        switch (_filterView.selectedTabIndex)
        {
            case 1: // 漫画
            {
                break;
            }
            case 0: {
                TuSDKMediaFilterEffect *effect = [_filterProcessor mediaEffectsWithType:TuSDKMediaEffectDataTypeFilter].firstObject;
                [effect submitParameter:index argPrecent:percentValue];
                break;
            }
        }
    }
    
}

/**
 重置滤镜参数回调
 
 @param filterPanel 滤镜面板
 @param paramterKeys 滤镜参数
 */
- (void)filterPanel:(id<CameraFilterPanelProtocol>)filterPanel resetParamterKeys:(NSArray *)paramterKeys {
    
    if (filterPanel == _facePanelView) {
        
        switch (_facePanelView.selectedTabIndex) {
            case 0:
            {
                [_filterProcessor removeMediaEffectsWithType:TuSDKMediaEffectDataTypeSkinFace];
            }
                break;
            case 1:
            {
                [_filterProcessor removeMediaEffectsWithType:TuSDKMediaEffectDataTypePlasticFace];
            }
                break;
            default:
                break;
        }
        
    } else if(filterPanel == _filterView) {
        [_filterProcessor removeMediaEffectsWithType:TuSDKMediaEffectDataTypeFilter];
    }
}

#pragma mark PropsPanelViewDelegate

/**
 贴纸选中回调
 
 @param propsPanelView 相机贴纸协议
 @param propsItem 贴纸组
 */
- (void)propsPanel:(PropsPanelView *)propsPanelView didSelectPropsItem:(__kindof PropsItem *)propsItem {
    if (!propsItem) {
        // 为nil时 移除已有贴纸组
        [_filterProcessor removeMediaEffectsWithType:TuSDKMediaEffectDataTypeSticker];
        return;
    }
    
    // 添加贴纸特效
    [_filterProcessor addMediaEffect:propsItem.effect];
}

/**
 取消选中某类道具
 
 @param propsPanel 道具视频
 @param propsItemCategory 道具分类
 */
- (void)propsPanel:(PropsPanelView *)propsPanel unSelectPropsItemCategory:(__kindof PropsItemCategory *)propsItemCategory {
    [_filterProcessor removeMediaEffectsWithType:propsItemCategory.categoryType];
}

/**
 道具移除事件
 
 @param propsPanel 道具视图
 @param propsItem 被移除的特效
 */
- (void)propsPanel:(PropsPanelView *)propsPanel didRemovePropsItem:(__kindof PropsItem *)propsItem {
    [_filterProcessor removeMediaEffect:propsItem.effect];
}


#pragma mark - TuSDKFilterProcessorMediaEffectDelegate

/**
 当前正在应用的特效
 
 @param processor TuSDKFilterProcessor
 @param mediaEffectData 正在预览特效
 @since 2.2.0
 */
- (void)onVideoProcessor:(TuSDKFilterProcessor *)processor didApplyingMediaEffect:(id<TuSDKMediaEffect>)mediaEffectData;
{
    switch (mediaEffectData.effectType) {
            // 滤镜特效
        case TuSDKMediaEffectDataTypeFilter: {
            [_filterView reloadFilterParamters];
        }
            break;
            // 微整形特效
        case TuSDKMediaEffectDataTypePlasticFace: {
            [self updatePlasticFaceDefaultParameters];
        }
            break;
        case TuSDKMediaEffectDataTypeSkinFace: {
            [self updateSkinFaceDefaultParameters];
            break;
        }
        default:
            break;
    }
    
}

/**
 当某个特效被移除时，该回调就将会被调用
 
 @param processor 特效处理器
 @param mediaEffectDatas 被移除的数据
 */
- (void)onVideoProcessor:(TuSDKFilterProcessor *)processor didRemoveMediaEffects:(NSArray<id<TuSDKMediaEffect>> *)mediaEffectDatas;
{
    
}

#pragma mark - 滤镜相关

/**
 重置美颜参数默认值
 */
- (void)updateSkinFaceDefaultParameters;
{
    TuSDKMediaSkinFaceEffect *effect = [_filterProcessor mediaEffectsWithType:TuSDKMediaEffectDataTypeSkinFace].firstObject;
    NSArray<TuSDKFilterArg *> *args = effect.filterArgs;
    BOOL needSubmitParameter = NO;
    
    for (TuSDKFilterArg *arg in args) {
        NSString *parameterName = arg.key;
        // NSLog(@"调节的滤镜参数名称 parameterName: %@",parameterName)
        // 应用保存的参数默认值、最大值
        NSDictionary *savedDefaultDic = _filterParameterDefaultDic[parameterName];
        if (savedDefaultDic) {
            if (savedDefaultDic[kFilterParameterDefaultKey])
                arg.defaultValue = [savedDefaultDic[kFilterParameterDefaultKey] doubleValue];
            
            if (savedDefaultDic[kFilterParameterMaxKey])
                arg.maxFloatValue = [savedDefaultDic[kFilterParameterMaxKey] doubleValue];
            
            // 把当前值重置为默认值
            [arg reset];
            needSubmitParameter = YES;
            continue;
        }
        
        // TUSDK 开放了滤镜等特效的参数调节，用户可根据实际使用场景情况调节效果强度大小
        // Attention ！！
        // 特效的参数并非越大越好，请根据实际效果进行调节
        
        // 是否需要更新参数值
        BOOL updateValue = NO;
        // 默认值的百分比，用于指定滤镜初始的效果（参数默认值 = 最小值 + (最大值 - 最小值) * defaultValueFactor）
        CGFloat defaultValueFactor = 1;
        // 最大值的百分比，用于限制滤镜参数变化的幅度（参数最大值 = 最小值 + (最大值 - 最小值) * maxValueFactor）
        CGFloat maxValueFactor = 1;
        
        if ([parameterName isEqualToString:@"smoothing"]) {
            // 润滑
            maxValueFactor = 0.7;
            defaultValueFactor = 0.6;
            updateValue = YES;
        } else if ([parameterName isEqualToString:@"whitening"]) {
            // 白皙
            maxValueFactor = 0.4;
            defaultValueFactor = 0.3;
            updateValue = YES;
        } else if ([parameterName isEqualToString:@"ruddy"]) {
            // 红润
            maxValueFactor = 0.4;
            defaultValueFactor = 0.3;
            updateValue = YES;
        }
        
        if (updateValue) {
            if (defaultValueFactor != 1)
                arg.defaultValue = arg.minFloatValue + (arg.maxFloatValue - arg.minFloatValue) * defaultValueFactor * maxValueFactor;
            
            if (maxValueFactor != 1)
                arg.maxFloatValue = arg.minFloatValue + (arg.maxFloatValue - arg.minFloatValue) * maxValueFactor;
            // 把当前值重置为默认值
            [arg reset];
            
            // 存储值
            _filterParameterDefaultDic[parameterName] = @{kFilterParameterDefaultKey: @(arg.defaultValue), kFilterParameterMaxKey: @(arg.maxFloatValue)};
            needSubmitParameter = YES;
        }
    }
    
    // 提交修改结果
    if (needSubmitParameter)
        [effect submitParameters];
    
    [_facePanelView reloadFilterParamters];
    
}

/**
 重置微整形参数默认值
 */
- (void)updatePlasticFaceDefaultParameters {
    
    TuSDKMediaPlasticFaceEffect *effect = [_filterProcessor mediaEffectsWithType:TuSDKMediaEffectDataTypePlasticFace].firstObject;
    NSArray<TuSDKFilterArg *> *args = effect.filterArgs;
    BOOL needSubmitParameter = NO;
    
    for (TuSDKFilterArg *arg in args) {
        NSString *parameterName = arg.key;
        
        // 是否需要更新参数值
        BOOL updateValue = NO;
        // 默认值的百分比，用于指定滤镜初始的效果（参数默认值 = 最小值 + (最大值 - 最小值) * defaultValueFactor）
        CGFloat defaultValueFactor = 1;
        // 最大值的百分比，用于限制滤镜参数变化的幅度（参数最大值 = 最小值 + (最大值 - 最小值) * maxValueFactor）
        CGFloat maxValueFactor = 1;
        if ([parameterName isEqualToString:@"eyeSize"]) {
            // 大眼
            defaultValueFactor = 0.3;
            maxValueFactor = 0.85;
            updateValue = YES;
        } else if ([parameterName isEqualToString:@"chinSize"]) {
            // 瘦脸
            defaultValueFactor = 0.2;
            maxValueFactor = 0.8;
            updateValue = YES;
        } else if ([parameterName isEqualToString:@"noseSize"]) {
            // 瘦鼻
            defaultValueFactor = 0.2;
            maxValueFactor = 0.6;
            updateValue = YES;
        } else if ([parameterName isEqualToString:@"mouthWidth"]) {
            // 嘴型
        } else if ([parameterName isEqualToString:@"archEyebrow"]) {
            // 细眉
        } else if ([parameterName isEqualToString:@"jawSize"]) {
            // 下巴
        } else if ([parameterName isEqualToString:@"eyeAngle"]) {
            // 眼角
        } else if ([parameterName isEqualToString:@"eyeDis"]) {
            // 眼距
        }
        
        if (updateValue) {
            if (defaultValueFactor != 1)
                arg.defaultValue = arg.minFloatValue + (arg.maxFloatValue - arg.minFloatValue) * defaultValueFactor * maxValueFactor;
            
            if (maxValueFactor != 1)
                arg.maxFloatValue = arg.minFloatValue + (arg.maxFloatValue - arg.minFloatValue) * maxValueFactor;
            // 把当前值重置为默认值
            [arg reset];
            
            needSubmitParameter = YES;
        }
    }
    
    // 提交修改结果
    if (needSubmitParameter)
        [effect submitParameters];
    
    [_facePanelView reloadFilterParamters];
    
}



#pragma mark - TuSDKFilterProcessor init

// 初始化 TuSDKFilterProcessor
- (void)initFilterProcessor;
{
    // 传入图像的方向是否为原始朝向(相机采集的原始朝向)，SDK 将依据该属性来调整人脸检测时图片的角度。如果没有对图片进行旋转，则为 YES
    BOOL isOriginalOrientation = NO;
    
    if (self.outputType < 3) {
        // pix
        if (self.outputType == TuSDKManagerFilterOutputType_420YpCbCr8BiPlanarFullRange) {
            _filterProcessor = [[TuSDKFilterProcessor alloc] initWithFormatType:kCVPixelFormatType_420YpCbCr8BiPlanarFullRange isOriginalOrientation:isOriginalOrientation];
        } else if (self.outputType == TuSDKManagerFilterOutputType_420YpCbCr8BiPlanarVideoRange) {
            _filterProcessor = [[TuSDKFilterProcessor alloc] initWithFormatType:kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange isOriginalOrientation:isOriginalOrientation];
        } else {
            _filterProcessor = [[TuSDKFilterProcessor alloc] initWithFormatType:kCVPixelFormatType_32BGRA isOriginalOrientation:isOriginalOrientation];
        }
        
    } else {
        // opengle
        EAGLSharegroup *group = [EAGLContext currentContext].sharegroup;
        _filterProcessor = [[TuSDKFilterProcessor alloc] initWithSharegroup:group];
    }
    
    
    self.filterProcessor.mediaEffectDelegate = self;
    
    // 是否开启了镜像
    self.filterProcessor.horizontallyMirrorFrontFacingCamera = NO;
    
   // 前置还是后置
   // _filterProcessor.outputPixelFormatType = lsqFormatTypeBGRA;
    
    
    self.filterProcessor.cameraPosition = AVCaptureDevicePositionFront;
    self.filterProcessor.adjustOutputRotation = NO;
    [self.filterProcessor setEnableLiveSticker:YES];
    
    // 默认选中第一个滤镜， 滤镜列表详见 Constants.h kCameraFilterCodes
    [_filterProcessor addMediaEffect:[[TuSDKMediaFilterEffect alloc] initWithEffectCode:self.filterCodes.firstObject]];
    
}


#pragma mark - TuSDK init

- (void)initFilterStickerBtn;
{
    
    CGFloat screenWidth = CGRectGetWidth([UIScreen mainScreen].bounds);
    UIColor *buttonBGC = lsqRGB(255, 102, 51);
    
    // 滤镜按钮
    if (!_filterBtn) {
        _filterBtn = [[UIButton alloc]initWithFrame:CGRectMake(screenWidth * 0.5 - 46 - 15 - 23, 30, 46, 46)];
        _filterBtn.layer.cornerRadius = 16;
        _filterBtn.backgroundColor = buttonBGC;
        [_filterBtn setTitle:@"滤镜" forState:UIControlStateNormal];
        _filterBtn.titleLabel.font = [UIFont systemFontOfSize:13];
        [_filterBtn addTarget:self action:@selector(clickFilterBtn) forControlEvents:UIControlEventTouchUpInside];
        [self.filterSuperView addSubview:_filterBtn];
    }
    
    // 贴纸按钮
    if (!_stickerBtn) {
        _stickerBtn = [[UIButton alloc]initWithFrame:CGRectMake(screenWidth*0.5 - 23, 30, 46, 46)];
        _stickerBtn.layer.cornerRadius = 16;
        _stickerBtn.backgroundColor = buttonBGC;
        [_stickerBtn setTitle:@"贴纸" forState:UIControlStateNormal];
        _stickerBtn.titleLabel.font = [UIFont systemFontOfSize:13];
        [_stickerBtn addTarget:self action:@selector(clickStickerBtn) forControlEvents:UIControlEventTouchUpInside];
        [self.filterSuperView addSubview:_stickerBtn];
    }
    
    // 微整形按钮
    if (!_faceBtn) {
        _faceBtn = [[UIButton alloc]initWithFrame:CGRectMake(screenWidth*0.5 + 15 + 23, 30, 46, 46)];
        _faceBtn.layer.cornerRadius = 16;
        _faceBtn.backgroundColor = buttonBGC;
        [_faceBtn setTitle:@"微整形" forState:UIControlStateNormal];
        _faceBtn.titleLabel.font = [UIFont systemFontOfSize:13];
        [_faceBtn addTarget:self action:@selector(clickFaceBtn) forControlEvents:UIControlEventTouchUpInside];
        [self.filterSuperView addSubview:_faceBtn];
    }
    
}


#pragma mark - TuSDK UI
- (void)clickStickerBtn;
{
    _propsPanelView.hidden = !_propsPanelView.hidden;
    _facePanelView.hidden = _filterView.hidden = YES;
}


- (void)clickFilterBtn;
{
    _filterView.hidden = !_filterView.hidden;
    _facePanelView.hidden = _propsPanelView.hidden = YES;
}

- (void)clickFaceBtn;
{
    _facePanelView.hidden = !_facePanelView.hidden;
    _propsPanelView.hidden = _filterView.hidden = YES;
}

- (void)initNormalView {
    // 美颜视图
    _facePanelView = [[CameraBeautyPanelView alloc] initWithFrame:CGRectZero];
    _facePanelView.delegate = (id<CameraFilterPanelDelegate>)self;
    _facePanelView.dataSource = (id<CameraFilterPanelDataSource>)self;
    CGSize size = self.filterSuperView.bounds.size;
    const CGFloat filterPanelHeight = 276;
    _facePanelView.frame = CGRectMake(0, size.height - filterPanelHeight, size.width, filterPanelHeight);
    [self.filterSuperView addSubview:_facePanelView];
    _facePanelView.hidden = YES;
    
    // 滤镜视图
    _filterView = [[CameraFilterPanelView alloc] initWithFrame:CGRectMake(0, size.height - filterPanelHeight, size.width, filterPanelHeight)];
    _filterView.delegate = (id<CameraFilterPanelDelegate>)self;
    _filterView.dataSource = (id<CameraFilterPanelDataSource>)self;
    [self.filterSuperView addSubview:_filterView];
    _filterView.hidden = YES;
    
    // 初始化贴纸视图
    _propsPanelView = [[PropsPanelView alloc] initWithFrame:CGRectZero];
    _propsPanelView.delegate = (id<PropsPanelViewDelegate>)self;
    const CGFloat stickerPanelHeight = 200;
    _propsPanelView.frame = CGRectMake(0, size.height - stickerPanelHeight, size.width, stickerPanelHeight);
    [self.filterSuperView addSubview:_propsPanelView];
    _propsPanelView.hidden = YES;
}

- (NSBundle *)resourceBundle {
    if (!_resourceBundle) {
        _resourceBundle = [NSBundle mainBundle];
    }
    return _resourceBundle;
}



#pragma mark - codes

- (void)configFilterCodes:(NSArray *)filterCodes {
    _filterCodes = filterCodes;
}

/**
 配置漫画codes
 
 @param cartoonCodes cartoonCodes
 */
- (void)configCartoonCodes:(NSArray *)cartoonCodes {
    _cartoonCodes = cartoonCodes;
}

/**
 配置美颜codes
 
 @param beautySkinKeys beautySkinKeys
 */
- (void)configBeautySkinKeys:(NSArray *)beautySkinKeys {
    _beautySkinKeys = beautySkinKeys;
}

/**
 配置美型codes
 
 @param beautyFaceKeys beautyFaceKeys
 */

- (void)configBeautyFaceKeys:(NSArray *)beautyFaceKeys {
    _beautyFaceKeys = beautyFaceKeys;
}

/**
 配置视频编辑codes
 
 @param videoEditFilterCodes videoEditFilterCodes
 */

- (void)configVideoEditFilterCodes:(NSArray *)videoEditFilterCodes {
    _videoEditFilterCodes = videoEditFilterCodes;
}


/**
 配置scenceCodes
 
 @param scenceCodes scenceCodes
 */

- (void)configScenceCodes:(NSArray *)scenceCodes {
    _scenceCodes = scenceCodes;
}

@end
