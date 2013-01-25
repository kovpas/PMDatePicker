//
//  PMDatePicker.m
//  PMDatePicker
//
//  Created by Pavel S. Mazurin on 1/13/13.
//  Copyright (c) 2013 Pavel Mazurin. All rights reserved.
//

#import "PMDatePicker.h"
#import "PMTableView.h"
#import "PMDatePickerTableViewCell.h"
#import "NSDate+Helpers.h"
#import "NSLocale+Helpers.h"

static const NSUInteger verticalPadding = 10.0f / 320.0f;

// TODO: I don't like this approach. I think we should indicate some "minimal" width and then
// calculate it dynamically.
//                                  width for standard UIDatePicker bounds ------v
#define PMDatePickerWidthsForPickerTypes @{@(PMDatePickerTagCountdownMinute): @(50.0 / 320.0), \
                                           @(PMDatePickerTagCountdownHour)  : @(50.0 / 320.0), \
                                           @(PMDatePickerTagAmPm)           : @(50.0 / 320.0), \
                                           @(PMDatePickerTagMinute)         : @(50.0 / 320.0), \
                                           @(PMDatePickerTagHour)           : @(60.0 / 320.0), \
                                           @(PMDatePickerTagDay)            : @{@"short": @(50.0 / 320.0)\
                                                                                , @"long": @(74.0 / 320.0)}, \
                                           @(PMDatePickerTagMonth)          : @{@"short": @(74.0 / 320.0)\
                                                                                , @"long": @(152.0 / 320.0)},\
                                           @(PMDatePickerTagYear)           : @{@"short": @(78.0 / 320.0)\
                                                                                , @"long": @(100.0 / 320.0)}, \
                                           @(PMDatePickerTagDate)           : @(150.0 / 320.0)}

#define PMDatePickerTableModesForPickerTypes @{@(PMDatePickerTagCountdownMinute): @(PMTableViewModeCircular), \
                                               @(PMDatePickerTagCountdownHour)  : @(PMTableViewModeDefault), \
                                               @(PMDatePickerTagAmPm)           : @(PMTableViewModeDefault), \
                                               @(PMDatePickerTagMinute)         : @(PMTableViewModeCircular), \
                                               @(PMDatePickerTagHour)           : @(PMTableViewModeCircular), \
                                               @(PMDatePickerTagDay)            : @(PMTableViewModeCircular), \
                                               @(PMDatePickerTagMonth)          : @(PMTableViewModeCircular),\
                                               @(PMDatePickerTagYear)           : @(PMTableViewModeDefault), \
                                               @(PMDatePickerTagDate)           : @(PMTableViewModeDefault)}

#define PMDateFormatsForPickerModes @{@(UIDatePickerModeTime)           : @"jjmm", \
                                      @(UIDatePickerModeDate)           : @"ddMMMMyyyy", \
                                      @(UIDatePickerModeDateAndTime)    : @"EEEddMMMyyyyhhmm", \
                                      @(UIDatePickerModeCountDownTimer) : @"hhmm"}

#define PMPickerTypeForDateFormatSymbols @{@"a": @(PMDatePickerTagAmPm), \
                                           @"m": @(PMDatePickerTagMinute), \
                                           @"h": @(PMDatePickerTagHour), \
                                           @"H": @(PMDatePickerTagHour), \
                                           @"d": @(PMDatePickerTagDay), \
                                           @"M": @(PMDatePickerTagMonth), \
                                           @"y": @(PMDatePickerTagYear), \
                                           @"E": @(PMDatePickerTagDate)}

#define PMPickerColumnsForPickerModes @{@(UIDatePickerModeTime)           : @[@(PMDatePickerTagHour), @(PMDatePickerTagMinute), @(PMDatePickerTagAmPm)], \
                                        @(UIDatePickerModeDate)           : @[@(PMDatePickerTagDay), @(PMDatePickerTagMonth), @(PMDatePickerTagYear)], \
                                        @(UIDatePickerModeDateAndTime)    : @[@(PMDatePickerTagDate), @(PMDatePickerTagYear), @(PMDatePickerTagHour), @(PMDatePickerTagMinute)], \
                                        @(UIDatePickerModeCountDownTimer) : @[@(PMDatePickerTagHour), @(PMDatePickerTagMinute)]}

