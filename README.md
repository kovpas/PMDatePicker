PMDatePicker
============

This componenit is supposed to be a fully customizable drop-in replacement for UIDatePicker. At the moment it supports only 2 of 4 UIDatePicker modes:

- ~~`UIDatePickerModeTime`~~  
- ~~`UIDatePickerModeDate`~~  
- `UIDatePickerModeDateAndTime`  
- `UIDatePickerModeCountDownTimer`  

Legal
============
PMDatePicker is released under the MIT License.

Customizable properties
============

The following properties are available for customization:  
``` objective-c
@property (nonatomic, retain) UIFont *font;                         // default is [UIFont boldSystemFontOfSize:24]
@property (nonatomic, assign) CGFloat rowHeight;                    // default is 45.0f

@property (nonatomic, strong, readonly) UIImageView *frameImageView;
@property (nonatomic, strong, readonly) UIImageView *shadowImageView;
@property (nonatomic, strong, readonly) UIImageView *selectionImageView;

- (void)setColBackgroundImage:(UIImage *)colBackgroundImage;
```

For the reference see enclosed demo project.


