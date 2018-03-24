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

#define kScreenWidth [[UIScreen mainScreen]bounds].size.width
#define kKeyWindow [[UIApplication sharedApplication] keyWindow]

static CGFloat const kScreenshotImageOriginalLeft = -150.f;

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
    
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(paningGestureReceive:)];
    pan.delegate = self;
    [self.view addGestureRecognizer:pan];
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
    NSInteger index = [self.viewControllers indexOfObject:viewController];
    if (index != NSNotFound) {
        NSUInteger loc = index;
        NSUInteger len = self.viewControllers.count - index - 1;
        
        if (loc + len > self.screenshotStack.count) { // loc + len cannot greater than screenshotStack.count.
            len = self.screenshotStack.count - loc;
        }
        [self.screenshotStack removeObjectsInRange:NSMakeRange(loc, len)];
    }
    return [super popToViewController:viewController animated:animated];
}

- (NSArray<UIViewController *> *)popToRootViewControllerAnimated:(BOOL)animated {
    [self.screenshotStack removeAllObjects];
    return [super popToRootViewControllerAnimated:animated];
}

#pragma mark - Utility Methods
- (UIImage *)capture {
    UIGraphicsBeginImageContextWithOptions(self.view.bounds.size, self.view.opaque, 0.0);
    [self.view.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (void)moveViewWithX:(CGFloat)x {
    x = MIN(x, self.view.bounds.size.width);
    x = MAX(x, 0);
    
    CGRect frame = self.view.frame;
    frame.origin.x = x;
    self.view.frame = frame;
    
    float alpha = 0.4 - (x / 800);
    
    self.blackMaskView.alpha = alpha;
    
    CGFloat aa = ABS(kScreenshotImageOriginalLeft) / kScreenWidth;
    CGFloat y = x * aa;
    
    CGRect rect = self.screenShotImageView.frame;
    
    self.screenShotImageView.frame = CGRectMake(kScreenshotImageOriginalLeft + y,
                                                0,
                                                CGRectGetWidth(rect),
                                                CGRectGetHeight(rect));
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
    
    if (sender.state == UIGestureRecognizerStateBegan) {
        [self _panGestureRecognizerBegan:sender];
    }
    else if (sender.state == UIGestureRecognizerStateChanged) {
        [self _panGestureRecognizerChanged:sender];
    }
    else if (sender.state == UIGestureRecognizerStateEnded) {
        [self _panGestureRecognizerEnded:sender];
    }
    else if (sender.state == UIGestureRecognizerStateCancelled) {
        [self _panGestureRecognizerCancelled:sender];
    }
}

- (void)_panGestureRecognizerBegan:(UIPanGestureRecognizer *)sender {
    self.moving = YES;
    self.startTouchPoint = [sender locationInView:kKeyWindow];
    
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
    [self.backgroundView insertSubview:self.screenShotImageView belowSubview:self.blackMaskView];
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
        [UIView animateWithDuration:0.2 animations:^{
            [self moveViewWithX:kScreenWidth];
        } completion:^(BOOL finished) {
            [self popViewControllerAnimated:NO];
            
            CGRect frame = self.view.frame;
            frame.origin.x = 0;
            self.view.frame = frame;
            
            self.moving = NO;
            self.backgroundView.hidden = YES;
        }];
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

#pragma mark - Getter Methods
- (NSMutableArray *)screenshotStack {
    if (!_screenshotStack) {
        _screenshotStack = [NSMutableArray array];
    }
    return _screenshotStack;
}

- (UIView *)backgroundView {
    if (!_backgroundView) {
        self.backgroundView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), CGRectGetHeight(self.view.bounds))];
        [self.view.superview insertSubview:self.backgroundView belowSubview:self.view];
        
        [_backgroundView addSubview:self.blackMaskView];
    }
    return _backgroundView;
}

- (UIView *)blackMaskView {
    if (!_blackMaskView) {
        _blackMaskView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), CGRectGetHeight(self.view.bounds))];
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