typedef NS_ENUM(NSInteger, PMDatePickerTags) {
    PMDatePickerTagCountdownMinute,
    PMDatePickerTagCountdownHour,
    PMDatePickerTagAmPm,
    PMDatePickerTagMinute,
    PMDatePickerTagHour,
    PMDatePickerTagDay,
    PMDatePickerTagMonth,
    PMDatePickerTagYear,
    PMDatePickerTagDate,
    _PMDatePickerTagCount
};

static const NSDictionary* widthsForColumnTypes;
static const NSDictionary* modesForColumnTypes;
static const NSDictionary* dateFormatsForPickerModes;
static const NSDictionary* columnsForPickerModes;
static const NSDictionary* tagsForDateFormatSymbols;

@interface PMDatePicker ()
@property (nonatomic, strong) NSMutableDictionary *tableViewsByTag;
@property (nonatomic, strong) NSMutableDictionary *visibleTableViewsByTag;
@property (nonatomic, strong) NSMutableArray *tableViewOverlays;
@property (nonatomic, strong) NSMutableArray *monthNameStrings;
@property (nonatomic, strong) NSMutableArray *dayStrings;

@property (nonatomic, strong) NSDateComponents *todayComponents;
@property (nonatomic, strong) NSDateComponents *currentDateComponents;
@property (nonatomic, strong) NSDateComponents *maxDateComponents;
@property (nonatomic, strong) NSDateComponents *minDateComponents;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;
@property (nonatomic, assign) CGFloat horizontalPadding;
@property (nonatomic, assign) CGFloat verticalPadding;
@property (nonatomic, assign) BOOL is24Hour;
@property (nonatomic, assign) BOOL monthToLeft;
@property (nonatomic, assign) NSInteger numberOfDaysInSelectedMonth;

@property (nonatomic, strong) UIImageView *frameImageView;
@property (nonatomic, strong) UIImageView *shadowImageView;
@property (nonatomic, strong) UIImageView *selectionImageView;

- (void) initialize;
- (void) initializeTableViewWithTag:(PMDatePickerTags)tag;
- (void) reloadComponents;
- (void) setTableViewsOrder:(NSArray *)order;
- (BOOL) checkDateConstraints:(BOOL)animated;
- (CGFloat)widthForTableWithTag:(PMDatePickerTags)tag;

@end

@implementation PMDatePicker

#pragma mark - view life cycle -
- (void)dealloc
{
    [[_tableViewsByTag allValues] makeObjectsPerformSelector:@selector(setTableDelegate:)
                                                  withObject:nil];
    [[_tableViewsByTag allValues] makeObjectsPerformSelector:@selector(setTableDataSource:)
                                                  withObject:nil];
}

- (id)init
{
    self = [super initWithFrame:CGRectMake(0.0f, 0.0f, 320.0f, 216.0f)];
    
    if (!self)
    {
        return nil;
    }
    
    [self initialize];
    
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    
    if (!self)
    {
        return nil;
    }
    
    [self initialize];
    
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (!self)
    {
        return nil;
    }
    
    [self initialize];
    
    return self;
}

- (void) didMoveToSuperview;
{
    [super didMoveToSuperview];
    self.locale = _locale;
    self.date = _date;
}

- (void) initializeTableViewWithTag:(PMDatePickerTags)tag
{
    CGRect frame = CGRectIntegral(CGRectMake(0.0f, 0.0f
                                             , [self widthForTableWithTag:tag]
                                             , self.bounds.size.height));
    PMDatePickerTableView *tableView = [[PMDatePickerTableView alloc] initWithFrame:frame];
    tableView.tableDelegate = self;
    tableView.tableDataSource = self;
    tableView.showsVerticalScrollIndicator = NO;
    tableView.tag = tag;
    tableView.mode = [modesForColumnTypes[@(tag)] integerValue];
    
    [_tableViewsByTag setObject:tableView forKey:@(tag)];
    
    UIImageView *tableViewOverlay = [[UIImageView alloc] init];
    [_tableViewOverlays addObject:tableViewOverlay];
}

