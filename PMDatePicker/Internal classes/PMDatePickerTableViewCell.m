//
//  PMDatePickerTableViewCell.m
//  PMDatePicker
//
//  Created by Pavel S. Mazurin on 1/13/13.
//  Copyright (c) 2013 Pavel Mazurin. All rights reserved.
//

#import "PMDatePickerTableViewCell.h"

@implementation PMDatePickerTableViewCell

- (PMDatePickerTableViewCell *)initWithReuseIdentifier:(NSString *)reuseIdentifier
                                    labelAlignment:(UITextAlignment)alignment
{
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
    if (self)
    {
        [self setSelectionStyle:UITableViewCellSelectionStyleNone];
        self.backgroundColor = [UIColor clearColor];
        
        _label = [[UILabel alloc] initWithFrame:CGRectInset(self.contentView.bounds, (alignment==UITextAlignmentCenter)?0.0f:10.0f, 0)];
        _label.textAlignment = alignment;
        _label.clipsToBounds = NO;
        _label.backgroundColor = [UIColor clearColor];
        _label.shadowColor = UIColorMakeRGBA(249, 250, 249, 0.7);
        _label.shadowOffset = CGSizeMake(0, 1);
        _label.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        
        [self.contentView addSubview:_label];
    }
    return self;
}

- (void)setType:(PMStringTableViewCellType)type
{
    switch (type) {
        case PMStringTableViewCellTypeDisabled:
            _label.textColor = UIColorMakeRGB(171, 179, 171);
            break;
        case PMStringTableViewCellTypeToday:
            _label.textColor = UIColorMakeRGB(125, 163, 97);
            break;
        default:
            _label.textColor = UIColorMakeRGB(67, 71, 51);
            break;
    }
    
    _type = type;
}
@end
