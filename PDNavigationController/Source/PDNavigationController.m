//
//  PDNavigationController.m
//  PDNavigationController
//
//  Created by liang on 2018/2/22.
//  Copyright © 2018年 PipeDog. All rights reserved.
//

#import "PDNavigationController.h"
#import <QuartzCore/QuartzCore.h>
#import <math.h>

#define kScreenWidth [[UIScreen mainScreen] bounds].size.width
#define kKeyWindow [[UIApplication sharedApplication] keyWindow]

static CGFloat const kScreenshotImageOriginalLeft = -150.f;
static CGFloat const kBlackMaskViewOriginAlpha = 0.4f;

@interface PDNavigationController () <UIGestureRecognizerDelegate>

@property (nonatomic, strong) NSMutableArray *screenshotStack;
@property (nonatomic, assign) CGPoint startTouchPoint;
@property (nonatomic, assign, getter=isMoving) BOOL moving;

@property (nonatomic, strong) UIView *backgroundView;
@property (nonatomic, strong) UIView *blackMaskView;
@property (nonatomic, strong) UIImageView *screenShotImageView;

@end

@implementation PDNavigationController

- (void)dealloc {
    [_backgroundView removeFromSuperview];
    _backgroundView = nil;
    _screenshotStack = nil;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.canDragBack = YES;
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.canDragBack = YES;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.interactivePopGestureRecognizer.enabled = NO;

    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(paningGestureReceive:)];
    pan.delegate = self;
    [self.view addGestureRecognizer:pan];

    self.view.layer.shadowOffset = CGSizeMake(-5, 0);
    self.view.layer.shadowRadius = 10.f;
    self.view.layer.shadowColor = RGBAColor(0x000000, 0.5f).CGColor;
    self.view.layer.shadowOpacity = 0.5f;
}

#pragma mark - Custom Methods
- (void)popViewControllerAnimated:(BOOL)animated completion:(void (^)(__kindof UIViewController *))completion {
    if (!animated) {
        UIViewController *viewController = [self popViewControllerAnimated:animated];
        if (completion) completion(viewController);
        return;
    }
    
    [self preparePop];
    
    self.blackMaskView.alpha = kBlackMaskViewOriginAlpha;

    [self animateForPopEndingWithBlock:^(UIViewController *viewController) {
        if (completion) completion(viewController);
    }];
}

- (void)popToViewController:(UIViewController *)viewController animated:(BOOL)animated completion:(void (^)(NSArray<__kindof UIViewController *> *))completion {
    if (!animated) {
        NSArray<__kindof UIViewController *> *viewControllers = [self popToViewController:viewController animated:animated];
        if (completion) completion(viewControllers);
        return;
    }
    
    [self preparePop];
    
    self.blackMaskView.alpha = kBlackMaskViewOriginAlpha;
    
    [self animateForPopEndingWithBlock:^(NSArray *viewControllers) {
        if (completion) completion(viewControllers);
    } toViewController:viewController];
}

- (void)popToRootViewControllerAnimated:(BOOL)animated completion:(void (^)(NSArray<__kindof UIViewController *> *))completion {
    if (!animated) {
        NSArray<__kindof UIViewController *> *viewControllers = [self popToRootViewControllerAnimated:animated];
        if (completion) completion(viewControllers);
        return;
    }
    
    [self preparePop];
    
    self.blackMaskView.alpha = kBlackMaskViewOriginAlpha;

    [self animateForPopToRootViewControllerWithBlock:^(NSArray<UIViewController *> *viewControllers) {
        if (completion) completion(viewControllers);
    }];
}

#pragma mark - Override Methods
- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated {
    [self.screenshotStack addObject:[self capture]];
    [super pushViewController:viewController animated:animated];
}

- (UIViewController *)popViewControllerAnimated:(BOOL)animated {
    [self.screenshotStack removeLastObject];
    return [super popViewControllerAnimated:animated];
}

- (NSArray *)popToViewController:(UIViewController *)viewController animated:(BOOL)animated {
    NSUInteger index = [self.viewControllers indexOfObject:viewController];
    
    if (index != NSNotFound) {
        NSInteger loc = index;
        NSInteger len = MAX((self.viewControllers.count - index - 1), 0);
        NSInteger screenshotCount = self.screenshotStack.count;
        
        if (screenshotCount >= (loc + len)) {
            [self.screenshotStack removeObjectsInRange:NSMakeRange(loc, len)];
        }
    }
    return [super popToViewController:viewController animated:animated];
}

