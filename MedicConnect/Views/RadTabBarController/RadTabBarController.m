//
//  RadTabBarControllerViewController.m
//  MedicalConsult
//
//  Created by User on 9/21/16.
//  Copyright © 2016 Erik Hitta. All rights reserved.
//

#import "RadTabBarController.h"
#import "RadTabBar.h"

@interface RadTabBarController () <UITabBarControllerDelegate>

@end

@implementation RadTabBarController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.delegate = self;
    
    // Default tab - Profile
    self.selectedIndex = 1;
    
    // Add border on top
    UIView *borderTop = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, 0.5)];
    borderTop.backgroundColor = [UIColor colorWithRed:229/255.0 green:229/255.0 blue:229/255.0 alpha:1.0];
    [self.tabBar addSubview:borderTop];
    
    // Tab Selected Image Color
    self.tabBar.tintAdjustmentMode = UIViewTintAdjustmentModeNormal;
    [self.tabBar setTintColor:COLOR_TABBAR_TINT];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(gotoProfileScreen:) name:@"gotoProfileScreen" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(gotoCallHistoryScreen:) name:@"gotoCallHistoryScreen" object:nil];
    
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self.tabBar invalidateIntrinsicContentSize];
}

- (void)gotoProfileScreen:(NSNotification *)notification {
    UINavigationController *nc = self.viewControllers[1];
    
    if (self.selectedIndex == 1 && nc.viewControllers.count == 1) {
        // Reload Profile
        [[NSNotificationCenter defaultCenter] postNotificationName:@"userUpdated" object:nil];
    }
    
    self.selectedIndex = 1;
    
    [nc dismissViewControllerAnimated:NO completion:nil];
    [nc popToRootViewControllerAnimated:NO];
}
    
- (void)gotoCallHistoryScreen:(NSNotification *)notification {
    UINavigationController *nc = self.viewControllers[0];
    [nc dismissViewControllerAnimated:NO completion:nil];
    [nc popToRootViewControllerAnimated:NO];
    
    self.selectedIndex = 0;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController {
    if ([viewController isKindOfClass:[UINavigationController class]]) {
        [(UINavigationController *)viewController popToRootViewControllerAnimated:NO];
    }
    
    return YES;
}

@end
