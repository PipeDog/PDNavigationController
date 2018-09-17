//
//  PDNavigationController.h
//  PDNavigationController
//
//  Created by liang on 2018/2/22.
//  Copyright © 2018年 PipeDog. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PDNavigationController : UINavigationController

@property (nonatomic, assign) BOOL canDragBack; ///< Default is YES.

- (void)popViewControllerAnimated:(BOOL)animated completion:(void (^)(__kindof UIViewController *viewController))completion;

- (void)popToViewController:(UIViewController *)viewController animated:(BOOL)animated completion:(void (^)(NSArray<__kindof UIViewController *> *viewControllers))completion;

- (void)popToRootViewControllerAnimated:(BOOL)animated completion:(void (^)(NSArray<__kindof UIViewController *> *viewControllers))completion;

@end

@interface UIViewController (Properties)

@property (nonatomic, readonly, nullable) PDNavigationController *navigationPage;

@end
