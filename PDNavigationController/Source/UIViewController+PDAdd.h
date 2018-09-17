//
//  UIViewController+PDAdd.h
//  PDNavigationController
//
//  Created by liang on 2018/9/17.
//  Copyright © 2018年 PipeDog. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol PDBackButtonEventProtocol <NSObject>

@optional
- (BOOL)regularBackButtonEvent;
- (BOOL)specialBackButtonEvent;

@end

@interface UIViewController (PDAdd) <PDBackButtonEventProtocol>

@end
