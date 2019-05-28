//
//  UIImage+LoadBundleImage.m
//  Pods-TuSDK-Third-Demo-Base
//
//  Created by tutu on 2019/5/6.
//

#import "UIImage+LoadBundleImage.h"
#import "TuSDKManager.h"

@implementation UIImage (LoadBundleImage)

+ (UIImage*)imageNamedWithNormalBundle:(NSString *)named {
    return [self imageNamed:named inBundle:[TuSDKManager sharedManager].resourceBundle compatibleWithTraitCollection:NULL];
}
@end
