//
//  RadTableBackgroundView.m
//  MedicalConsult
//
//  Created by User on 9/22/16.
//  Copyright © 2016 Erik Hitta. All rights reserved.
//

#import "RadTableBackgroundView.h"

@interface RadTableBackgroundView()

@property (nonatomic, strong) RadTableBackgroundView *customView;

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *captionLabel;

@end


@implementation RadTableBackgroundView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // 1. Load the .xib file .xib file must match classname
        NSString *className = NSStringFromClass([self class]);
        _customView = [[[NSBundle mainBundle] loadNibNamed:className owner:self options:nil] firstObject];
        _customView.frame = self.bounds;
        // 2. Set the bounds if not set by programmer (i.e. init called)
        if(CGRectIsEmpty(frame)) {
            self.bounds = _customView.bounds;
        }
        
        // 3. Add as a subview
        [self addSubview:_customView];
        
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if(self) {
        
        // 1. Load .xib file
        NSString *className = NSStringFromClass([self class]);
        _customView = [[[NSBundle mainBundle] loadNibNamed:className owner:self options:nil] firstObject];
        _customView.frame = self.bounds;
        // 2. Add as a subview
        [self addSubview:_customView];
        
    }
    return self;
}

- (void)setTitle:(NSString *)title caption:(NSString *)caption{
    
    self.titleLabel.text = title;
    self.captionLabel.text = caption;
}

@end