- (void) initialize
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        widthsForColumnTypes = PMDatePickerWidthsForPickerTypes;
        modesForColumnTypes = PMDatePickerTableModesForPickerTypes;
        dateFormatsForPickerModes = PMDateFormatsForPickerModes;
        columnsForPickerModes = PMPickerColumnsForPickerModes;
        tagsForDateFormatSymbols = PMPickerTypeForDateFormatSymbols;
    });
    
    _horizontalPadding = 20.0f / 320.0f * self.frame.size.width;
    _verticalPadding = verticalPadding * self.frame.size.height;
    _minuteInterval = 1;
    _rowHeight = 45.0f;

    _datePickerMode = UIDatePickerModeDate;
    _calendar = [NSCalendar currentCalendar];
    _date = [NSDate date];
    _font = [UIFont boldSystemFontOfSize:24]; // default
    
    _frameImageView = [[UIImageView alloc] initWithFrame:self.bounds];
    [self addSubview:_frameImageView];

    _shadowImageView = [[UIImageView alloc] initWithFrame:CGRectInset(self.bounds
                                                                    , _horizontalPadding
                                                                    , _verticalPadding)];
    _shadowImageView.contentMode = UIViewContentModeScaleToFill;
    [self addSubview:_shadowImageView];

    _selectionImageView = [[UIImageView alloc] initWithFrame:CGRectZero];
    [self setSelectionImageViewHeight:_rowHeight];
    [self addSubview:_selectionImageView];
    
    _visibleTableViewsByTag = [NSMutableDictionary dictionaryWithCapacity:_PMDatePickerTagCount];
    _tableViewsByTag = [NSMutableDictionary dictionaryWithCapacity:_PMDatePickerTagCount];
    _tableViewOverlays = [NSMutableArray arrayWithCapacity:_PMDatePickerTagCount];

    [self initializeTableViewWithTag:PMDatePickerTagCountdownMinute];
    [self initializeTableViewWithTag:PMDatePickerTagCountdownHour];
    [self initializeTableViewWithTag:PMDatePickerTagAmPm];
    [self initializeTableViewWithTag:PMDatePickerTagMinute];
    [self initializeTableViewWithTag:PMDatePickerTagHour];
    [self initializeTableViewWithTag:PMDatePickerTagDay];
    [self initializeTableViewWithTag:PMDatePickerTagMonth];
    [self initializeTableViewWithTag:PMDatePickerTagYear];
    [self initializeTableViewWithTag:PMDatePickerTagDate];
    
    _dateFormatter = [[NSDateFormatter alloc] init];
}

- (void) reloadComponents
{
    NSString *dateFormat = [NSDateFormatter dateFormatFromTemplate:dateFormatsForPickerModes[@(_datePickerMode)]
                                                           options:0
                                                            locale:_locale];
    NSInteger index = [dateFormat hasPrefix:@"'"]?1:0;
    NSArray *comps = [dateFormat componentsSeparatedByString:@"'"];
    NSMutableString *df = [NSMutableString string];
    for (; index < [comps count]; index += 2)
    {
        [df appendString:comps[index]];
    }
    dateFormat = df;
    
    NSMutableSet *componentsSet = [NSMutableSet set];
    unichar *_characters;
    NSUInteger _stringLength = [dateFormat length];
    _characters = calloc(_stringLength, sizeof(unichar));
    [dateFormat getCharacters:_characters range:NSMakeRange(0, _stringLength)];
    
    for (NSUInteger i = 0; i < _stringLength; i++)
    {
        unichar character = _characters[i];
        NSString *component = [NSString stringWithCharacters:&character length:1];
        if (tagsForDateFormatSymbols[component])
        {
            [componentsSet addObject:component];
        }
    }
    
    NSMutableArray *arr = [NSMutableArray arrayWithCapacity:[componentsSet count]];
    NSMutableDictionary *indexForComponent = [NSMutableDictionary dictionaryWithCapacity:[componentsSet count]];
    
    for (NSString *component in componentsSet)
    {
        NSNumber *index = @([dateFormat rangeOfString:component].location);
        [arr addObject:index];
        [indexForComponent setObject:index forKey:component];
    }
    
    [arr sortUsingSelector:@selector(compare:)];
    NSMutableArray *order = [arr mutableCopy];
    
    for (NSString *component in componentsSet)
    {
        [order replaceObjectAtIndex:[arr indexOfObject:indexForComponent[component]]
                         withObject:tagsForDateFormatSymbols[component]];
    }
    
    [self setTableViewsOrder:order];
    [[_tableViewsByTag allValues] makeObjectsPerformSelector:@selector(reloadData)];
}

