//
//  JTCalendarDayView.m
//  JTCalendar
//
//  Created by Jonathan Tribouharet
//

#import "JTCalendarDayView.h"

#import "JTDayViewProtocol.h"

@interface JTCalendarDayView (){
    UIView *backgroundView;
    UIView<JTDayViewProtocol> *circleView;
    UILabel *textLabel;
    UIView<JTDayViewProtocol> *dotView;

    BOOL isSelected;

    int cacheIsToday;
    NSString *cacheCurrentDateText;
}
@end

static NSString *const kJTCalendarDaySelected = @"kJTCalendarDaySelected";

@implementation JTCalendarDayView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if(!self){
        return nil;
    }

    [self commonInit];

    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if(!self){
        return nil;
    }

    [self commonInit];

    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter]  removeObserver:self];
}

- (void)commonInit
{
    isSelected = NO;
    self.isOtherMonth = NO;

    backgroundView = [UIView new];
    [self addSubview:backgroundView];
    textLabel = [UILabel new];
    [self addSubview:textLabel];
    UITapGestureRecognizer *gesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTouch)];

    self.userInteractionEnabled = YES;
    [self addGestureRecognizer:gesture];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didDaySelected:) name:kJTCalendarDaySelected object:nil];
}

- (void)layoutSubviews
{
    [self configureConstraintsForSubviews];

    // No need to call [super layoutSubviews]
}

// Avoid to calcul constraints (very expensive)
- (void)configureConstraintsForSubviews
{
    textLabel.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
    backgroundView.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);

    CGFloat sizeCircle = MIN(self.frame.size.width, self.frame.size.height);
    CGFloat sizeDot = sizeCircle;

    sizeCircle = sizeCircle * self.calendarManager.calendarAppearance.dayCircleRatio;
    sizeDot = sizeDot * self.calendarManager.calendarAppearance.dayDotRatio;

    sizeCircle = roundf(sizeCircle);
    sizeDot = roundf(sizeDot);

    if (!circleView) {
        circleView = [self.calendarManager.calendarAppearance.circleViewClass new];
        [self addSubview:circleView];
        [self bringSubviewToFront:textLabel];
    }

    if (!dotView) {
        dotView = [self.calendarManager.calendarAppearance.circleViewClass new];
        [self addSubview:dotView];
        dotView.hidden = YES;
    }

    circleView.frame = CGRectMake(0, 0, sizeCircle, sizeCircle);
    circleView.center = CGPointMake(self.frame.size.width / 2., self.frame.size.height / 2.);
    circleView.layer.cornerRadius = sizeCircle / 2.;

    dotView.frame = CGRectMake(0, 0, sizeDot, sizeDot);
    dotView.center = CGPointMake(self.frame.size.width / 2., (self.frame.size.height / 2.) + sizeDot * 2.5);
    dotView.layer.cornerRadius = sizeDot / 2.;
}

- (void)setDate:(NSDate *)date
{
    static NSDateFormatter *dateFormatter;
    if(!dateFormatter){
        dateFormatter = [NSDateFormatter new];
        dateFormatter.timeZone = self.calendarManager.calendarAppearance.calendar.timeZone;
        [dateFormatter setDateFormat:self.calendarManager.calendarAppearance.dayFormat];
    }

    self->_date = date;

    textLabel.text = [dateFormatter stringFromDate:date];

    cacheIsToday = -1;
    cacheCurrentDateText = nil;
}

- (void)didTouch
{
    [self setSelected:YES animated:YES];
    [self.calendarManager setCurrentDateSelected:self.date];

    [[NSNotificationCenter defaultCenter] postNotificationName:kJTCalendarDaySelected object:self.date];

    [self.calendarManager.dataSource calendar:self.calendarManager didSelectDate:self.date];

    if(!self.isOtherMonth || !self.calendarManager.calendarAppearance.autoChangeMonth){
        return;
    }

    NSInteger currentMonthIndex = [self monthIndexForDate:self.date];
    NSInteger calendarMonthIndex = [self monthIndexForDate:self.calendarManager.currentDate];

    currentMonthIndex = currentMonthIndex % 12;

    if(currentMonthIndex == (calendarMonthIndex + 1) % 12){
        [self.calendarManager loadNextMonth];
    }
    else if(currentMonthIndex == (calendarMonthIndex + 12 - 1) % 12){
        [self.calendarManager loadPreviousMonth];
    }
}

