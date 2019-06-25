//
//  PDNavigationController.h
//  PDNavigationController
//
//  Created by liang on 2018/2/22.
//  Copyright © 2018年 PipeDog. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PDNavigationController : UINavigationController

@property (nonatomic, assign) BOOL canDragBack; ///< Default is YES.

- (void)popViewControllerAnimated:(BOOL)animated completion:(void (^ __nullable)(__kindof UIViewController *viewController))completion;

- (void)popToViewController:(UIViewController *)viewController animated:(BOOL)animated completion:(void (^ __nullable)(NSArray<__kindof UIViewController *> *viewControllers))completion;

- (void)popToRootViewControllerAnimated:(BOOL)animated completion:(void (^ __nullable)(NSArray<__kindof UIViewController *> *viewControllers))completion;

@end
  
NS_ASSUME_NONNULL_END
