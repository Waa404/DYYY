// Modified By @Waa
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

// 调整评论区透明度
@interface UIView(Comment)
- (void)setBackgroundColor:(UIColor *)backgroundColor;
@end

%hook UIView

- (void)setBackgroundColor:(UIColor *)backgroundColor {
    CGFloat transparency = 1.0;
    BOOL shouldModify = NO;
    NSString *transparencyKey = nil;

    UIResponder *responder = self.nextResponder;
    BOOL isInCommentPanel = [responder isKindOfClass:NSClassFromString(@"AWECommentPanelContainerSwiftImpl.CommentContainerInnerViewController")];

    UIView *superview = self.superview;
    BOOL isFirstSubviewOfCommentInputView = NO;
    BOOL isFirstSubviewOfMiddleContainer = NO;
    
    while (superview && !(isFirstSubviewOfCommentInputView || isFirstSubviewOfMiddleContainer)) {
        if ([superview isKindOfClass:NSClassFromString(@"AWECommentInputViewSwiftImpl.CommentInputContainerView")]) {
            isFirstSubviewOfCommentInputView = (superview.subviews.firstObject == self);
        } else if ([superview isKindOfClass:NSClassFromString(@"AWECommentInputViewSwiftImpl.CommentInputViewMiddleContainer")]) {
            isFirstSubviewOfMiddleContainer = (superview.subviews.firstObject == self);
        }
        superview = superview.superview;
    }

    if (isFirstSubviewOfMiddleContainer || [NSStringFromClass([self class]) isEqualToString:@"AWECommentInputViewSwiftImpl.CommentInputViewMiddleContainer"]) {
        transparencyKey = @"DYYYInputBoxTransparency";
        shouldModify = YES;
    } else if (isInCommentPanel || isFirstSubviewOfCommentInputView) {
        transparencyKey = @"DYYYCommentTransparency";
        shouldModify = YES;
    }

    if (shouldModify && transparencyKey) {
        transparency = [[NSUserDefaults standardUserDefaults] floatForKey:transparencyKey];
        transparency = (transparency >= 0.0 && transparency <= 1.0) ? transparency : 1.0;

        CGFloat r, g, b, a;
        if ([backgroundColor getRed:&r green:&g blue:&b alpha:&a]) {
            backgroundColor = [UIColor colorWithRed:r green:g blue:b alpha:transparency];
        }
    }

    %orig(backgroundColor);
}

%end

// 调整评论区文字颜色
UIColor *darkerColorForColor(UIColor *color) {
    CGFloat hue, saturation, brightness, alpha;
    if ([color getHue:&hue saturation:&saturation brightness:&brightness alpha:&alpha]) {
        return [UIColor colorWithHue:hue saturation:saturation brightness:brightness * 0.9 alpha:alpha];
    }
    return color;
}

@interface UIView (CustomColor)
- (void)traverseSubviews:(UIView *)view customColor:(UIColor *)customColor;
- (void)recursiveModifyImageViewsInView:(UIView *)view;
@end

@implementation UIView (CustomColor)

- (void)traverseSubviews:(UIView *)view customColor:(UIColor *)customColor {
    if ([view isKindOfClass:[UILabel class]]) {
        UILabel *label = (UILabel *)view;
        if ([label.text containsString:@"条评论"]) {
            label.textColor = customColor;
        }
    }

    for (UIView *subview in view.subviews) {
        [self traverseSubviews:subview customColor:customColor];
    }
}

