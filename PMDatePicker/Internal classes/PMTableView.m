//
//  PMTableView.m
//  PMDatePicker
//
//  Created by Pavel S. Mazurin on 1/14/13.
//  Copyright (c) 2013 Pavel Mazurin. All rights reserved.
//

#import "PMTableView.h"

@interface PMTableView ()

@property (nonatomic, strong) NSTimer *centerTimer;
@property (nonatomic, strong) NSMutableSet *_unusedcells;
@property (nonatomic, strong) NSMutableArray *_visiblecells;
@property (nonatomic, strong) NSMutableDictionary *_visiblecellsByIndex;
@property (nonatomic, strong) UITapGestureRecognizer *_tapGestureRecognizer;

- (UITableViewCell *) addCellAtIndex:(NSInteger)index;
- (UITableViewCell *) removeCellAtIndex:(NSInteger)index;
- (NSInteger)realIndexForIndex:(NSInteger)index;

@end

@implementation PMTableView

@synthesize tableDataSource = __dataSource;
@synthesize tableDelegate = __delegate;

#pragma mark - initialization methods -

- (void)dealloc
{
    [self removeGestureRecognizer:__tapGestureRecognizer];
}

- (void) initialize
{
    __visiblecells = [NSMutableArray array];
    __unusedcells = [NSMutableSet set];
    __visiblecellsByIndex = [NSMutableDictionary dictionary];
    _rowHeight = 45;
    __tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                     action:@selector(tapHandler:)];
    [self addGestureRecognizer:__tapGestureRecognizer];
    
    self.delegate = self;
//    self.contentSize = CGSizeMake(self.frame.size.width, 5000);
}

- (void) awakeFromNib
{
    [super awakeFromNib];
    [self reloadData];
}

- (id) initWithCoder:(NSCoder *)aDecoder
{
    if ((self = [super initWithCoder:aDecoder]))
    {
        [self initialize];
    }
    
    return self;
}
- (id) initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame]))
    {
        [self initialize];
    }
    
    return self;
}

- (id) init
{
    if ((self = [super init]))
    {
        [self initialize];
    }
    
    return self;
}

#pragma mark - public methods -

- (void) reloadData
{
    [__visiblecells makeObjectsPerformSelector:@selector(removeFromSuperview)];    
    [__unusedcells removeAllObjects];
    [__visiblecells removeAllObjects];
    [__visiblecellsByIndex removeAllObjects];
    
    UITableViewCell *cell = nil;
    NSInteger i = floorl(self.contentOffset.y / self.rowHeight);
    NSInteger totalNumberOfRows = [self numberOfRows];
    
    do
    {
        if ((_mode == PMTableViewModeCircular) || ((i >= 0) && (i < totalNumberOfRows)))
        {
            cell = [self addCellAtIndex:i];
        }
        i++;
    } while ((CGRectGetMaxY(cell.frame) < self.frame.size.height + self.contentOffset.y)
             && ((_mode == PMTableViewModeCircular) || (i < totalNumberOfRows)));

    if ((_mode == PMTableViewModeCircular)
        && (self.contentSize.height != self.rowHeight * [self numberOfRows] * 4))
    {
        [self setContentSize:CGSizeMake(self.frame.size.width
                                        , self.rowHeight * [self numberOfRows] * 4)];
    }
    else if ((_mode == PMTableViewModeDefault)
             &&(self.contentSize.height != self.rowHeight * [self numberOfRows]))
    {
        [self setContentSize:CGSizeMake(self.bounds.size.width
                                        , self.rowHeight * [self numberOfRows])];
    }
}

- (NSInteger) numberOfRows
{
    return [__dataSource numberOfRowsInTableView:self];
}

- (UITableViewCell *) dequeueReusableCell
{
    if ([__unusedcells count] > 0)
    {
        UITableViewCell *cell = [__unusedcells allObjects][0];
        [__unusedcells removeObject:cell];
        
        return cell;
    }
    
    return nil;
}

- (NSInteger) indexForSelectedRow
{
    CGPoint centralPoint = CGPointMake(CGRectGetMidX(self.bounds), self.contentOffset.y + self.frame.size.height / 2);
    NSInteger index = [self indexForRowAtPoint:centralPoint];
    return [self realIndexForIndex:index];
}

- (NSInteger) indexForRowAtPoint:(CGPoint)point
{
    if ((point.y < self.contentOffset.y - self.rowHeight)
        || (point.y > self.contentOffset.y + self.frame.size.height + self.rowHeight))
    {
        return -1;
    }
    
    return floorl(point.y / self.rowHeight);
}

- (NSInteger) indexForCell:(UITableViewCell *)cell
{
    return [[__visiblecellsByIndex allKeysForObject:cell][0] intValue];
}

- (UITableViewCell *) cellForRowAtIndex:(NSInteger)index
{
    return __visiblecellsByIndex[@(index)];
}

- (NSInteger)realIndexForIndex:(NSInteger)index
{
    if (_mode == PMTableViewModeCircular)
    {
        NSUInteger numberOfRows = [self numberOfRows];
        return ((index % numberOfRows) + numberOfRows) % numberOfRows;
    }
    
    return index;
}

- (CGRect)rectForRowAtIndex:(NSInteger)index
{
    return CGRectMake(0, index * _rowHeight, self.frame.size.width, _rowHeight);
}

