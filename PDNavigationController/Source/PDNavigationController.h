//
//  PDNavigationController.h
//  PDNavigationController
//
//  Created by liang on 2018/2/22.
//  Copyright © 2018年 PipeDog. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 * Use PDNavigationController, you should set the pop gesture of the system to NO.
 * @eg:
        self.navigationController.interactivePopGestureRecognizer.enabled = NO;
 */
@interface PDNavigationController : UINavigationController

@property (nonatomic, assign) BOOL canDragBack; // default is YES

@end
