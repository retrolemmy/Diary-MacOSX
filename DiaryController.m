#import "DiaryController.h"
#import "CalendarView.h"
#import "DiaryServer.h"
#import "EntryStore.h"
#import "Dates.h"

#define kListWidth 196      /* the calendar's width */
#define kMargin    12

static NSString *const kFontNameKey = @"FontName";
static NSString *const kFontSizeKey = @"FontSize";
static NSString *const kServerKey = @"Server";
static NSString *const kServerKeyKey = @"ServerKey";

/* New in 10.5: the yellow flash that shows a match. */
@interface NSTextView (LeopardFindIndicator)
- (void)showFindIndicatorForRange:(NSRange)range;
@end

@implementation DiaryController

/* ---------- Small helpers ---------- */

static NSNumber *Day(int day)
{
    return [NSNumber numberWithInt:day];
}

static BOOL ContainsDay(NSArray *days, int day)
{
    return days != nil && [days indexOfObject:Day(day)] != NSNotFound;
}

/* Keeps the list newest first. */
static void InsertDay(NSMutableArray *days, int day)
{
    unsigned i;

    if (ContainsDay(days, day))
        return;
    for (i = 0; i < [days count]; i++)
        if ([[days objectAtIndex:i] intValue] < day)
            break;
    [days insertObject:Day(day) atIndex:i];
}

static void RemoveDay(NSMutableArray *days, int day)
{
    [days removeObject:Day(day)];
}

static void ShowMessage(NSString *title, NSString *message)
{
    NSRunAlertPanel(title, @"%@", @"OK", nil, nil, message);
}

/* The message for a request that didn't get through or was refused. */
static NSString *Reason(int status, NSString *text, NSString *error)
{
    return status == 0 ? error : [DiaryServer reasonForStatus:status text:text];
}

- (void)setEntryVersion:(NSString *)version
{
    [entryVersion autorelease];
    entryVersion = [version copy];
}

- (void)setSearch:(NSString *)text
{
    [search autorelease];
    search = [text copy];
}

/* ---------- Window ---------- */

- (NSButton *)buttonWithTitle:(NSString *)title action:(SEL)action frame:(NSRect)frame
{
    NSButton *button = [[[NSButton alloc] initWithFrame:frame] autorelease];

    [button setTitle:title];
    [button setBezelStyle:NSRoundedBezelStyle];
    [button setTarget:self];
    [button setAction:action];
    [button setAutoresizingMask:NSViewMinYMargin];
    return button;
}

