//
//  PMTableView.h
//  PMDatePicker
//
//  Created by Pavel S. Mazurin on 1/14/13.
//  Copyright (c) 2013 Pavel Mazurin. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol PMTableViewDelegate;
@protocol PMTableViewDataSource;

typedef NS_ENUM(NSInteger, PMTableViewMode) {
    PMTableViewModeDefault,
    PMTableViewModeCircular
};

typedef NS_ENUM(NSInteger, PMTableViewScrollDirection) {
    PMTableViewScrollUp,
    PMTableViewScrollDown
};

@interface PMTableView : UIScrollView <UIScrollViewDelegate>

@property (nonatomic, assign) IBOutlet id <PMTableViewDelegate> tableDelegate;
@property (nonatomic, assign) IBOutlet id <PMTableViewDataSource> tableDataSource;
@property (nonatomic, assign) CGFloat rowHeight;
@property (nonatomic, assign) PMTableViewMode mode;
@property (nonatomic, assign, getter=isAutoscrolling) BOOL autoscrolling;

- (void) reloadData;
- (NSInteger) numberOfRows;
- (UITableViewCell *) dequeueReusableCell;

- (CGRect)rectForRowAtIndex:(NSInteger)index;

- (NSInteger) indexForSelectedRow;    // Index of a row in a middle of a tableView's frame.
- (NSInteger) indexForRowAtPoint:(CGPoint)point;
- (NSInteger) indexForCell:(UITableViewCell *)cell;
- (UITableViewCell *) cellForRowAtIndex:(NSInteger)index;

- (void)scrollToRowAtIndex:(NSInteger)index
          atScrollPosition:(UITableViewScrollPosition)scrollPosition
                  animated:(BOOL)animated;

@end

@protocol PMTableViewDelegate<NSObject, UIScrollViewDelegate>

@optional
- (void) tableView:(PMTableView *)tableView didSelectRowAtIndex:(NSInteger)index;
- (void) tableViewDidPassCycle:(PMTableView *)tableView withDirection:(PMTableViewScrollDirection)direction;

@end

@protocol PMTableViewDataSource<NSObject>

@required
- (NSInteger) numberOfRowsInTableView:(PMTableView *)tableView;
- (UITableViewCell *) tableView:(PMTableView *)tableView
              cellForRowAtIndex:(NSInteger)index;

@end

