//
//  ViewController.m
//  PDNavigationController
//
//  Created by liang on 2018/2/22.
//  Copyright © 2018年 PipeDog. All rights reserved.
//

#import "ViewController.h"

static inline UIColor *random_color() {
    CGFloat hue = arc4random() % 100 / 100.0;
    CGFloat saturation = (arc4random() % 50 / 100) + 0.5;
    CGFloat brightness = (arc4random() % 50 / 100) + 0.5;
    return [UIColor colorWithHue:hue saturation:saturation brightness:brightness alpha:1];
}

static NSInteger kPageCount = 0;

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.view.backgroundColor = random_color();
    self.navigationController.interactivePopGestureRecognizer.enabled = NO;
    
    self.title = [NSString stringWithFormat:@"%zd", kPageCount];
    kPageCount += 1;
}

- (IBAction)pushToNextPage:(id)sender {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    ViewController *vc = [storyboard instantiateViewControllerWithIdentifier:@"vc"];
    [self.navigationController pushViewController:vc animated:YES];
}

- (IBAction)popToRootPage:(id)sender {
    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (IBAction)popToPage:(id)sender {
    kPageCount = 2;
    
    for (UIViewController *vc in self.navigationController.viewControllers) {
        if ([vc.title integerValue] == kPageCount) {
            [self.navigationController popToViewController:vc animated:YES];
            break;
        }
    }
}

- (IBAction)popToLastPage:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

@end
