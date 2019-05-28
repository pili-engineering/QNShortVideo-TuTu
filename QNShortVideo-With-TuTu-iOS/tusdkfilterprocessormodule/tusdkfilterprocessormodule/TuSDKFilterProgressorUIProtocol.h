//
//  TuSDKFilterProgressorUIProtocol.h
//  tusdkfilterprocessormodule
//
//  Created by tutu on 2019/5/7.
//  Copyright © 2019 KK. All rights reserved.
//


@protocol TuSDKFilterProgressorUIProtocol <NSObject>

@optional

/**
 配置滤镜codes

 @param filterCodes filterCodes
 */
- (void)configFilterCodes:(NSArray*)filterCodes;

/**
 配置漫画codes
 
 @param cartoonCodes cartoonCodes
 */
- (void)configCartoonCodes:(NSArray*)cartoonCodes;

/**
 配置美颜codes
 
 @param beautySkinKeys beautySkinKeys
 */
- (void)configBeautySkinKeys:(NSArray*)beautySkinKeys;

/**
 配置美型codes
 
 @param beautyFaceKeys beautyFaceKeys
 */

- (void)configBeautyFaceKeys:(NSArray*)beautyFaceKeys;

/**
 配置视频编辑codes
 
 @param videoEditFilterCodes videoEditFilterCodes
 */

- (void)configVideoEditFilterCodes:(NSArray*)videoEditFilterCodes;


/**
 配置scenceCodes
 
 @param scenceCodes scenceCodes
 */

- (void)configScenceCodes:(NSArray*)scenceCodes;

@end