- (void)createWindow
{
    NSRect frame = NSMakeRect(0, 0, 760, 520);
    NSSize calendarSize = [CalendarView size];
    float width = frame.size.width, height = frame.size.height;
    float right = kMargin + kListWidth + kMargin;
    NSView *content;
    NSScrollView *scroller;
    NSTableColumn *column;
    NSSize size;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSFont *font;

    window = [[NSWindow alloc] initWithContentRect:frame
                                         styleMask:NSTitledWindowMask | NSClosableWindowMask
                                                   | NSMiniaturizableWindowMask | NSResizableWindowMask
                                           backing:NSBackingStoreBuffered
                                             defer:NO];
    [window setMinSize:NSMakeSize(560, 400)];
    [window setDelegate:self];
    content = [window contentView];

    /* Left: the calendar and the entry list */
    calendar = [[CalendarView alloc] initWithFrame:NSMakeRect(kMargin, height - kMargin - calendarSize.height,
                                                              calendarSize.width, calendarSize.height)];
    [calendar setDelegate:self];
    [calendar setAutoresizingMask:NSViewMinYMargin | NSViewMaxXMargin];
    [content addSubview:calendar];

    scroller = [[[NSScrollView alloc] initWithFrame:
                 NSMakeRect(kMargin, kMargin, kListWidth,
                            height - 3 * kMargin - calendarSize.height)] autorelease];
    [scroller setHasVerticalScroller:YES];
    [scroller setBorderType:NSBezelBorder];
    [scroller setAutoresizingMask:NSViewHeightSizable | NSViewMaxXMargin];
    list = [[NSTableView alloc] initWithFrame:NSMakeRect(0, 0, [scroller contentSize].width,
                                                         [scroller contentSize].height)];
    column = [[[NSTableColumn alloc] initWithIdentifier:@"day"] autorelease];
    [column setEditable:NO];
    [column setWidth:[scroller contentSize].width];
    [column setResizingMask:NSTableColumnAutoresizingMask];
    [list addTableColumn:column];
    [list setHeaderView:nil];
    [list setColumnAutoresizingStyle:NSTableViewUniformColumnAutoresizingStyle];
    [list setAllowsEmptySelection:YES];
    [list setDataSource:self];
    [list setDelegate:self];
    [scroller setDocumentView:list];
    [content addSubview:scroller];

    /* Right: the day's buttons and date, then its text */
    [content addSubview:[self buttonWithTitle:@"<" action:@selector(previousDay:)
                                        frame:NSMakeRect(right - 6, height - 40, 44, 32)]];
    [content addSubview:[self buttonWithTitle:@"Today" action:@selector(today:)
                                        frame:NSMakeRect(right + 32, height - 40, 76, 32)]];
    [content addSubview:[self buttonWithTitle:@">" action:@selector(nextDay:)
                                        frame:NSMakeRect(right + 102, height - 40, 44, 32)]];
    dateLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(right + 156, height - 34,
                                                              width - right - 156 - kMargin, 20)];
    [dateLabel setEditable:NO];
    [dateLabel setSelectable:NO];
    [dateLabel setBordered:NO];
    [dateLabel setDrawsBackground:NO];
    [dateLabel setFont:[NSFont boldSystemFontOfSize:14]];
    [dateLabel setAutoresizingMask:NSViewMinYMargin | NSViewWidthSizable];
    [content addSubview:dateLabel];

    scroller = [[[NSScrollView alloc] initWithFrame:
                 NSMakeRect(right, kMargin, width - right - kMargin, height - kMargin - 48)] autorelease];
    [scroller setHasVerticalScroller:YES];
    [scroller setBorderType:NSBezelBorder];
    [scroller setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
    size = [scroller contentSize];
    editor = [[NSTextView alloc] initWithFrame:NSMakeRect(0, 0, size.width, size.height)];
    [editor setMinSize:NSMakeSize(0, size.height)];
    [editor setMaxSize:NSMakeSize(FLT_MAX, FLT_MAX)];
    [editor setVerticallyResizable:YES];
    [editor setHorizontallyResizable:NO];
    [editor setAutoresizingMask:NSViewWidthSizable];
    [[editor textContainer] setContainerSize:NSMakeSize(size.width, FLT_MAX)];
    [[editor textContainer] setWidthTracksTextView:YES];
    [editor setTextContainerInset:NSMakeSize(4, 4)];
    [editor setRichText:NO];
    [editor setImportsGraphics:NO];
    [editor setUsesFontPanel:YES];
    [editor setAllowsUndo:YES];
    [editor setDelegate:self];
    font = [NSFont fontWithName:[defaults stringForKey:kFontNameKey]
                           size:[defaults floatForKey:kFontSizeKey]];
    [editor setFont:font != nil ? font : [NSFont userFontOfSize:12]];
    [scroller setDocumentView:editor];
    [content addSubview:scroller];

    [window center];
    [window setFrameAutosaveName:@"Diary"];
    [window makeFirstResponder:editor];
}

- (void)updateTitle
{
    if (server != nil)
        [window setTitle:[NSString stringWithFormat:@"Diary %C %@", (unichar)0x2014, [server address]]];
    else
        [window setTitle:@"Diary"];
}

- (void)refreshList
{
    [list reloadData];
    [calendar setNeedsDisplay:YES];
}

