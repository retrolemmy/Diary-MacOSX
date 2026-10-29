/* Diary's one window and everything it does: the app's delegate, the
   window's delegate, and the data source of the entry list. */

#import <Cocoa/Cocoa.h>

@class CalendarView, DiaryServer, EntryStore;

@interface DiaryController : NSObject
{
    NSWindow *window;
    CalendarView *calendar;
    NSTableView *list;
    NSTextField *dateLabel;
    NSTextView *editor;

    EntryStore *store;
    DiaryServer *server;        /* nil when the entries are kept locally */
    NSMutableArray *allDays;    /* NSNumbers, newest first */
    NSMutableArray *shownDays;  /* the same, or a search's matches */
    NSString *search;           /* the current search, or nil */
    NSString *entryVersion;     /* the server's version of the open entry */
    int day;                    /* the open day */
    BOOL changed;               /* the open entry was edited */
    BOOL syncingList;
}

- (IBAction)saveEntry:(id)sender;
- (IBAction)chooseServer:(id)sender;
- (IBAction)find:(id)sender;
- (IBAction)findAgain:(id)sender;
- (IBAction)showAllEntries:(id)sender;
- (IBAction)previousDay:(id)sender;
- (IBAction)nextDay:(id)sender;
- (IBAction)today:(id)sender;

@end