#pragma mark - public methods -
- (void) setLocale:(NSLocale *)locale
{
    _locale = locale;
    if (locale == nil)
    {
        _locale = [NSLocale currentLocale];
    }
    
    _is24Hour = [_locale is24Hour];
    if (_datePickerMode == UIDatePickerModeDate)
    {
        NSString *dateFormat = [NSDateFormatter dateFormatFromTemplate:dateFormatsForPickerModes[@(UIDatePickerModeDate)]
                                                               options:0
                                                                locale:_locale];
        _monthToLeft = [dateFormat rangeOfString:@"d"].location < [dateFormat rangeOfString:@"M"].location;
    }
    _dateFormatter.locale = _locale;
    
    _dayStrings = [NSMutableArray arrayWithCapacity:31];
    NSDateComponents *c = [[NSDateComponents alloc] init];
    NSString *dayFormatString = [NSDateFormatter dateFormatFromTemplate:@"dd"
                                                                options:0
                                                                 locale:_locale];
    for (NSInteger i = 0; i < 31; i++)
    {
        c.day = i + 1;
        NSDate *dayDate = [_calendar dateFromComponents:c];
        [_dateFormatter setDateFormat:dayFormatString];
        [_dayStrings addObject:[_dateFormatter stringFromDate:dayDate]];
    }
    
    [self reloadComponents];

    self.date = _date;
}

- (void)setDate:(NSDate *)date
{
    [self setDate:date animated:NO];
}

- (void)setDate:(NSDate *)date animated:(BOOL)animated
{
    [self setDate:date animated:animated dontAutoscrollTablesWithTags:nil];
}

- (void)setDate:(NSDate *)date animated:(BOOL)animated dontAutoscrollTablesWithTags:(NSArray *)tagsToIgnore
{
    _date = date;
    if (!_date)
    {
        _date = [NSDate date];
    }
    [self sendActionsForControlEvents:UIControlEventValueChanged];

    _numberOfDaysInSelectedMonth = [_calendar rangeOfUnit:NSDayCalendarUnit
                                                   inUnit:NSMonthCalendarUnit
                                                  forDate:_date].length;

    if (![self checkDateConstraints:animated] && (_datePickerMode != UIDatePickerModeCountDownTimer))
    {
        _currentDateComponents = [_calendar components:(NSYearCalendarUnit
                                                        | NSMonthCalendarUnit
                                                        | NSDayCalendarUnit
                                                        | NSHourCalendarUnit
                                                        | NSMinuteCalendarUnit )
                                              fromDate:_date];
        for (NSNumber *tag in columnsForPickerModes[@(_datePickerMode)])
        {
            if ([tagsToIgnore containsObject:tag])
            {
                continue;
            }
            PMDatePickerTableView *tableView = _visibleTableViewsByTag[tag];
            NSInteger row = -1;
            [tableView setNeedsLayout];
            switch ([tag integerValue]) {
                case PMDatePickerTagYear:
                    row += [_currentDateComponents year];
                    break;
                case PMDatePickerTagMonth:
                    row += [_currentDateComponents month];
                    break;
                case PMDatePickerTagDay:
                    row += [_currentDateComponents day];
                    break;
                case PMDatePickerTagHour:
                    row += [_currentDateComponents hour] + 1;
                    break;
                case PMDatePickerTagMinute:
                    row += floor((double)[_currentDateComponents minute] / (double)_minuteInterval) + 1;
                    break;
                case PMDatePickerTagAmPm:
                    row += ([_currentDateComponents hour] > 12)?2:1;
                    break;
                    
                default:
                    break;
            }
            [tableView scrollToRowAtIndex:row
                         atScrollPosition:UITableViewScrollPositionMiddle
                                 animated:animated];
        }
    }
}

