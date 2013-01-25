//
//  NSLocale+Helpers.m
//  PMDatePicker
//
//  Created by Pavel S. Mazurin on 1/15/13.
//  Copyright (c) 2013 Pavel Mazurin. All rights reserved.
//

#import "NSLocale+Helpers.h"

@implementation NSLocale (Helpers)

- (BOOL)is24Hour
{
    NSString *dateFormat = [NSDateFormatter dateFormatFromTemplate:@"j"
                                                           options:0
                                                            locale:self];
    return [dateFormat rangeOfString:@"a"].location == NSNotFound;
}

@end