- (void)syncList
{
    unsigned row = shownDays != nil ? [shownDays indexOfObject:Day(day)] : NSNotFound;

    syncingList = YES;
    if (row == NSNotFound) {
        [list deselectAll:nil];
    } else {
        [list selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
        [list scrollRowToVisible:row];
    }
    syncingList = NO;
}

/* ---------- Asking ---------- */

- (void)endAsk:(id)sender
{
    [NSApp stopModalWithCode:[sender tag]];
}

/* Asks for one or more lines of text in a small window: labels has one
   label per field, values their texts, which get the answers. */
- (BOOL)askTitle:(NSString *)title labels:(NSArray *)labels values:(NSMutableArray *)values
{
    float width = 400, inner = width - 40, y;
    NSMutableArray *fields = [NSMutableArray array];
    NSPanel *panel;
    NSView *content;
    NSButton *ok, *cancel;
    unsigned i;
    int answer;

    panel = [[[NSPanel alloc] initWithContentRect:NSMakeRect(0, 0, width, 400)
                                        styleMask:NSTitledWindowMask
                                          backing:NSBackingStoreBuffered
                                            defer:YES] autorelease];
    [panel setTitle:title];
    content = [panel contentView];

    /* Lay out from the top, then size the window to fit. */
    y = 400 - 16;
    for (i = 0; i < [labels count]; i++) {
        NSTextField *label = [[[NSTextField alloc] initWithFrame:NSZeroRect] autorelease];
        NSTextField *field;
        float labelHeight;

        [label setStringValue:[labels objectAtIndex:i]];
        [label setEditable:NO];
        [label setSelectable:NO];
        [label setBordered:NO];
        [label setDrawsBackground:NO];
        [[label cell] setWraps:YES];
        labelHeight = [[label cell] cellSizeForBounds:NSMakeRect(0, 0, inner, 1000)].height;
        y -= labelHeight;
        [label setFrame:NSMakeRect(20, y, inner, labelHeight)];
        [content addSubview:label];

        y -= 4 + 22;
        field = [[[NSTextField alloc] initWithFrame:NSMakeRect(20, y, inner, 22)] autorelease];
        [field setStringValue:[values objectAtIndex:i]];
        [content addSubview:field];
        if (i > 0)
            [[fields lastObject] setNextKeyView:field];
        [fields addObject:field];
        y -= 12;
    }
    [[fields lastObject] setNextKeyView:[fields objectAtIndex:0]];

    y -= 32 + 4;
    ok = [[[NSButton alloc] initWithFrame:NSMakeRect(width - 20 - 90 + 6, y, 90, 32)] autorelease];
    [ok setTitle:@"OK"];
    [ok setKeyEquivalent:@"\r"];
    [ok setTag:NSOKButton];
    cancel = [[[NSButton alloc] initWithFrame:NSMakeRect(width - 20 - 180 + 6, y, 90, 32)] autorelease];
    [cancel setTitle:@"Cancel"];
    [cancel setKeyEquivalent:@"\033"];
    [cancel setTag:NSCancelButton];
    for (i = 0; i < 2; i++) {
        NSButton *button = i == 0 ? ok : cancel;

        [button setBezelStyle:NSRoundedBezelStyle];
        [button setTarget:self];
        [button setAction:@selector(endAsk:)];
        [content addSubview:button];
    }

    /* Move everything down so the bottom margin is 16, and shrink. */
    for (i = 0; i < [[content subviews] count]; i++) {
        NSView *view = [[content subviews] objectAtIndex:i];
        NSRect r = [view frame];

        r.origin.y -= y - 16;
        [view setFrame:r];
    }
    [panel setContentSize:NSMakeSize(width, 400 - (y - 16))];
    [panel center];
    [panel setInitialFirstResponder:[fields objectAtIndex:0]];

    answer = [NSApp runModalForWindow:panel];
    [panel orderOut:nil];
    if (answer != NSOKButton)
        return NO;
    for (i = 0; i < [fields count]; i++)
        [values replaceObjectAtIndex:i withObject:[[fields objectAtIndex:i] stringValue]];
    return YES;
}

/* ---------- Reading and saving ---------- */

/* Reads the list of entries, from the server if one is set. If it can't be
   reached, Diary can work with the local folder for this session. */
- (void)scanEntries
{
    [allDays release];
    allDays = nil;
    while (server != nil && allDays == nil) {
        NSString *text, *error = nil;
        int status = [server request:@"GET" path:@"/entries" body:nil base:nil
                                text:&text version:NULL error:&error];

        if (status == 200) {
            allDays = [[DiaryServer daysInReply:text] retain];
        } else if (NSRunAlertPanel(@"Diary couldn't get the entries from the Diary Server.", @"%@",
                                   @"Retry", @"Work Locally", nil,
                                   Reason(status, text, error)) != NSAlertDefaultReturn) {
            [server release];       /* for this session; the setting stays */
            server = nil;
            [self updateTitle];
        }
    }
    if (allDays == nil)
        allDays = [[store days] retain];
}

- (NSString *)textOfDay:(int)which
{
    NSString *text, *version, *error = nil;
    int status;

    if (server == nil)
        return [store textForDay:which];

    status = [server request:@"GET" path:[@"/entries/" stringByAppendingString:EntryName(which)]
                        body:nil base:nil text:&text version:&version error:&error];
    if (which == day)
        [self setEntryVersion:status == 200 && version != nil ? version : @"none"];
    if (status == 200)
        return text;
    if (status != 404)
        ShowMessage(@"Diary couldn't load the entry from the Diary Server.",
                    Reason(status, text, error));
    return nil;
}

- (void)loadEntry
{
    NSString *text = [self textOfDay:day];

    [editor setString:text != nil ? text : @""];
    [editor setSelectedRange:NSMakeRange([[editor string] length], 0)];
    [editor scrollRangeToVisible:[editor selectedRange]];
    [[editor undoManager] removeAllActions];
    changed = NO;
    [window setDocumentEdited:NO];

    [dateLabel setStringValue:LongDate(day)];
    [calendar showMonthOfDay:day];
    [self syncList];
}

/* Saves (or, if text is empty, deletes) the open entry on the server. If it
   was changed on another computer since it was loaded, asks first. */
- (BOOL)saveOnServer:(NSString *)text
{
    NSString *path = [@"/entries/" stringByAppendingString:EntryName(day)];
    NSString *base = entryVersion;

    for (;;) {
        NSString *reply, *version, *error = nil;
        int status;

        if ([text length] == 0)
            status = [server request:@"DELETE" path:path body:nil base:base
                                text:&reply version:&version error:&error];
        else
            status = [server request:@"PUT" path:path body:text base:base
                                text:&reply version:&version error:&error];
        if (status == 200) {
            [self setEntryVersion:version != nil ? version : @"none"];
            return YES;
        }
        if (status != 409) {
            ShowMessage(status == 0 ? @"Diary couldn't save the entry on the Diary Server."
                                    : @"The Diary Server refused to save the entry.",
                        [Reason(status, reply, error)
                         stringByAppendingString:@"\n\nYour text is still in the window."]);
            return NO;
        }
        if (NSRunAlertPanel(@"This entry was changed on another computer since you opened it.",
                            @"Save your version over it?", @"Overwrite", @"Keep Editing", nil)
                != NSAlertDefaultReturn)
            return NO;
        base = nil;             /* replace it unconditionally */
    }
}

/* Saves the open entry if it was changed. */
- (BOOL)saveIfNeeded
{
    NSMutableString *text;

    if (!changed)
        return YES;
    text = [NSMutableString stringWithString:[editor string]];
    while ([text hasSuffix:@"\n"])
        [text deleteCharactersInRange:NSMakeRange([text length] - 1, 1)];

    if (server != nil) {
        if (![self saveOnServer:text])
            return NO;
    } else if (![store setText:text forDay:day]) {
        ShowMessage(@"Diary couldn't save the entry.",
                    [NSString stringWithFormat:@"Check that the folder \"%@\" can be written to.",
                     [store folder]]);
        return NO;
    }

    if ([text length] == 0) {
        RemoveDay(allDays, day);
        RemoveDay(shownDays, day);
        [self refreshList];
    } else if (!ContainsDay(allDays, day)) {
        InsertDay(allDays, day);
        if (search == nil)
            InsertDay(shownDays, day);
        [self refreshList];
    }
    changed = NO;
    [window setDocumentEdited:NO];
    [self syncList];
    return YES;
}

- (void)goToDay:(int)which
{
    if (which == day || ![self saveIfNeeded]) {
        [self syncList];
        return;
    }
    day = which;
    [self loadEntry];
    [calendar setNeedsDisplay:YES];
}

/* ---------- Searching ---------- */

- (BOOL)entryContainsSearch:(int)which
{
    /* With a server, the listed days are its search result. */
    if (server != nil)
        return ContainsDay(shownDays, which);
    return [[store textForDay:which] rangeOfString:search options:NSCaseInsensitiveSearch].location
           != NSNotFound;
}

/* Selects the first match in the open entry, or the next one after the selection. */
- (BOOL)selectMatchFromTop:(BOOL)fromTop
{
    NSString *text = [editor string];
    unsigned start = fromTop ? 0 : NSMaxRange([editor selectedRange]);
    NSRange found;

    if (search == nil || start > [text length])
        return NO;
    found = [text rangeOfString:search options:NSCaseInsensitiveSearch
                          range:NSMakeRange(start, [text length] - start)];
    if (found.location == NSNotFound)
        return NO;
    [editor setSelectedRange:found];
    [editor scrollRangeToVisible:found];
    if ([editor respondsToSelector:@selector(showFindIndicatorForRange:)])
        [editor showFindIndicatorForRange:found];
    return YES;
}

- (void)openDay:(int)which
{
    [self goToDay:which];
    if (search != nil && which == day)
        [self selectMatchFromTop:YES];
}

- (IBAction)showAllEntries:(id)sender
{
    [self setSearch:nil];
    [shownDays release];
    shownDays = [allDays mutableCopy];
    [self refreshList];
    [self syncList];
}

- (IBAction)find:(id)sender
{
    NSMutableArray *values = [NSMutableArray arrayWithObject:search != nil ? search : @""];
    NSMutableArray *matches;
    NSString *text;
    unsigned i;

    if (![self askTitle:@"Find" labels:[NSArray arrayWithObject:@"Find entries containing:"]
                 values:values])
        return;
    text = [values objectAtIndex:0];
    if ([text length] == 0) {
        [self showAllEntries:nil];
        return;
    }
    if (![self saveIfNeeded])
        return;

    if (server != nil) {
        NSString *query = [(NSString *)CFURLCreateStringByAddingPercentEscapes(
                               NULL, (CFStringRef)text, NULL, CFSTR("!*'();:@&=+$,/?%#[] "),
                               kCFStringEncodingUTF8) autorelease];
        NSString *reply, *error = nil;
        int status = [server request:@"GET" path:[@"/search?q=" stringByAppendingString:query]
                                body:nil base:nil text:&reply version:NULL error:&error];

        if (status != 200) {
            ShowMessage(status == 0 ? @"Diary couldn't search on the Diary Server."
                                    : @"The Diary Server refused the search.",
                        Reason(status, reply, error));
            return;
        }
        matches = [DiaryServer daysInReply:reply];
    } else {
        matches = [NSMutableArray array];
        for (i = 0; i < [allDays count]; i++) {
            int each = [[allDays objectAtIndex:i] intValue];

            if ([[store textForDay:each] rangeOfString:text options:NSCaseInsensitiveSearch].location
                    != NSNotFound)
                [matches addObject:Day(each)];
        }
    }

    if ([matches count] == 0) {
        ShowMessage(@"No entries contain that text.", @"");    /* keep the current filter */
        return;
    }
    [self setSearch:text];
    [shownDays release];
    shownDays = [matches retain];
    [self refreshList];
    if (!ContainsDay(shownDays, day))
        [self goToDay:[[shownDays objectAtIndex:0] intValue]];
    [self syncList];
    [self selectMatchFromTop:YES];
}

/* Moves to the next match: first within the open entry, then on to the
   following (older) matching entries, wrapping around to the newest. */
- (IBAction)findAgain:(id)sender
{
    unsigned count = [shownDays count], start, step;

    if (search == nil) {
        [self find:sender];
        return;
    }
    if ([self selectMatchFromTop:NO])
        return;

    start = [shownDays indexOfObject:Day(day)];
    for (step = 1; step <= count; step++) {
        unsigned i = start == NSNotFound ? step - 1 : (start + step) % count;
        int each = [[shownDays objectAtIndex:i] intValue];

        if (each == day) {
            if ([self selectMatchFromTop:YES])
                return;
        } else if ([self entryContainsSearch:each]) {
            [self openDay:each];
            return;
        }
    }
    NSBeep();
}

/* ---------- Commands ---------- */

- (IBAction)saveEntry:(id)sender
{
    [self saveIfNeeded];
}

- (IBAction)previousDay:(id)sender
{
    [self goToDay:day - 1];
}

- (IBAction)nextDay:(id)sender
{
    [self goToDay:day + 1];
}

- (IBAction)today:(id)sender
{
    [self goToDay:Today()];
}

- (void)saveSettings
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    [defaults setObject:[[editor font] fontName] forKey:kFontNameKey];
    [defaults setFloat:[[editor font] pointSize] forKey:kFontSizeKey];
    [defaults synchronize];
}