- (void)setMaximumDate:(NSDate *)maximumDate
{
    _maximumDate = maximumDate;
    if (!maximumDate)
    {
        _maxDateComponents = nil;
        return;
    }
    
    _maxDateComponents = [_calendar components:(NSYearCalendarUnit
                                                | NSMonthCalendarUnit
                                                | NSDayCalendarUnit
                                                | NSHourCalendarUnit
                                                | NSMinuteCalendarUnit )
                                      fromDate:_maximumDate];
    [self checkDateConstraints:NO];
}

- (void)setMinimumDate:(NSDate *)minimumDate
{
    _minimumDate = minimumDate;
    if (!minimumDate)
    {
        _minDateComponents = nil;
        return;
    }
    
    _minDateComponents = [_calendar components:(NSYearCalendarUnit
                                                | NSMonthCalendarUnit
                                                | NSDayCalendarUnit
                                                | NSHourCalendarUnit
                                                | NSMinuteCalendarUnit )
                                      fromDate:_minimumDate];
    [self checkDateConstraints:NO];
}


- (void)setCalendar:(NSCalendar *)calendar
{
    _calendar = calendar;
	_todayComponents = [_calendar components:(NSYearCalendarUnit
                                              | NSMonthCalendarUnit
                                              | NSDayCalendarUnit
                                              | NSHourCalendarUnit
                                              | NSMinuteCalendarUnit )
                                    fromDate:[NSDate date]];
    
    if (_date)
    {
        // renew date so component reposition it's tableviews
        self.date = _date;
    }
}

- (void)setDatePickerMode:(UIDatePickerMode)datePickerMode
{
    _datePickerMode = datePickerMode;
    [self reloadComponents];
}

- (BOOL) checkDateConstraints:(BOOL)animated
{
    if ([[_date dateWithoutTime] isBefore:[_minimumDate dateWithoutTime]])
    {
        [self setDate:_minimumDate animated:animated];
        return YES;
    }
    else if ([[_date dateWithoutTime] isAfter:[_maximumDate dateWithoutTime]])
    {
        [self setDate:_maximumDate animated:animated];
        return YES;
    }
    else if ([_currentDateComponents day] > _numberOfDaysInSelectedMonth)
    {
        _currentDateComponents.day = _numberOfDaysInSelectedMonth;
        _date = [_calendar dateFromComponents:_currentDateComponents];
        [self setDate:_date animated:animated];
        return YES;        
    }
    
    return NO;
}

- (void)setRowHeight:(CGFloat)rowHeight
{
    _rowHeight = rowHeight;
    
    for (NSNumber *tag in _tableViewsByTag)
    {
        PMDatePickerTableView *tableView = _tableViewsByTag[tag];
        tableView.rowHeight = _rowHeight;
        [tableView reloadData];
    }
    [self setSelectionImageViewHeight:_rowHeight];
}

- (void)setMinuteInterval:(NSInteger)minuteInterval
{
    if ((minuteInterval <= 0) || (minuteInterval > 30) || (60 % minuteInterval != 0))
    {
        NSLog( @"interval must be evenly divided into 60. default is 1. min is 1, max is 30" );
        _minuteInterval = 1;

        return;
    }
    
    _minuteInterval = minuteInterval;
}

#pragma mark - PMTableViewDataSource -

- (NSInteger)numberOfRowsInTableView:(PMTableView *)tableView
{
    NSInteger result = 0;
    switch (tableView.tag) {
        case PMDatePickerTagMonth:
            result = 12;
            break;
        case PMDatePickerTagDay:
            result = 31;
            break;
        case PMDatePickerTagYear:
            result = 9998;
            break;
        case PMDatePickerTagHour:
        {
            result = 24;
            if (!_is24Hour)
            {
                result = result / 2;
            }

            break;
        }
        case PMDatePickerTagMinute:
            result = 60 / [self minuteInterval];
            break;
        case PMDatePickerTagAmPm:
            result = 2;
            break;
            
        default:
            break;
    }
    return result;
}

