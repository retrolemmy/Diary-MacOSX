/* Diary for Mac OS X 10.4 and 10.5: a simple one-page-per-day journal.
   Without a nib, so the menus are built here. */

#import <Cocoa/Cocoa.h>
#import "DiaryController.h"

/* Still in AppKit, but no longer in its headers. */
@interface NSApplication (AppleMenu)
- (void)setAppleMenu:(NSMenu *)menu;
@end

static NSMenu *AddMenu(NSMenu *bar, NSString *title)
{
    NSMenuItem *item = [bar addItemWithTitle:title action:NULL keyEquivalent:@""];
    NSMenu *menu = [[[NSMenu alloc] initWithTitle:title] autorelease];

    [bar setSubmenu:menu forItem:item];
    return menu;
}

static NSMenuItem *AddItem(NSMenu *menu, NSString *title, SEL action, NSString *key)
{
    return [menu addItemWithTitle:title action:action keyEquivalent:key];
}

static void BuildMenus(void)
{
    NSMenu *bar = [[[NSMenu alloc] initWithTitle:@""] autorelease];
    NSMenu *menu, *windows;
    NSMenuItem *item;
    NSFontManager *fonts = [NSFontManager sharedFontManager];

    menu = AddMenu(bar, @"Diary");
    AddItem(menu, @"About Diary", @selector(orderFrontStandardAboutPanel:), @"");
    [menu addItem:[NSMenuItem separatorItem]];
    AddItem(menu, @"Hide Diary", @selector(hide:), @"h");
    item = AddItem(menu, @"Hide Others", @selector(hideOtherApplications:), @"h");
    [item setKeyEquivalentModifierMask:NSCommandKeyMask | NSAlternateKeyMask];
    AddItem(menu, @"Show All", @selector(unhideAllApplications:), @"");
    [menu addItem:[NSMenuItem separatorItem]];
    AddItem(menu, @"Quit Diary", @selector(terminate:), @"q");
    [NSApp setAppleMenu:menu];

    menu = AddMenu(bar, @"File");
    AddItem(menu, @"Save", @selector(saveEntry:), @"s");
    [menu addItem:[NSMenuItem separatorItem]];
    AddItem(menu, @"Diary Server...", @selector(chooseServer:), @"");
    [menu addItem:[NSMenuItem separatorItem]];
    AddItem(menu, @"Close", @selector(performClose:), @"w");

    menu = AddMenu(bar, @"Edit");
    AddItem(menu, @"Undo", @selector(undo:), @"z");
    AddItem(menu, @"Redo", @selector(redo:), @"Z");
    [menu addItem:[NSMenuItem separatorItem]];
    AddItem(menu, @"Cut", @selector(cut:), @"x");
    AddItem(menu, @"Copy", @selector(copy:), @"c");
    AddItem(menu, @"Paste", @selector(paste:), @"v");
    AddItem(menu, @"Select All", @selector(selectAll:), @"a");
    [menu addItem:[NSMenuItem separatorItem]];
    AddItem(menu, @"Find...", @selector(find:), @"f");
    AddItem(menu, @"Find Again", @selector(findAgain:), @"g");
    AddItem(menu, @"Show All Entries", @selector(showAllEntries:), @"");

    menu = AddMenu(bar, @"Go");
    AddItem(menu, @"Previous Day", @selector(previousDay:), @"[");
    AddItem(menu, @"Next Day", @selector(nextDay:), @"]");
    AddItem(menu, @"Today", @selector(today:), @"t");

    /* The entry is plain text, so a font applies to all of it. */
    menu = AddMenu(bar, @"Format");
    item = AddItem(menu, @"Show Fonts", @selector(orderFrontFontPanel:), @"t");
    [item setKeyEquivalentModifierMask:NSCommandKeyMask | NSAlternateKeyMask];
    [item setTarget:fonts];
    item = AddItem(menu, @"Bigger", @selector(modifyFont:), @"+");
    [item setTag:NSSizeUpFontAction];
    [item setTarget:fonts];
    item = AddItem(menu, @"Smaller", @selector(modifyFont:), @"-");
    [item setTag:NSSizeDownFontAction];
    [item setTarget:fonts];

    windows = AddMenu(bar, @"Window");
    AddItem(windows, @"Minimize", @selector(performMiniaturize:), @"m");
    AddItem(windows, @"Zoom", @selector(performZoom:), @"");

    [NSApp setMainMenu:bar];
    [NSApp setWindowsMenu:windows];
}

int main(int argc, const char *argv[])
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    DiaryController *controller;

    [NSApplication sharedApplication];
    BuildMenus();
    controller = [[DiaryController alloc] init];
    [NSApp setDelegate:controller];
    [NSApp run];

    [controller release];
    [pool release];
    return 0;
}
