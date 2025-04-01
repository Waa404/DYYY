#import "DYYYBottomAlertView.h"

@interface DYYYBottomAlertView ()

@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) UIView *alertView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *messageLabel;
@property (nonatomic, strong) UIButton *cancelButton;
@property (nonatomic, strong) UIButton *confirmButton;
@property (nonatomic, copy) DYYYAlertActionHandler cancelAction;
@property (nonatomic, copy) DYYYAlertActionHandler confirmAction;

@end

@implementation DYYYBottomAlertView

+ (instancetype)showAlertWithTitle:(NSString *)title
                           message:(NSString *)message
                      cancelAction:(DYYYAlertActionHandler)cancelAction
                     confirmAction:(DYYYAlertActionHandler)confirmAction {
    
    DYYYBottomAlertView *alertView = [[DYYYBottomAlertView alloc] initWithTitle:title 
                                                                        message:message
                                                                   cancelAction:cancelAction
                                                                  confirmAction:confirmAction];
    [alertView show];
    return alertView;
}

- (instancetype)initWithTitle:(NSString *)title
                      message:(NSString *)message
                 cancelAction:(DYYYAlertActionHandler)cancelAction
                confirmAction:(DYYYAlertActionHandler)confirmAction {
    
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    self = [super initWithFrame:window.bounds];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        
        _cancelAction = cancelAction;
        _confirmAction = confirmAction;
        
        // 创建半透明背景
        _containerView = [[UIView alloc] initWithFrame:self.bounds];
        _containerView.backgroundColor = [UIColor blackColor];
        _containerView.alpha = 0.0;
        [self addSubview:_containerView];
        
        // 添加点击手势来关闭弹窗
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(backgroundTapped:)];
        [_containerView addGestureRecognizer:tapGesture];
        
        // 获取底部安全区域高度
        CGFloat bottomSafeAreaHeight = 0;
        if (@available(iOS 11.0, *)) {
            UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
            bottomSafeAreaHeight = keyWindow.safeAreaInsets.bottom;
        }
        
        // 创建弹窗内容视图
        _alertView = [[UIView alloc] initWithFrame:CGRectMake(6, self.bounds.size.height, self.bounds.size.width - 12, 200 + bottomSafeAreaHeight)];
        _alertView.backgroundColor = [UIColor whiteColor];
        _alertView.layer.cornerRadius = 50.0;
        _alertView.layer.masksToBounds = YES;
        _alertView.clipsToBounds = YES;
        
        if (@available(iOS 13.0, *)) {
            _alertView.backgroundColor = [UIColor systemBackgroundColor];
        } else {
            _alertView.backgroundColor = [UIColor whiteColor];
        }
        
        [self addSubview:_alertView];
        
        // 添加拖拽手势
        UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGesture:)];
        [_alertView addGestureRecognizer:panGesture];
        
        // 创建标题
        _titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 15, _alertView.frame.size.width - 60, 24)];
        _titleLabel.text = title;
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _titleLabel.font = [UIFont boldSystemFontOfSize:18];
        _titleLabel.center = CGPointMake(_alertView.frame.size.width / 2, _titleLabel.center.y);
        
        // 创建消息
        _messageLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(_titleLabel.frame) + 30, _alertView.frame.size.width - 60, 60)];
        _messageLabel.text = message;
        _messageLabel.textAlignment = NSTextAlignmentCenter;
        _messageLabel.numberOfLines = 0;
        _messageLabel.font = [UIFont systemFontOfSize:17];
        _messageLabel.textColor = [UIColor darkGrayColor];
        _messageLabel.center = CGPointMake(_alertView.frame.size.width / 2, _messageLabel.center.y);
        
        // 创建取消按钮
        _cancelButton = [[UIButton alloc] initWithFrame:CGRectMake(_alertView.frame.size.width * 0.08, _alertView.frame.size.height - 75, _alertView.frame.size.width * 0.4, 50)];
        [_cancelButton setTitle:@"取消" forState:UIControlStateNormal];
        [_cancelButton addTarget:self action:@selector(cancelButtonTapped) forControlEvents:UIControlEventTouchUpInside];
        _cancelButton.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];
        _cancelButton.layer.cornerRadius = 14.0;
        [_cancelButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        _cancelButton.titleLabel.font = [UIFont systemFontOfSize:16];
        
        // 创建确认按钮
        _confirmButton = [[UIButton alloc] initWithFrame:CGRectMake(_alertView.frame.size.width * 0.52, _alertView.frame.size.height - 75, _alertView.frame.size.width * 0.4, 50)];
        [_confirmButton setTitle:@"确定" forState:UIControlStateNormal];
        [_confirmButton addTarget:self action:@selector(confirmButtonTapped) forControlEvents:UIControlEventTouchUpInside];
        _confirmButton.backgroundColor = [UIColor colorWithRed:254/255.0 green:47/255.0 blue:85/255.0 alpha:1.0];
        _confirmButton.layer.cornerRadius = 14.0;
        [_confirmButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _confirmButton.titleLabel.font = [UIFont boldSystemFontOfSize:16];
        
        [_alertView addSubview:_titleLabel];
        [_alertView addSubview:_messageLabel];
        [_alertView addSubview:_cancelButton];
        [_alertView addSubview:_confirmButton];
    }
    return self;
}

- (void)show {
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    [window addSubview:self];
    
    [UIView animateWithDuration:0.3 animations:^{
        self.containerView.alpha = 0.4;
        self.alertView.frame = CGRectMake(6, self.bounds.size.height - self.alertView.frame.size.height - 6, self.bounds.size.width - 12, self.alertView.frame.size.height);
    }];
}

- (void)dismiss {
    [UIView animateWithDuration:0.3 animations:^{
        self.containerView.alpha = 0.0;
        self.alertView.frame = CGRectMake(6, self.bounds.size.height, self.bounds.size.width - 12, self.alertView.frame.size.height);
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
    }];
}

- (void)backgroundTapped:(UITapGestureRecognizer *)gesture {
    [self dismiss];
}

- (void)cancelButtonTapped {
    if (self.cancelAction) {
        self.cancelAction();
    }
    [self dismiss];
}

- (void)confirmButtonTapped {
    if (self.confirmAction) {
        self.confirmAction();
    }
    [self dismiss];
}

#pragma mark - Pan Gesture Handling

- (void)handlePanGesture:(UIPanGestureRecognizer *)gesture {
    CGPoint translation = [gesture translationInView:self.alertView];
    if (translation.y > 0) {
        self.alertView.frame = CGRectMake(6, self.bounds.size.height - self.alertView.frame.size.height + translation.y - 6, self.bounds.size.width - 12, self.alertView.frame.size.height);
    }

    if (gesture.state == UIGestureRecognizerStateEnded) {
        if (translation.y > 100) {
            [self dismiss];
        } else {
            [UIView animateWithDuration:0.2 animations:^{
                self.alertView.frame = CGRectMake(6, self.bounds.size.height - self.alertView.frame.size.height - 6, self.bounds.size.width - 12, self.alertView.frame.size.height);
            }];
        }
    }
}

@end