- (NSArray<UIViewController *> *)popToRootViewControllerAnimated:(BOOL)animated {
    [self.screenshotStack removeAllObjects];
    return [super popToRootViewControllerAnimated:animated];
}

#pragma mark - Gesture Recognizer Methods
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if (self.viewControllers.count <= 1 || !self.canDragBack) {
        return NO;
    }
    return YES;
}

- (void)paningGestureReceive:(UIPanGestureRecognizer *)sender {
    if (self.viewControllers.count <= 1 || !self.canDragBack) return;
    
    switch (sender.state) {
        case UIGestureRecognizerStateBegan: {
            [self _panGestureRecognizerBegan:sender];
        } break;
        case UIGestureRecognizerStateChanged: {
            [self _panGestureRecognizerChanged:sender];
        } break;
        case UIGestureRecognizerStateEnded: {
            [self _panGestureRecognizerEnded:sender];
        } break;
        case UIGestureRecognizerStateCancelled: {
            [self _panGestureRecognizerCancelled:sender];
        } break;
        default: break;
    }
}

- (void)_panGestureRecognizerBegan:(UIPanGestureRecognizer *)sender {
    self.startTouchPoint = [sender locationInView:kKeyWindow];
    [self preparePop];
}

- (void)_panGestureRecognizerChanged:(UIPanGestureRecognizer *)sender {
    CGPoint touchPoint = [sender locationInView:kKeyWindow];
    if (self.isMoving) {
        [self moveViewWithX:touchPoint.x - self.startTouchPoint.x];
    }
}

- (void)_panGestureRecognizerEnded:(UIPanGestureRecognizer *)sender {
    CGPoint touchPoint = [sender locationInView:kKeyWindow];
    
    if (touchPoint.x - self.startTouchPoint.x > kScreenWidth / 3.f) {
        [self animateForPopEndingWithBlock:nil];
    } else {
        [UIView animateWithDuration:0.2 animations:^{
            [self moveViewWithX:0];
        } completion:^(BOOL finished) {
            self.moving = NO;
            self.backgroundView.hidden = YES;
        }];
    }
}

- (void)_panGestureRecognizerCancelled:(UIPanGestureRecognizer *)sender {
    [UIView animateWithDuration:0.2 animations:^{
        [self moveViewWithX:0];
    } completion:^(BOOL finished) {
        self.moving = NO;
        self.backgroundView.hidden = YES;
    }];
}

#pragma mark - Tool Methods
- (void)moveViewWithX:(CGFloat)x {
    x = MIN(x, self.view.bounds.size.width);
    x = MAX(x, 0);
    
    CGRect frame = self.view.frame;
    frame.origin.x = x;
    self.view.frame = frame;
    
    float alpha = kBlackMaskViewOriginAlpha - (kBlackMaskViewOriginAlpha * (x / kScreenWidth));    
    self.blackMaskView.alpha = alpha;
    
    CGFloat aa = ABS(kScreenshotImageOriginalLeft) / kScreenWidth;
    CGFloat y = x * aa;
    
    CGRect rect = self.screenShotImageView.frame;
    
    self.screenShotImageView.frame = CGRectMake(kScreenshotImageOriginalLeft + y,
                                                0,
                                                CGRectGetWidth(rect),
                                                CGRectGetHeight(rect));
}

- (UIImage *)capture {
    UIWindow *window = [[UIApplication sharedApplication] keyWindow];
    UIGraphicsBeginImageContextWithOptions(window.bounds.size, window.opaque, 0);
    // -[CALayer renderInContext:] => -[UIView drawViewHierarchyInRect:afterScreenUpdates:]
    // From 0.2s+ => 0.05s+
    [window drawViewHierarchyInRect:window.bounds afterScreenUpdates:NO];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image ?: [UIImage new];
}