/* File > Diary Server...: where the entries are kept. */
- (IBAction)chooseServer:(id)sender
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *address = [defaults stringForKey:kServerKey];
    NSString *key = [defaults stringForKey:kServerKeyKey];
    NSMutableArray *values = [NSMutableArray arrayWithObjects:address != nil ? address : @"",
                                                              key != nil ? key : @"", nil];

    if (![self askTitle:@"Diary Server"
                 labels:[NSArray arrayWithObjects:
                         @"Keep the entries on a Diary Server at this address (host or host:port; "
                         @"leave it empty for the \"Diary Entries\" folder):",
                         @"The server's key (leave it empty if it has none):", nil]
                 values:values])
        return;
    if (![self saveIfNeeded])
        return;

    address = [[values objectAtIndex:0] stringByTrimmingCharactersInSet:
               [NSCharacterSet whitespaceCharacterSet]];
    key = [address length] > 0 ? [values objectAtIndex:1] : @"";
    [defaults setObject:address forKey:kServerKey];
    [defaults setObject:key forKey:kServerKeyKey];
    [defaults synchronize];

    [server release];
    server = [address length] > 0 ? [[DiaryServer alloc] initWithAddress:address key:key] : nil;
    [self updateTitle];
    [self scanEntries];
    [self showAllEntries:nil];
    [self loadEntry];
}

