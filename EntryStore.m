#import "EntryStore.h"
#import "Dates.h"

NSString *DecodeEntry(NSData *data)
{
    const unsigned char *bytes = [data bytes];
    unsigned length = [data length], i;
    NSString *text;
    NSMutableString *result;
    BOOL hasLF = NO, macOnly = NO;

    text = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
    if (text == nil) {
        /* The Amiga version always ends its files with LF; the classic Mac
           one writes CR line ends, and only MacRoman uses 0x80..0x9F. */
        for (i = 0; i < length; i++) {
            if (bytes[i] == '\n')
                hasLF = YES;
            else if (bytes[i] >= 0x80 && bytes[i] < 0xA0)
                macOnly = YES;
        }
        text = [[[NSString alloc] initWithData:data
                                      encoding:(!hasLF || macOnly) ? NSMacOSRomanStringEncoding
                                                                   : NSISOLatin1StringEncoding] autorelease];
    }
    result = [NSMutableString stringWithString:text != nil ? text : @""];
    [result replaceOccurrencesOfString:@"\r\n" withString:@"\n" options:0
                                 range:NSMakeRange(0, [result length])];
    [result replaceOccurrencesOfString:@"\r" withString:@"\n" options:0
                                 range:NSMakeRange(0, [result length])];
    return result;
}

@implementation EntryStore

+ (NSString *)defaultFolder
{
    NSString *beside = [[[[NSBundle mainBundle] bundlePath] stringByDeletingLastPathComponent]
                        stringByAppendingPathComponent:@"Diary Entries"];
    BOOL isFolder;

    if ([[NSFileManager defaultManager] fileExistsAtPath:beside isDirectory:&isFolder] && isFolder)
        return beside;
    return [[NSHomeDirectory() stringByAppendingPathComponent:@"Documents"]
            stringByAppendingPathComponent:@"Diary Entries"];
}

- (id)initWithFolder:(NSString *)path
{
    if ((self = [super init]) != nil)
        folder = [path copy];
    return self;
}

- (void)dealloc
{
    [folder release];
    [super dealloc];
}

- (NSString *)folder
{
    return folder;
}

- (NSString *)pathForDay:(int)day
{
    return [folder stringByAppendingPathComponent:EntryName(day)];
}

static int NewestFirst(id a, id b, void *context)
{
    return [b compare:a];
}

- (NSMutableArray *)days
{
    NSArray *names = [[NSFileManager defaultManager] directoryContentsAtPath:folder];
    NSMutableArray *days = [NSMutableArray array];
    unsigned i;
    int day;

    for (i = 0; i < [names count]; i++)
        if (ParseEntryName([names objectAtIndex:i], &day))
            [days addObject:[NSNumber numberWithInt:day]];
    [days sortUsingFunction:NewestFirst context:NULL];
    return days;
}

- (NSString *)textForDay:(int)day
{
    NSData *data = [NSData dataWithContentsOfFile:[self pathForDay:day]];
    NSString *text;

    if (data == nil)
        return nil;
    text = DecodeEntry(data);
    if ([text hasSuffix:@"\n"])
        text = [text substringToIndex:[text length] - 1];   /* setText adds one */
    return text;
}

- (BOOL)setText:(NSString *)text forDay:(int)day
{
    NSFileManager *files = [NSFileManager defaultManager];
    NSString *path = [self pathForDay:day];
    BOOL isFolder;

    if ([text length] == 0) {
        /* An emptied entry is removed rather than kept as an empty file. */
        return ![files fileExistsAtPath:path] || [files removeFileAtPath:path handler:nil];
    }
    if (![files fileExistsAtPath:folder isDirectory:&isFolder]) {
        if (![files createDirectoryAtPath:folder attributes:nil])
            return NO;
    } else if (!isFolder) {
        return NO;
    }
    return [[[text stringByAppendingString:@"\n"] dataUsingEncoding:NSUTF8StringEncoding]
            writeToFile:path atomically:YES];
}

@end