- (void)preparePop {
    self.moving = YES;
    self.backgroundView.hidden = NO;
    
    if (self.screenShotImageView.superview) {
        [self.screenShotImageView removeFromSuperview];
    }
    UIImage *screenShot = [self.screenshotStack lastObject];
    self.screenShotImageView.image = screenShot;
    
    CGRect rect = CGRectMake(kScreenshotImageOriginalLeft,
                             0,
                             CGRectGetWidth(self.view.bounds),
                             CGRectGetHeight(self.view.bounds));
    self.screenShotImageView.frame = rect;
    
    rect = CGRectMake(0,
                      0,
                      CGRectGetWidth(self.view.bounds),
                      CGRectGetHeight(self.view.bounds));
    self.blackMaskView.frame = rect;
    [self.backgroundView insertSubview:self.screenShotImageView belowSubview:self.blackMaskView];
    [self.view.superview insertSubview:self.backgroundView belowSubview:self.view];
}

- (void)animateForPopEndingWithBlock:(void (^)(UIViewController *viewController))block {
    [UIView animateWithDuration:0.35f animations:^{
        [self moveViewWithX:kScreenWidth];
    } completion:^(BOOL finished) {
        UIViewController *viewController = [self popViewControllerAnimated:NO];
        
        CGRect frame = self.view.frame;
        frame.origin.x = 0;
        self.view.frame = frame;
        
        self.moving = NO;
        self.backgroundView.hidden = YES;
        
        if (block) block(viewController);
    }];
}

- (void)animateForPopEndingWithBlock:(void (^)(NSArray<UIViewController *> *viewControllers))block toViewController:(UIViewController *)viewController {
    UIImage *capture = nil;
    NSUInteger index = [self.viewControllers indexOfObject:viewController];
    
    if (self.screenshotStack.count > index) {
        capture = self.screenshotStack[index];
    }
    
    if (!capture) {
        // If can not get a matching image, use system animation.
        NSArray<UIViewController *> *viewControllers = [self popToViewController:viewController animated:YES];
        if (block) block(viewControllers);
        return;
    }
    
    self.screenShotImageView.image = capture;

    [UIView animateWithDuration:0.35f animations:^{
        [self moveViewWithX:kScreenWidth];
    } completion:^(BOOL finished) {
        NSArray<UIViewController *> *viewControllers = [self popToViewController:viewController animated:NO];
        CGRect frame = self.view.frame;
        frame.origin.x = 0;
        self.view.frame = frame;

        self.moving = NO;
        self.backgroundView.hidden = YES;

        if (block) block(viewControllers);
    }];
}

- (void)animateForPopToRootViewControllerWithBlock:(void (^)(NSArray<UIViewController *> *viewControllers))block {
    UIImage *capture = self.screenshotStack.firstObject;

    if (!capture) {
        NSArray<UIViewController *> *viewControllers = [self popToRootViewControllerAnimated:YES];
        if (block) block(viewControllers);
        return;
    }

    self.screenShotImageView.image = capture;
    
    [UIView animateWithDuration:0.35f animations:^{
        [self moveViewWithX:kScreenWidth];
    } completion:^(BOOL finished) {
        NSArray<UIViewController *> *viewControllers = [self popToRootViewControllerAnimated:NO];
        CGRect frame = self.view.frame;
        frame.origin.x = 0;
        self.view.frame = frame;
        
        self.moving = NO;
        self.backgroundView.hidden = YES;
        
        if (block) block(viewControllers);
    }];
}

#pragma mark - Getter Methods
- (NSMutableArray *)screenshotStack {
    if (!_screenshotStack) {
        _screenshotStack = [NSMutableArray array];
    }
    return _screenshotStack;
}

- (UIView *)backgroundView {
    if (!_backgroundView) {
        _backgroundView = [[UIView alloc] initWithFrame:CGRectMake(0,
                                                                   0,
                                                                   CGRectGetWidth(self.view.bounds),
                                                                   CGRectGetHeight(self.view.bounds))];
        [_backgroundView addSubview:self.blackMaskView];
    }
    return _backgroundView;
}

- (UIView *)blackMaskView {
    if (!_blackMaskView) {
        _blackMaskView = [[UIView alloc] initWithFrame:CGRectMake(0,
                                                                  0,
                                                                  CGRectGetWidth(self.view.bounds),
                                                                  CGRectGetHeight(self.view.bounds))];
        _blackMaskView.backgroundColor = [UIColor blackColor];
    }
    return _blackMaskView;
}

- (UIImageView *)screenShotImageView {
    if (!_screenShotImageView) {
        _screenShotImageView = [[UIImageView alloc] init];
    }
    return _screenShotImageView;
}

@end
