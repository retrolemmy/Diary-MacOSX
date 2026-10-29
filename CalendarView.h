/* A month calendar like the other Diary versions': arrows and the month at
   the top, then the weeks from Sunday. Days with an entry are bold, today
   is framed and the open day is highlighted; clicking a day tells the
   delegate. */

#import <Cocoa/Cocoa.h>

@interface NSObject (CalendarViewDelegate)
- (BOOL)calendarHasEntry:(int)day;
- (int)calendarOpenDay;
- (void)calendarClickedDay:(int)day;
@end

@interface CalendarView : NSView
{
    id delegate;
    int year, month;
}

/* The view's natural size. */
+ (NSSize)size;

- (void)setDelegate:(id)object;
- (void)showMonthOfDay:(int)day;
- (void)changeMonth:(int)delta;

@end
