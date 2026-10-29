/* The local "Diary Entries" folder: one plain text file per day, named
   YYYY-MM-DD. Diary writes UTF-8 with LF line ends and reads the files of
   the classic Mac (MacRoman, CR) and Amiga (ISO Latin-1, LF) versions too. */

#import <Foundation/Foundation.h>

@interface EntryStore : NSObject
{
    NSString *folder;
}

/* A "Diary Entries" folder next to the application if there is one (as the
   classic Mac version keeps it), otherwise ~/Documents/Diary Entries. */
+ (NSString *)defaultFolder;

- (id)initWithFolder:(NSString *)path;
- (NSString *)folder;

/* All days with an entry, as NSNumbers, newest first. */
- (NSMutableArray *)days;

/* The entry's text without a final line end, or nil if there is none. */
- (NSString *)textForDay:(int)day;

/* Saves the text; an empty text deletes the entry. */
- (BOOL)setText:(NSString *)text forDay:(int)day;

@end

/* Decodes an entry file from any Diary version and gives it LF line ends. */
NSString *DecodeEntry(NSData *data);
