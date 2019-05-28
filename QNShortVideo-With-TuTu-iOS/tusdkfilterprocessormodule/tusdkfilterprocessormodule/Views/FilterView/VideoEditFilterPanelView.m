//
//  CameraFilterPanelView.m
//  TuSDKVideoDemo
//
//  Created by bqlin on 2018/7/23.
//  Copyright © 2018年 TuSDK. All rights reserved.
//

#import "VideoEditFilterPanelView.h"
#import "CameraNormalFilterListView.h"
#import "CameraComicsFilterListView.h"
#import "PageTabbar.h"
#import "ViewSlider.h"
#import "TuSDKManager.h"

// 滤镜列表高度
static const CGFloat kFilterListHeight = 120;
// 滤镜列表与参数面板的间隔
static const CGFloat kFilterListParamtersViewSpacing = 24;
// tabbar 高度
static const CGFloat kFilterTabbarHeight = 30;

@interface VideoEditFilterPanelView () <PageTabbarDelegate, ViewSliderDataSource, ViewSliderDelegate>

/**
 普通滤镜列表
 */
@property (nonatomic, strong, readonly) CameraNormalFilterListView *normalFilterListView;

/**
 参数面板
 */
@property (nonatomic, strong, readonly) ParametersAdjustView *paramtersView;

/**
 模糊背景
 */
@property (nonatomic, strong) UIVisualEffectView *effectBackgroundView;

@end

@implementation VideoEditFilterPanelView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self commonInit];
    }
    return self;
}
- (instancetype)initWithCoder:(NSCoder *)decoder {
    if (self = [super initWithCoder:decoder]) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit {
    __weak typeof(self) weakSelf = self;
    

    
    // 模糊背景
    _effectBackgroundView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleDark]];
    [self addSubview:_effectBackgroundView];
    
    // 普通滤镜列表
    _normalFilterListView = [[CameraNormalFilterListView alloc] initWithFrame:CGRectZero filterCodes:[TuSDKManager sharedManager].videoEditFilterCodes];
    _normalFilterListView.itemViewTapActionHandler = ^(CameraNormalFilterListView *filterListView, HorizontalListItemView *selectedItemView, NSString *filterCode) {
        weakSelf.paramtersView.hidden = selectedItemView.tapCount < selectedItemView.maxTapCount;
        if ([weakSelf.delegate respondsToSelector:@selector(filterPanel:didSelectedFilterCode:)]) {
            [weakSelf.delegate filterPanel:weakSelf didSelectedFilterCode:filterCode];
        }
        // 不能在此处调用 reloadData，应在外部滤镜应用后才调用
    };
    
    [self addSubview:_normalFilterListView];
    
    // 参数面板
    _paramtersView = [[ParametersAdjustView alloc] initWithFrame:CGRectZero];
    [self addSubview:_paramtersView];
    _paramtersView.hidden = YES;
    

}

- (void)layoutSubviews {
    CGSize size = self.bounds.size;
    CGRect safeBounds = self.bounds;
    if (@available(iOS 11.0, *)) {
        safeBounds = UIEdgeInsetsInsetRect(safeBounds, self.safeAreaInsets);
    }
    
    const CGFloat tabbarY = CGRectGetMaxY(safeBounds) - kFilterListHeight;
    const CGFloat pageSliderHeight = kFilterListHeight - kFilterTabbarHeight;
    _normalFilterListView.frame = CGRectMake(CGRectGetMinX(safeBounds), tabbarY, CGRectGetWidth(safeBounds), pageSliderHeight);

    const CGFloat paramtersViewAvailableHeight = CGRectGetMaxY(safeBounds) - kFilterListHeight - kFilterListParamtersViewSpacing;
    const CGFloat paramtersViewLeftMargin = 16;
    const CGFloat paramtersViewRightMargin = 9;
    const CGFloat paramtersViewHeight = _paramtersView.contentHeight;
    _paramtersView.frame =
    CGRectMake(CGRectGetMinX(safeBounds) + paramtersViewLeftMargin,
               paramtersViewAvailableHeight - paramtersViewHeight,
               CGRectGetWidth(self.frame) - paramtersViewLeftMargin - paramtersViewRightMargin,
               paramtersViewHeight);
    _effectBackgroundView.frame = CGRectMake(0,CGRectGetMinY(_paramtersView.frame) - kFilterTabbarHeight, size.width, self.intrinsicContentSize.height );
}

- (CGSize)intrinsicContentSize {
    return CGSizeMake(-1, kFilterListParamtersViewSpacing + kFilterListHeight + _paramtersView.intrinsicContentSize.height + kFilterTabbarHeight);
}

/**
 判断滤镜参数是否过滤

 @param key 滤镜参数
 @return 是否过滤
 */
- (BOOL)shouldSkipFilterKey:(NSString *)key {
    return NO;
}

#pragma mark - property

- (void)setSelectedFilterCode:(NSString *)selectedFilterCode {
    _selectedFilterCode = selectedFilterCode;
    _normalFilterListView.selectedFilterCode = selectedFilterCode;
}

- (BOOL)display {
    return self.alpha > 0.0;
}

- (NSInteger)selectedIndex {
    return _normalFilterListView.selectedIndex;
}

#pragma mark - public

/**
 重载滤镜参数数据
 */
- (void)reloadFilterParamters {
    if (!self.display) return;
    
    __weak typeof(self) weakSelf = self;
    
    
    [_paramtersView setupWithParameterCount:[self.dataSource numberOfParamter:self] config:^(NSUInteger index, ParameterAdjustItemView *itemView, void (^parameterItemConfig)(NSString *name, double percent)) {
        NSString *parameterName = [self.dataSource filterPanel:weakSelf  paramterNameAtIndex:index];
        // 跳过美颜、美型滤镜参数
        BOOL shouldSkip = [self shouldSkipFilterKey:parameterName];
        if (!shouldSkip) {
            double percentVale = [self.dataSource filterPanel:weakSelf percentValueAtIndex:index];
            parameterName = [NSString stringWithFormat:@"lsq_filter_set_%@", parameterName];
            parameterItemConfig(NSLocalizedStringFromTable(parameterName, @"TuSDKConstants", @"无需国际化"), percentVale);
        }
    } valueChange:^(NSUInteger index, double percent) {
        if ([weakSelf.delegate respondsToSelector:@selector(filterPanel:didChangeValue:paramterIndex:)]) {
            [weakSelf.delegate filterPanel:weakSelf didChangeValue:percent paramterIndex:index];
        }
    }];
}


#pragma mark - touch

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    if (self.userInteractionEnabled == NO || self.hidden == YES || self.alpha <= 0.01 || ![self pointInside:point withEvent:event]) return nil;
    UIView *hitView = [super hitTest:point withEvent:event];
    // 响应子视图
    if (hitView != self && !hitView.hidden) {
        return hitView;
    }
    return nil;
}

@end
