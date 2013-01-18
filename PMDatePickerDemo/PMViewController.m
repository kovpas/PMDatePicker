//
//  PMViewController.m
//  PMDatePicker
//
//  Created by Pavel Mazurin on 1/14/13.
//  Copyright (c) 2013 Pavel Mazurin. All rights reserved.
//

#import "PMViewController.h"
#import "PMDatePicker.h"
#import <QuartzCore/QuartzCore.h>

@interface PMViewController ()

@property (nonatomic, strong) IBOutlet PMDatePicker *datePicker;
@property (nonatomic, strong) IBOutlet UIButton *localeButton;
@property (nonatomic, strong) IBOutlet UILabel *dateLabel;

@end

@implementation PMViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    _datePicker.selectionImageView.layer.borderWidth = 1.0f;
    _datePicker.selectionImageView.layer.borderColor = [[UIColor darkGrayColor] CGColor];
    _datePicker.frameImageView.layer.borderWidth = 1.0f;
    _datePicker.frameImageView.layer.borderColor = [[UIColor darkGrayColor] CGColor];

    _datePicker.rowHeight = 30;
    _datePicker.font = [UIFont boldSystemFontOfSize:15];
    _datePicker.datePickerMode = UIDatePickerModeTime;
    _datePicker.minuteInterval = 4;
    _datePicker.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
    [_datePicker addTarget:self
                    action:@selector(dateChanged:)
          forControlEvents:UIControlEventValueChanged];
}

- (void) dateChanged:(id)sender
{
    _dateLabel.text = [NSString stringWithFormat:@"%@", _datePicker.date];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self today:nil];
    [_localeButton setTitle:_datePicker.locale.localeIdentifier forState:UIControlStateNormal];
}

- (IBAction)today:(id)sender
{
    [_datePicker setDate:[NSDate date] animated:YES];
}

- (IBAction)changeLocale:(id)sender
{
    static NSLocale *locale;
    if (!locale || [locale.localeIdentifier rangeOfString:@"ko"].location != NSNotFound)
    {
        locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
    }
    else if (locale && [locale.localeIdentifier rangeOfString:@"ru"].location != NSNotFound)
    {
        locale = [[NSLocale alloc] initWithLocaleIdentifier:@"ko"];
    }
    else
    {
        locale = [[NSLocale alloc] initWithLocaleIdentifier:@"ru"];
    }
    [[self datePicker] setLocale:locale];
    [(UIButton *)sender setTitle:locale.localeIdentifier forState:UIControlStateNormal];
}
@end