- (BOOL)validateMenuItem:(NSMenuItem *)item
{
    if ([item action] == @selector(showAllEntries:))
        return search != nil;
    if ([item action] == @selector(saveEntry:))
        return changed;
    return YES;
}

/* ---------- Delegates ---------- */

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
    NSString *address = [[NSUserDefaults standardUserDefaults] stringForKey:kServerKey];

    store = [[EntryStore alloc] initWithFolder:[EntryStore defaultFolder]];
    if ([address length] > 0)
        server = [[DiaryServer alloc] initWithAddress:address
                                                  key:[[NSUserDefaults standardUserDefaults]
                                                       stringForKey:kServerKeyKey]];
    [self createWindow];
    [self updateTitle];
    day = Today();
    [self scanEntries];
    [self showAllEntries:nil];
    [self loadEntry];
    [window makeKeyAndOrderFront:nil];
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
    if ([self saveIfNeeded])
        return NSTerminateNow;
    return NSRunAlertPanel(@"The entry could not be saved.", @"Quit anyway?",
                           @"Cancel", @"Quit", nil) == NSAlertDefaultReturn ? NSTerminateCancel
                                                                            : NSTerminateNow;
}

- (void)applicationWillTerminate:(NSNotification *)notification
{
    [self saveSettings];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender
{
    return YES;
}

- (BOOL)windowShouldClose:(id)sender
{
    return [self saveIfNeeded];
}

- (void)textDidChange:(NSNotification *)notification
{
    changed = YES;
    [window setDocumentEdited:YES];
}

- (int)numberOfRowsInTableView:(NSTableView *)table
{
    return [shownDays count];
}

- (id)tableView:(NSTableView *)table objectValueForTableColumn:(NSTableColumn *)column row:(int)row
{
    return ShortDate([[shownDays objectAtIndex:row] intValue]);
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
    int row = [list selectedRow];

    if (!syncingList && row >= 0)
        [self openDay:[[shownDays objectAtIndex:row] intValue]];
}

- (BOOL)calendarHasEntry:(int)which
{
    return ContainsDay(shownDays, which);
}

- (int)calendarOpenDay
{
    return day;
}

- (void)calendarClickedDay:(int)which
{
    [self openDay:which];
}

@end