- (void)scrollToRowAtIndex:(NSInteger)index
          atScrollPosition:(UITableViewScrollPosition)scrollPosition
                  animated:(BOOL)animated
{
    // stops current scrolling animation
    CGPoint offset = self.contentOffset;
    [self setContentOffset:offset animated:NO];
    
    CGRect cellRect = [self rectForRowAtIndex:index];
    CGPoint centralPoint = CGPointMake(CGRectGetMidX(self.bounds), self.contentOffset.y + self.frame.size.height / 2);
    NSInteger numberOfRows = [self numberOfRows];
    CGFloat yDiff = (CGRectGetMidY(cellRect) - centralPoint.y);
    CGFloat totalHeight = numberOfRows * _rowHeight;
    yDiff = fmodf(yDiff, totalHeight);
    if (yDiff != 0)
    {
        if (fabs(yDiff) > totalHeight / 2)
        {
            yDiff += totalHeight * (yDiff > 0?-1:1);
        }
        _autoscrolling = YES;
        CGPoint newContentOffset = CGPointMake(self.contentOffset.x, self.contentOffset.y + yDiff);

        dispatch_async(dispatch_get_main_queue(), ^(void){
            [self setContentOffset:newContentOffset animated:animated];
        });
        int64_t delayInSeconds = 0.4;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            self.autoscrolling = NO;
        });
    }
}

#pragma mark - private methods -

- (UITableViewCell *) addCellAtIndex:(NSInteger)index
{
    UITableViewCell *cell = [__dataSource tableView:self
                                  cellForRowAtIndex:[self realIndexForIndex:index]];
    cell.frame = CGRectMake(0, 0, self.bounds.size.width, self.rowHeight);
    cell.center = CGPointMake( self.bounds.size.width / 2, (index + 0.5) * self.rowHeight );
    
    [self addSubview:cell];
    [__visiblecells addObject:cell];
    [__visiblecellsByIndex setObject:cell forKey:@(index)];
    
    return cell;
}

- (UITableViewCell *) removeCellAtIndex:(NSInteger)index
{
    UITableViewCell *cell = [__visiblecellsByIndex objectForKey:@(index)];
    if (cell)
    {
        [cell removeFromSuperview];
        [__visiblecellsByIndex removeObjectForKey:@(index)];
        [__visiblecells removeObject:cell];
        [__unusedcells addObject:cell];
        
        return cell;
    }
    
    return nil;
}

- (void) scrollViewDidScroll:(UIScrollView *)scrollView
{
    NSNumber *topRowIndex = @([self indexForRowAtPoint:scrollView.contentOffset]);
    NSNumber *bottomRowIndex = @([self indexForRowAtPoint:CGPointMake(0, scrollView.contentOffset.y + scrollView.frame.size.height)]);
    
    for (NSNumber *index in [__visiblecellsByIndex allKeys])
    {
        if (([index integerValue] < [topRowIndex integerValue])
            || ([index integerValue] > [bottomRowIndex integerValue]))
        {
            [self removeCellAtIndex:[index integerValue]];
        }
    }
    
    NSUInteger totalNumberOfRows = [self numberOfRows];
    for (NSInteger i = [topRowIndex intValue]; i <= [bottomRowIndex intValue]; i++)
    {
        if (!__visiblecellsByIndex[@(i)] && ((_mode == PMTableViewModeCircular) || ((i >= 0) && (i < totalNumberOfRows))))
        {
            [self addCellAtIndex:i];
        }
    }
}

- (void) recenterIfNecessary
{
    CGPoint currentOffset = self.contentOffset;
    CGFloat centerY       = self.contentSize.height / 2;
    CGFloat halfOfFrame   = self.bounds.size.height / 2;
    CGFloat contentHeight = [self numberOfRows] * _rowHeight;
    BOOL needToRecenter   = (currentOffset.y + contentHeight + halfOfFrame < centerY)
                             || (currentOffset.y + halfOfFrame > centerY);
    if (needToRecenter)
    {
        BOOL scrollDown       = currentOffset.y + halfOfFrame > centerY;
        CGFloat diff          = contentHeight * (scrollDown?-1:1);
        self.contentOffset    = CGPointMake(currentOffset.x, currentOffset.y + diff);
        
        if (_mode == PMTableViewModeCircular)
        {
            if ([__delegate respondsToSelector:@selector(tableViewDidPassCycle:withDirection:)])
            {
                [__delegate tableViewDidPassCycle:self
                                    withDirection:(!scrollDown?PMTableViewScrollDown:PMTableViewScrollUp)];
            }
        }
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    if (_mode == PMTableViewModeCircular)
    {
        [self recenterIfNecessary];
    }
}

- (void) tapHandler:(UITapGestureRecognizer *)gestureRecognizer
{
    if ([gestureRecognizer numberOfTouches] > 1)
    {
        return;
    }
    
    if ([gestureRecognizer state] == UIGestureRecognizerStateEnded)
    {
        CGPoint pnt = [gestureRecognizer locationInView:self];
        if (pnt.y > 0 && pnt.y < self.contentSize.height)
        {
            NSInteger index = [self indexForRowAtPoint:pnt];
            NSInteger centralRowIndex = [self indexForRowAtPoint:CGPointMake(0, self.contentOffset.y + self.frame.size.height / 2.0)];
            if (centralRowIndex == index)
            {
                return;
            }
            
            [self scrollToRowAtIndex:index atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
        
            if ([__delegate respondsToSelector:@selector(tableView:didSelectRowAtIndex:)])
            {
                [__delegate tableView:self didSelectRowAtIndex:(_mode == PMTableViewModeDefault)?index:index % [self numberOfRows]];
            }
        }
    }
}

@end
