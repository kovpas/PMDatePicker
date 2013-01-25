//
//  PMDatePickerTableView.m
//  PMDatePicker
//
//  Created by Pavel S. Mazurin on 1/13/13.
//  Copyright (c) 2013 Pavel Mazurin. All rights reserved.
//

#import "PMDatePickerTableView.h"

@interface PMDatePickerTableView ()

- (void) alignRowsToCenterAnimated:(BOOL)animated;
@property (nonatomic, strong) NSTimer *centerTimer;

@end

@implementation PMDatePickerTableView

- (void) reloadTimer
{
    [_centerTimer invalidate];
    
    if (!self.autoscrolling)
    {
        _centerTimer = [NSTimer scheduledTimerWithTimeInterval:0.2
                                                        target:self
                                                      selector:@selector(alignRowsToCenterTimerHandler:)
                                                      userInfo:nil
                                                       repeats:NO];
        [[NSRunLoop currentRunLoop] addTimer:_centerTimer
                                     forMode:NSRunLoopCommonModes];
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [super scrollViewDidScroll:scrollView];
    [_centerTimer invalidate];

    if (!self.tracking)
    {
        [self reloadTimer];
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate;
{
    if (!decelerate)
    {
        [self alignRowsToCenterAnimated:YES];
    }
    else
    {
        [self reloadTimer];
    }
}

- (void) alignRowsToCenterTimerHandler:(NSTimer *)timer
{
    [_centerTimer invalidate];
    if (!self.autoscrolling)
    {
        [self alignRowsToCenterAnimated:YES];
    }
}

- (void) alignRowsToCenterAnimated:(BOOL)animated
{
    CGPoint centralPoint = CGPointMake(CGRectGetMidX(self.bounds), self.contentOffset.y + self.frame.size.height / 2);
    NSInteger centralCellIndex = [self indexForRowAtPoint:centralPoint];
    UITableViewCell *cell = [self cellForRowAtIndex:centralCellIndex];
    CGFloat yDiff = cell.center.y - centralPoint.y;
    CGPoint newContentOffset = CGPointMake(self.contentOffset.x, self.contentOffset.y + yDiff);
    NSInteger newIndex = [self indexForRowAtPoint:CGPointMake(newContentOffset.x, newContentOffset.y + self.frame.size.height / 2)] % [self numberOfRows];
    
    self.autoscrolling = YES;
    [self setContentOffset:newContentOffset animated:animated];
    
    int64_t delayInSeconds = animated?0.4f:0.0f;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        if ([self.tableDelegate respondsToSelector:@selector(tableView:didSelectRowAtIndex:)])
        {
            [self.tableDelegate tableView:self didSelectRowAtIndex:newIndex];
        }
        self.autoscrolling = NO;
    });
}

- (void)setContentOffset:(CGPoint)contentOffset animated:(BOOL)animated
{
    [super setContentOffset:contentOffset animated:animated];
}

- (void)setContentOffset:(CGPoint)contentOffset
{
    [super setContentOffset:contentOffset];
}

- (void)setRowHeight:(CGFloat)rowHeight
{
    [super setRowHeight:rowHeight];
    [self recalculateContentInsets];
}

- (void) setMode:(PMTableViewMode)mode
{
    [super setMode:mode];
    [self recalculateContentInsets];
}

- (void)recalculateContentInsets
{
    switch (self.mode) {
        case PMTableViewModeDefault:
            self.contentInset = UIEdgeInsetsMake((self.frame.size.height - self.rowHeight) / 2, 0, (self.frame.size.height - self.rowHeight) / 2, 0);
            break;
        case PMTableViewModeCircular:
            self.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
            break;
            
        default:
            break;
    }
}
@end