- (UITableViewCell *)tableView:(PMDatePickerTableView *)tableView cellForRowAtIndex:(NSInteger)index
{
    PMDatePickerTableViewCell *cell = (PMDatePickerTableViewCell *)[tableView dequeueReusableCell];
    if (!cell)
    {
        cell = [[PMDatePickerTableViewCell alloc] initWithReuseIdentifier:@"PMDatePickerTableViewCellId"
                                                           labelAlignment:(tableView.tag == PMDatePickerTagMonth)?UITextAlignmentRight:UITextAlignmentCenter];
        cell.label.font = _font;
    }

    cell.type = PMStringTableViewCellTypeDefault;
    switch (tableView.tag) {
        case PMDatePickerTagAmPm:
        {
            cell.label.text = (index == 0)?@"AM":@"PM";
            cell.label.font = [_font fontWithSize:(_font.pointSize - 4.0f)];

            break;
        }
        case PMDatePickerTagMinute:
        {
            NSInteger minute = index;
            cell.label.text = [NSString stringWithFormat:@"%02d", minute * _minuteInterval];
            break;
        }
        case PMDatePickerTagHour:
        {
            NSInteger hour = index;
            if (!_is24Hour)
            {
                hour = (index + 11) % 12 + 1;
            }
//            NSInteger day = _currentDateComponents.day;
//            NSInteger month = _currentDateComponents.month;
//            NSInteger year = _currentDateComponents.year;
            cell.label.text = [NSString stringWithFormat:@"%d", hour];
//            if ((_minimumDate && (((year == [_minDateComponents year]) && (month == [_minDateComponents month]) && (day < [_minDateComponents day]))))
//                     || (_maximumDate && ((year == [_maxDateComponents year]) && (month == [_maxDateComponents month]) && (day > [_maxDateComponents day]))))
//            {
//                cell.type = PMStringTableViewCellTypeDisabled;
//            }
            break;
        }
        case PMDatePickerTagDay:
        {
            NSInteger day = index + 1;
            NSInteger month = _currentDateComponents.month;
            NSInteger year = _currentDateComponents.year;
            cell.label.text = _dayStrings[index];
            if (day == [_todayComponents day])
            {
                cell.type = PMStringTableViewCellTypeToday;
            }
            else if ((_minimumDate && (((year == [_minDateComponents year])
                                        && (month == [_minDateComponents month])
                                        && (day < [_minDateComponents day]))))
                     || (_maximumDate && ((year == [_maxDateComponents year])
                                       && (month == [_maxDateComponents month])
                                       && (day > [_maxDateComponents day])))
                     || day > _numberOfDaysInSelectedMonth)
            {
                cell.type = PMStringTableViewCellTypeDisabled;
            }
            break;
        }
        case PMDatePickerTagMonth:
        {
            NSInteger month = index + 1;
            NSInteger year = _currentDateComponents.year;
            cell.label.text = [_dateFormatter monthSymbols][month - 1];
            if (month == [_todayComponents month])
            {
                cell.type = PMStringTableViewCellTypeToday;
            }
            else if ((_minimumDate && ((year == [_minDateComponents year])
                                       && (month < [_minDateComponents month])))
                  || (_maximumDate && ((year == [_maxDateComponents year])
                                       && (month > [_maxDateComponents month]))))
            {
                cell.type = PMStringTableViewCellTypeDisabled;
            }
            UITextAlignment alignment = UITextAlignmentRight;
            if (_monthToLeft)
            {
                alignment = UITextAlignmentLeft;
            }
            cell.label.textAlignment = alignment;


            break;
        }
        case PMDatePickerTagYear:
        {
            NSInteger year = index + 1;
            NSDateComponents *c = [[NSDateComponents alloc] init];
            c.year = year;
            NSDate *yearDate = [_calendar dateFromComponents:c];
            [_dateFormatter setDateFormat:[NSDateFormatter dateFormatFromTemplate:@"yyyy"
                                                                          options:0 locale:_locale]];
            cell.label.text = [_dateFormatter stringFromDate:yearDate];
            cell.label.textAlignment = UITextAlignmentCenter;
            if (year == [_todayComponents year])
            {
                cell.type = PMStringTableViewCellTypeToday;
            }
            else if ((_minimumDate && (year < [_minDateComponents year])) || (_maximumDate && (year > [_maxDateComponents year])))
            {
                cell.type = PMStringTableViewCellTypeDisabled;
            }
            break;
        }
        default:
            break;
    }
    
    return cell;
}

