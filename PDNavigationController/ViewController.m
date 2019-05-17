//
//  ViewController.m
//  PDNavigationController
//
//  Created by liang on 2018/2/22.
//  Copyright © 2018年 PipeDog. All rights reserved.
//

#import "ViewController.h"
#import "PDNavigationController.h"
#import "UIViewController+PDAdd.h"

static inline UIColor *random_color() {
    CGFloat hue = arc4random() % 100 / 100.0;
    CGFloat saturation = (arc4random() % 50 / 100) + 0.5;
    CGFloat brightness = (arc4random() % 50 / 100) + 0.5;
    return [UIColor colorWithHue:hue saturation:saturation brightness:brightness alpha:1];
}

static NSInteger kPageCount = 0;

@interface ViewController () <PDBackButtonEventProtocol>

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.view.backgroundColor = random_color();

    self.title = [NSString stringWithFormat:@"%zd", kPageCount];
    kPageCount += 1;
}

- (IBAction)pushToNextPage:(id)sender {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    ViewController *vc = [storyboard instantiateViewControllerWithIdentifier:@"vc"];
    [self.navigationController pushViewController:vc animated:YES];
}

- (IBAction)popToRootPage:(id)sender {
    kPageCount = 0;
    PDNavigationController *navigationController = (PDNavigationController *)self.navigationController;
    [navigationController popToRootViewControllerAnimated:YES completion:nil];
}

- (IBAction)popToPage:(id)sender {
    kPageCount = 2;
    PDNavigationController *navigationController = (PDNavigationController *)self.navigationController;
    
    for (UIViewController *vc in self.navigationController.viewControllers) {
        if ([vc.title integerValue] == kPageCount) {
            [navigationController popToViewController:vc animated:YES completion:nil];
            break;
        }
    }
}

- (IBAction)popToLastPage:(id)sender {
    PDNavigationController *navigationController = (PDNavigationController *)self.navigationController;
    [navigationController popViewControllerAnimated:YES completion:nil];
}

#pragma mark - PDBackButtonEventProtocol
- (BOOL)specialBackButtonEvent {
    PDNavigationController *navigationController = (PDNavigationController *)self.navigationController;
    [navigationController popViewControllerAnimated:YES completion:nil];
    NSLog(@"===> %s", __FUNCTION__);
    return NO;
}

- (BOOL)regularBackButtonEvent {
    PDNavigationController *navigationController = (PDNavigationController *)self.navigationController;
    [navigationController popViewControllerAnimated:YES completion:nil];
    NSLog(@"===> %s", __FUNCTION__);
    return NO;
}

@end