- (void)recursiveModifyImageViewsInView:(UIView *)view {

    BOOL isCommentBlurEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYisEnableCommentBlur"];
    BOOL isCommentColorEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYEnableCommentColor"];
    NSString *customHexColor = [[NSUserDefaults standardUserDefaults] stringForKey:@"DYYYCommentColor"];
    UIColor *customColor = nil;

    // 隐藏输入框上方横线
    if (isCommentBlurEnabled) {
        for (UIView *subview in self.subviews) {
            CGRect frame = subview.frame;
            if (frame.size.width == 430 && frame.size.height == 0.6666666666666666) {
                subview.hidden = YES;
            }
        }
    }
    // 评论区文字颜色
    if (customHexColor.length > 0) {
        unsigned int hexValue = 0;
        NSScanner *scanner = [NSScanner scannerWithString:[customHexColor hasPrefix:@"#"] ? [customHexColor substringFromIndex:1] : customHexColor];
        if ([scanner scanHexInt:&hexValue]) {
            customColor = [UIColor colorWithRed:((hexValue >> 16) & 0xFF) / 255.0
                                          green:((hexValue >> 8) & 0xFF) / 255.0
                                           blue:(hexValue & 0xFF) / 255.0
                                          alpha:0.9];
        }
    }

    UIColor *targetColor = isCommentColorEnabled && customColor ? customColor : [UIColor redColor];

    for (UIView *subview in view.subviews) {
        if ([NSStringFromClass([subview class]) containsString:@"Image"] || 
            [subview isKindOfClass:[UIImageView class]]) {
            
            UIImageView *imgView = (UIImageView *)subview;
            if (imgView.image) {
                imgView.image = [imgView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            }
            imgView.tintColor = targetColor;
        }
        [self recursiveModifyImageViewsInView:subview];
    }
}

@end

@interface UIView (FullScreenPlus)
- (BOOL)fs_isQuickReplayView;
@end

@implementation UIView (FullScreenPlus)
- (BOOL)fs_isQuickReplayView {
    UIResponder *responder = self;
    while (responder) {
        if ([NSStringFromClass([responder class]) containsString:@"AWEIMFeedVideoQuickReplay"]) {
            return YES;
        }
        responder = [responder nextResponder];
    }
    return NO;
}

@end

%hook UIView

- (void)layoutSubviews {
    %orig;

    NSString *className = NSStringFromClass([self class]);

    BOOL isFullScreenEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYisEnableFullScreen"];
    BOOL isCommentColorEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYEnableCommentColor"];

    // 评论区文字
    if (isCommentColorEnabled) {
        NSString *customHexColor = [[NSUserDefaults standardUserDefaults] stringForKey:@"DYYYCommentColor"];
        UIColor *customColor = nil;

        if (customHexColor.length > 0) {
            unsigned int hexValue = 0;
            NSScanner *scanner = [NSScanner scannerWithString:[customHexColor hasPrefix:@"#"] ? [customHexColor substringFromIndex:1] : customHexColor];
            if ([scanner scanHexInt:&hexValue]) {
                customColor = [UIColor colorWithRed:((hexValue >> 16) & 0xFF) / 255.0
                                              green:((hexValue >> 8) & 0xFF) / 255.0
                                               blue:(hexValue & 0xFF) / 255.0
                                              alpha:1.0];
            }
        }

        if (customColor) {
            UIColor *darkerColor = darkerColorForColor(customColor);
            Class YYLabelClass = NSClassFromString(@"YYLabel");

            for (UIView *subview in self.subviews) {
                NSString *subviewClassName = NSStringFromClass([subview class]);

                if ([subview isKindOfClass:[UILabel class]] &&
                    [subviewClassName isEqualToString:@"AWECommentSwiftBizUI.CommentInteractionBaseLabel"]) {
                    ((UILabel *)subview).textColor = darkerColor;
                } else if (YYLabelClass && [subview isKindOfClass:YYLabelClass] &&
                           [subviewClassName isEqualToString:@"AWECommentPanelListSwiftImpl.BaseCellCommentLabel"]) {
                    ((UILabel *)subview).textColor = customColor;
                } else if ([subview isKindOfClass:[UILabel class]] &&
                           [subviewClassName isEqualToString:@"AWECommentPanelHeaderSwiftImpl.CommentHeaderCell"]) {
                    ((UILabel *)subview).textColor = customColor;
                }
            }

            Class targetClass = objc_getClass("AWECommentPanelListSwiftImpl.CommentFooterView");
            if (targetClass && [self isKindOfClass:targetClass]) {
                [self recursiveModifyImageViewsInView:self];
            }

            for (UIView *subview in self.subviews) {
                if ([subview isKindOfClass:[UIButton class]]) {
                    UIButton *button = (UIButton *)subview;
                    NSString *buttonText = [button titleForState:UIControlStateNormal];
                    if ([buttonText containsString:@"展开"] && [buttonText containsString:@"条回复"]) {
                        [button setTitleColor:darkerColor forState:UIControlStateNormal]; 
                    }
                }
            }

            [self traverseSubviews:self customColor:customColor];
        }
    }

    // 私聊视频全屏
    if (isFullScreenEnabled && [self fs_isQuickReplayView]) {
        if (![NSStringFromClass([self class]) containsString:@"AWEIMFeedBottomQuickEmojiInputBar"]) {
            self.backgroundColor = [UIColor clearColor];
            self.layer.backgroundColor = [UIColor clearColor].CGColor;
        }
    }

}

%end