#pragma mark - PMTableViewDelegate -

- (void) tableView:(PMTableView *)_tableView didSelectRowAtIndex:(NSInteger)index
{
    BOOL animateDate = NO;
    if ((_tableView.tag == PMDatePickerTagMonth) || (_tableView.tag == PMDatePickerTagYear))
    {
        NSDateComponents *comps = [_currentDateComponents copy];
        comps.day = 10; // random day in a middle of the month
        if (_tableView.tag == PMDatePickerTagMonth)
        {
            comps.month = index + 1;
        }
        else if (_tableView.tag == PMDatePickerTagYear)
        {
            comps.year = index + 1;
        }
        NSInteger numberOfDaysInSelectedMonth = [_calendar rangeOfUnit:NSDayCalendarUnit
                                                                inUnit:NSMonthCalendarUnit
                                                               forDate:[_calendar dateFromComponents:comps]].length;
        
        if (_currentDateComponents.day > numberOfDaysInSelectedMonth)
        {
            _currentDateComponents.day = numberOfDaysInSelectedMonth;
            animateDate = YES;
        }
    }
    
    switch (_tableView.tag) {
        case PMDatePickerTagAmPm:
            _currentDateComponents.hour = (_currentDateComponents.hour % 12) + (index == 0?0:12);
            break;
        case PMDatePickerTagMinute:
            _currentDateComponents.minute = index * _minuteInterval;
            break;
        case PMDatePickerTagHour:
        {
            NSInteger add = 0;
            if (!_is24Hour)
            {
                PMDatePickerTableView *tv = _visibleTableViewsByTag[@(PMDatePickerTagAmPm)];
                if ([tv indexForSelectedRow] == 1)
                {
                    add = 12;
                }
            }
            _currentDateComponents.hour = index + 1 + add;
            break;
        }
        case PMDatePickerTagDay:
            if (index + 1 > _numberOfDaysInSelectedMonth)
            {
                _currentDateComponents.day = _numberOfDaysInSelectedMonth;
                animateDate = YES;
            }
            else
            {
                _currentDateComponents.day = index + 1;
            }
            break;
        case PMDatePickerTagMonth:
            _currentDateComponents.month = index + 1;
            break;
        case PMDatePickerTagYear:
            _currentDateComponents.year = index + 1;
            break;
        default:
            break;
    }
    
    _date = [_calendar dateFromComponents:_currentDateComponents];
    _numberOfDaysInSelectedMonth = [_calendar rangeOfUnit:NSDayCalendarUnit
                                                   inUnit:NSMonthCalendarUnit
                                                  forDate:_date].length;

    for (NSNumber *tag in _visibleTableViewsByTag)
    {
        PMDatePickerTableView *tableView = _visibleTableViewsByTag[tag];
        if (_tableView.tag != [tag integerValue] && !tableView.autoscrolling)
        {
            [tableView reloadData];
        }
    }
    
    if (animateDate)
    {
        [self setDate:_date animated:YES];
        return;
    }

    if (![self checkDateConstraints:YES])
    {
        [self sendActionsForControlEvents:UIControlEventValueChanged];
    }
}

- (void)tableViewDidPassCycle:(PMTableView *)tableView withDirection:(PMTableViewScrollDirection)direction
{
    if (!_is24Hour && (tableView.tag == PMDatePickerTagHour))
    {
        NSInteger add = 12;
        if (direction == PMTableViewScrollDown)
        {
            add = -12;
        }
        _currentDateComponents.hour += add;
        [self setDate:[_calendar dateFromComponents:_currentDateComponents]
             animated:YES
dontAutoscrollTablesWithTags:@[@(PMDatePickerTagHour), @(PMDatePickerTagMinute)]];
    }
}

