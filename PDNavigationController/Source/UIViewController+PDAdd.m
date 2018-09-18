//
//  UIViewController+PDAdd.m
//  PDNavigationController
//
//  Created by liang on 2018/9/17.
//  Copyright © 2018年 PipeDog. All rights reserved.
//

#import "UIViewController+PDAdd.h"

static inline void dispatch_async_safe(dispatch_queue_t queue, dispatch_block_t block) {
    if (strcmp(dispatch_queue_get_label(queue),
               dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL))) {
        if (block) block();
    } else {
        dispatch_async(queue, ^{
            if (block) block();
        });
    }
}

@implementation UIViewController (PDAdd)

@end

@interface UINavigationController (PDAdd) <UINavigationBarDelegate>

@end

@implementation UINavigationController (PDAdd)

- (BOOL)navigationBar:(UINavigationBar *)navigationBar shouldPopItem:(UINavigationItem *)item {
    if ([self.viewControllers count] < [navigationBar.items count]) {
        return YES;
    }
    
    BOOL shouldPop = YES;
    UIViewController *page = [self topViewController];
    
    if ([page respondsToSelector:@selector(specialBackButtonEvent)]) {
        shouldPop = [page specialBackButtonEvent];
    } else if ([page respondsToSelector:@selector(regularBackButtonEvent)]) {
        shouldPop = [page regularBackButtonEvent];
    }
    
    if (shouldPop) {
        dispatch_async_safe(dispatch_get_main_queue(), ^{
            [self popViewControllerAnimated:YES];
        });
    } else {
        // Workaround for iOS7.1. - http://stackoverflow.com/posts/comments/34452906
        for (UIView *subview in [navigationBar subviews]) {
            if(0.f < subview.alpha && subview.alpha < 1.f) {
                [UIView animateWithDuration:0.25f animations:^{
                    subview.alpha = 1.f;
                }];
            }
        }
    }
    return NO;
}

@end
