//
//  RadTabBar.m
//  MedicalConsult
//
//  Created by User on 9/21/16.
//  Copyright © 2016 Erik Hitta. All rights reserved.
//

#import "RadTabBar.h"

@implementation RadTabBar

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
 */
- (void)drawRect:(CGRect)rect {
    // Drawing code
    [super drawRect:rect];
    
    CGFloat tapItemTopInset = 6.0f;
    CGFloat tapItemLeftInset = 0.0f;
    
    if ([UIScreen mainScreen].nativeBounds.size.height == 2436) {
        // iPhone X
        tapItemTopInset = tapItemTopInset + 4;
    }
    
    // Adjustment the point
    for (UITabBarItem *item in self.items) {
        item.imageInsets = UIEdgeInsetsMake(tapItemTopInset, tapItemLeftInset, -tapItemTopInset, -tapItemLeftInset);
        item.titlePositionAdjustment = UIOffsetZero;
    }
}

-(CGSize)sizeThatFits:(CGSize)size {
    
    CGSize sizeThatFits = [super sizeThatFits:size];
    sizeThatFits.height = TABBAR_HEIGHT;
    
    if ([UIScreen mainScreen].nativeBounds.size.height == 2436) {
        // iPhone X
        sizeThatFits.height = sizeThatFits.height + 26;
    }
    return sizeThatFits;
}

@end