#pragma mark - view customization methods -
- (void)setColBackgroundImage:(UIImage *)colBackgroundImage
{
    for (UIImageView *iv in _tableViewOverlays)
    {
        iv.image = colBackgroundImage;
    }
}
#pragma mark - private methods -

- (void)setSelectionImageViewHeight:(CGFloat)newHeight
{
    CGRect frame = _selectionImageView.frame;
    frame.size.height = newHeight;
    frame.size.width = self.frame.size.width - _horizontalPadding * 2;
    _selectionImageView.frame = frame;
    _selectionImageView.center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
    _selectionImageView.frame = CGRectIntegral(_selectionImageView.frame);
}

- (void)setTableViewsOrder:(NSArray *)order
{
    [_tableViewOverlays makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [[_visibleTableViewsByTag allValues] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [_visibleTableViewsByTag removeAllObjects];
    
    CGFloat totalWidth = 0;
    for (NSNumber *tag in order)
    {
        totalWidth += [self widthForTableWithTag:[tag integerValue]];
    }
    CGFloat paddingDiff = _horizontalPadding;
    _horizontalPadding = (int)((self.frame.size.width - totalWidth) / 2);
    paddingDiff = _horizontalPadding - paddingDiff;
    
    CGFloat xCoord = _horizontalPadding;
    int i = 0;
    for (NSNumber *tag in order)
    {
        PMDatePickerTableView *tv = _tableViewsByTag[tag];
        tv.index = i;
        CGFloat width = [self widthForTableWithTag:[tag integerValue]];
        tv.frame = CGRectIntegral(CGRectMake(xCoord, tv.frame.origin.y
                                             , width, tv.frame.size.height));
        tv.contentSize = CGSizeMake(width, tv.contentSize.height);
        UIView *overlay = _tableViewOverlays[i];
        overlay.frame = tv.frame;
        [self addSubview:overlay];
        [self addSubview:tv];
        [_visibleTableViewsByTag setObject:tv forKey:tag];
        xCoord += width;
        i++;
    }
    _shadowImageView.frame = CGRectIntegral(CGRectInset(_shadowImageView.frame, paddingDiff, 0.0f));
    _selectionImageView.frame = CGRectIntegral(CGRectInset(_selectionImageView.frame, paddingDiff, 0.0f));
    _frameImageView.frame = CGRectIntegral(CGRectInset(_frameImageView.frame, paddingDiff, 0.0f));
    [self bringSubviewToFront:_shadowImageView];
    [self bringSubviewToFront:_selectionImageView];
    [self bringSubviewToFront:_frameImageView];
}

- (CGFloat)widthForTableWithTag:(PMDatePickerTags)tag
{
    NSObject *width = widthsForColumnTypes[@(tag)];
    CGFloat result = 0.0f;
    if ([width isKindOfClass:[NSNumber class]])
    {
        result = [(NSNumber *)width floatValue];
    }
    else if ([width isKindOfClass:[NSDictionary class]])
    {
        NSDictionary *widthDict = (NSDictionary *)width;
        if (PMDatePickerTagMonth == tag)
        {
            NSString *decString = [_dateFormatter standaloneMonthSymbols][11];
            if ([decString rangeOfString:@"12"].location != NSNotFound)
            {
                result = [widthDict[@"short"] floatValue];
            }
            else
            {
                result = [widthDict[@"long"] floatValue];
            }
        }
        else
        {
            NSString *formatString = nil;
            switch (tag) {
                case PMDatePickerTagDay:
                    formatString = @"dd";
                    break;
                case PMDatePickerTagYear:
                    formatString = @"y";
                    break;
                default:
                    break;
            }
            NSString *localeFormattedString = [NSDateFormatter dateFormatFromTemplate:formatString
                                                                              options:0
                                                                               locale:_locale];
            if ([[localeFormattedString stringByReplacingOccurrencesOfString:formatString
                                                                  withString:@""] length] == 0)
            {
                result = [widthDict[@"short"] floatValue];
            }
            else
            {
                result = [widthDict[@"long"] floatValue];
            }
        }
    }
    
    return result * self.bounds.size.width;
}

@end