- (void)didDaySelected:(NSNotification *)notification
{
    NSDate *dateSelected = [notification object];

    if([self isSameDate:dateSelected]){
        if(!isSelected){
            [self setSelected:YES animated:YES];
        }
    }
    else if(isSelected){
        [self setSelected:NO animated:YES];
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    if(isSelected == selected){
        animated = NO;
    }

    isSelected = selected;

    circleView.transform = CGAffineTransformIdentity;
    CGAffineTransform tr = CGAffineTransformIdentity;
    CGFloat opacity = 1.;

    if(selected){
        if(!self.isOtherMonth){
            circleView.color = [self.calendarManager.calendarAppearance dayCircleColorSelected];
            textLabel.textColor = [self.calendarManager.calendarAppearance dayTextColorSelected];
            dotView.color = [self.calendarManager.calendarAppearance dayDotColorSelected];
            dotView.layer.borderColor = [self.calendarManager.calendarAppearance dayDotColorSelected].CGColor;
        }
        else{
            circleView.color = [self.calendarManager.calendarAppearance dayCircleColorSelectedOtherMonth];
            textLabel.textColor = [self.calendarManager.calendarAppearance dayTextColorSelectedOtherMonth];
            dotView.color = [self.calendarManager.calendarAppearance dayDotColorSelectedOtherMonth];
            dotView.layer.borderColor = [self.calendarManager.calendarAppearance dayDotColorSelectedOtherMonth].CGColor;
        }

        circleView.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0.1, 0.1);
        tr = CGAffineTransformIdentity;
    }
    else if([self isToday]){
        if(!self.isOtherMonth){
            circleView.color = [self.calendarManager.calendarAppearance dayCircleColorToday];
            textLabel.textColor = [self.calendarManager.calendarAppearance dayTextColorToday];
            dotView.color = [self.calendarManager.calendarAppearance dayDotColorToday];
            dotView.layer.borderColor = [self.calendarManager.calendarAppearance dayDotColorToday].CGColor;
        }
        else{
            circleView.color = [self.calendarManager.calendarAppearance dayCircleColorTodayOtherMonth];
            textLabel.textColor = [self.calendarManager.calendarAppearance dayTextColorTodayOtherMonth];
            dotView.color = [self.calendarManager.calendarAppearance dayDotColorTodayOtherMonth];
            dotView.layer.borderColor = [self.calendarManager.calendarAppearance dayDotColorTodayOtherMonth].CGColor;
        }
    }
    else{
        if(!self.isOtherMonth){
            textLabel.textColor = [self.calendarManager.calendarAppearance dayTextColor];
            dotView.color = [self.calendarManager.calendarAppearance dayDotColor];
            dotView.layer.borderColor = [self.calendarManager.calendarAppearance dayDotColor].CGColor;
        }
        else{
            textLabel.textColor = [self.calendarManager.calendarAppearance dayTextColorOtherMonth];
            dotView.color = [self.calendarManager.calendarAppearance dayDotColorOtherMonth];
            dotView.layer.borderColor = [self.calendarManager.calendarAppearance dayDotColorOtherMonth].CGColor;
        }

        opacity = 0.;
    }

    if(animated){
        [UIView animateWithDuration:.3 animations:^{
            circleView.layer.opacity = opacity;
            circleView.transform = tr;
        }];
    }
    else{
        circleView.layer.opacity = opacity;
        circleView.transform = tr;
    }
}

- (void)setIsOtherMonth:(BOOL)isOtherMonth
{
    self->_isOtherMonth = isOtherMonth;
    [self setSelected:isSelected animated:NO];
}

- (void)reloadData
{
    id dataForEvent = [self.calendarManager.dataCache dataForEvent:self.date];
    dotView.data = dataForEvent;
    dotView.layer.borderWidth = 1;

    if (self.calendarManager.calendarAppearance.showDotOnEvent) {
        dotView.hidden = (dataForEvent == nil);
    }

    BOOL selected = [self isSameDate:[self.calendarManager currentDateSelected]];
    [self setSelected:selected animated:NO];
}

- (BOOL)isToday
{
    if(cacheIsToday == 0){
        return NO;
    }
    else if(cacheIsToday == 1){
        return YES;
    }
    else{
        if([self isSameDate:[NSDate date]]){
            cacheIsToday = 1;
            return YES;
        }
        else{
            cacheIsToday = 0;
            return NO;
        }
    }
}

- (BOOL)isSameDate:(NSDate *)date
{
    static NSDateFormatter *dateFormatter;
    if(!dateFormatter){
        dateFormatter = [NSDateFormatter new];
        dateFormatter.timeZone = self.calendarManager.calendarAppearance.calendar.timeZone;
        [dateFormatter setDateFormat:@"dd-MM-yyyy"];
    }

    if(!cacheCurrentDateText){
        cacheCurrentDateText = [dateFormatter stringFromDate:self.date];
    }

    NSString *dateText2 = [dateFormatter stringFromDate:date];

    if ([cacheCurrentDateText isEqualToString:dateText2]) {
        return YES;
    }

    return NO;
}

- (NSInteger)monthIndexForDate:(NSDate *)date
{
    NSCalendar *calendar = self.calendarManager.calendarAppearance.calendar;
    NSDateComponents *comps = [calendar components:NSCalendarUnitMonth fromDate:date];
    return comps.month;
}

- (void)reloadAppearance
{
    textLabel.textAlignment = NSTextAlignmentCenter;
    textLabel.font = self.calendarManager.calendarAppearance.dayTextFont;
    backgroundView.backgroundColor = self.calendarManager.calendarAppearance.dayBackgroundColor;
    backgroundView.layer.borderWidth = self.calendarManager.calendarAppearance.dayBorderWidth;
    backgroundView.layer.borderColor = self.calendarManager.calendarAppearance.dayBorderColor.CGColor;
    
    [self configureConstraintsForSubviews];
    [self setSelected:isSelected animated:NO];
}

@end
