#import "CalendarView.h"
#import "Dates.h"

#define kCellWidth   28
#define kCellHeight  20
#define kTitleHeight 24
#define kNamesHeight 18

@implementation CalendarView

+ (NSSize)size
{
    return NSMakeSize(7 * kCellWidth, kTitleHeight + kNamesHeight + 6 * kCellHeight);
}

- (id)initWithFrame:(NSRect)frame
{
    if ((self = [super initWithFrame:frame]) != nil)
        [self showMonthOfDay:Today()];
    return self;
}

- (BOOL)isFlipped
{
    return YES;
}

- (BOOL)acceptsFirstMouse:(NSEvent *)event
{
    return YES;
}

- (void)setDelegate:(id)object
{
    delegate = object;      /* not retained: the delegate owns the view */
}

- (void)showMonthOfDay:(int)day
{
    int d;

    DayToDate(day, &year, &month, &d);
    [self setNeedsDisplay:YES];
}

- (void)changeMonth:(int)delta
{
    month += delta;
    if (month < 1) {
        month = 12;
        year--;
    } else if (month > 12) {
        month = 1;
        year++;
    }
    [self setNeedsDisplay:YES];
}

- (NSRect)previousArrowRect
{
    return NSMakeRect(0, 0, kCellWidth, kTitleHeight);
}

- (NSRect)nextArrowRect
{
    return NSMakeRect(6 * kCellWidth, 0, kCellWidth, kTitleHeight);
}

- (NSRect)rectOfCell:(int)cell
{
    return NSMakeRect((cell % 7) * kCellWidth, kTitleHeight + kNamesHeight + (cell / 7) * kCellHeight,
                      kCellWidth, kCellHeight);
}

/* Draws text centred in a rectangle. */
static void DrawCentred(NSString *text, NSRect rect, NSFont *font, NSColor *colour)
{
    NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                font, NSFontAttributeName, colour, NSForegroundColorAttributeName, nil];
    NSSize size = [text sizeWithAttributes:attributes];

    [text drawAtPoint:NSMakePoint(rect.origin.x + floor((rect.size.width - size.width) / 2),
                                  rect.origin.y + floor((rect.size.height - size.height) / 2))
       withAttributes:attributes];
}

static void DrawArrow(NSRect rect, BOOL right)
{
    NSBezierPath *path = [NSBezierPath bezierPath];
    float x = NSMidX(rect), y = NSMidY(rect);

    if (right) {
        [path moveToPoint:NSMakePoint(x - 3, y - 5)];
        [path lineToPoint:NSMakePoint(x + 3, y)];
        [path lineToPoint:NSMakePoint(x - 3, y + 5)];
    } else {
        [path moveToPoint:NSMakePoint(x + 3, y - 5)];
        [path lineToPoint:NSMakePoint(x - 3, y)];
        [path lineToPoint:NSMakePoint(x + 3, y + 5)];
    }
    [path closePath];
    [[NSColor controlTextColor] set];
    [path fill];
}

- (void)drawRect:(NSRect)dirty
{
    NSFont *plain = [NSFont systemFontOfSize:11];
    NSFont *bold = [NSFont boldSystemFontOfSize:11];
    int first = DateToDay(year, month, 1), length = MonthLength(year, month);
    int lead = Weekday(first), today = Today();
    int open = delegate != nil ? [delegate calendarOpenDay] : today;
    int i;

    [[NSColor controlBackgroundColor] set];
    NSRectFill([self bounds]);

    DrawArrow([self previousArrowRect], NO);
    DrawArrow([self nextArrowRect], YES);
    DrawCentred([NSString stringWithFormat:@"%@ %d", kMonths[month - 1], year],
                NSMakeRect(kCellWidth, 0, 5 * kCellWidth, kTitleHeight),
                [NSFont boldSystemFontOfSize:12], [NSColor controlTextColor]);

    for (i = 0; i < 7; i++)
        DrawCentred([kWeekdays[i] substringToIndex:1],
                    NSMakeRect(i * kCellWidth, kTitleHeight, kCellWidth, kNamesHeight),
                    plain, [NSColor disabledControlTextColor]);

    for (i = 0; i < length; i++) {
        int day = first + i;
        NSRect cell = [self rectOfCell:lead + i];
        NSRect box = NSInsetRect(cell, 2, 1);
        BOOL hasEntry = delegate != nil && [delegate calendarHasEntry:day];
        NSColor *colour = [NSColor controlTextColor];

        if (day == open) {
            [[NSColor alternateSelectedControlColor] set];
            NSRectFill(box);
            colour = [NSColor alternateSelectedControlTextColor];
        }
        if (day == today) {
            [[NSColor controlTextColor] set];
            NSFrameRect(box);
        }
        DrawCentred([NSString stringWithFormat:@"%d", i + 1], cell, hasEntry ? bold : plain, colour);
    }
}

- (void)mouseDown:(NSEvent *)event
{
    NSPoint where = [self convertPoint:[event locationInWindow] fromView:nil];
    int first = DateToDay(year, month, 1), i;

    if (NSPointInRect(where, [self previousArrowRect])) {
        [self changeMonth:-1];
        return;
    }
    if (NSPointInRect(where, [self nextArrowRect])) {
        [self changeMonth:1];
        return;
    }
    for (i = 0; i < MonthLength(year, month); i++)
        if (NSPointInRect(where, [self rectOfCell:Weekday(first) + i])) {
            [delegate calendarClickedDay:first + i];
            return;
        }
}

@end
