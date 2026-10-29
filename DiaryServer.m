#import "DiaryServer.h"
#import "Dates.h"

@implementation DiaryServer

- (id)initWithAddress:(NSString *)serverAddress key:(NSString *)serverKey
{
    if ((self = [super init]) != nil) {
        serverAddress = [serverAddress stringByTrimmingCharactersInSet:
                         [NSCharacterSet whitespaceCharacterSet]];
        if ([serverAddress rangeOfString:@":"].location == NSNotFound)
            serverAddress = [NSString stringWithFormat:@"%@:%d", serverAddress, kDefaultPort];
        address = [serverAddress copy];
        key = [(serverKey != nil ? serverKey : @"") copy];
    }
    return self;
}

- (void)dealloc
{
    [address release];
    [key release];
    [super dealloc];
}

- (NSString *)address
{
    return address;
}

/* The value of a response header, whatever its spelling. */
static NSString *HeaderValue(NSHTTPURLResponse *response, NSString *name)
{
    NSDictionary *headers = [response allHeaderFields];
    NSEnumerator *names = [headers keyEnumerator];
    NSString *each;

    while ((each = [names nextObject]) != nil)
        if ([each caseInsensitiveCompare:name] == NSOrderedSame)
            return [headers objectForKey:each];
    return nil;
}

- (int)request:(NSString *)method path:(NSString *)path body:(NSString *)body
          base:(NSString *)base text:(NSString **)text version:(NSString **)version
         error:(NSString **)error
{
    NSString *separator = [path rangeOfString:@"?"].location == NSNotFound ? @"?" : @"&";
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@%@%@charset=utf-8",
                                       address, path, separator]];
    NSMutableURLRequest *request;
    NSURLResponse *response = nil;
    NSError *failure = nil;
    NSData *data;
    NSString *reply;

    if (text != NULL)
        *text = @"";
    if (version != NULL)
        *version = nil;
    if (url == nil) {
        if (error != NULL)
            *error = @"That isn't a valid server address.";
        return 0;
    }

    request = [NSMutableURLRequest requestWithURL:url
                                      cachePolicy:NSURLRequestReloadIgnoringCacheData
                                  timeoutInterval:10];
    [request setHTTPMethod:method];
    if ([key length] > 0)
        [request setValue:key forHTTPHeaderField:@"X-Diary-Key"];
    if (base != nil)
        [request setValue:base forHTTPHeaderField:@"X-Diary-Base"];
    if (body != nil) {
        NSData *bytes = [body dataUsingEncoding:NSUTF8StringEncoding];

        [request setValue:@"text/plain; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
        [request setValue:[NSString stringWithFormat:@"%u", (unsigned)[bytes length]]
                 forHTTPHeaderField:@"Content-Length"];
        [request setHTTPBody:bytes];
    }

    data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&failure];
    if (response == nil || ![response isKindOfClass:[NSHTTPURLResponse class]]) {
        if (error != NULL)
            *error = failure != nil ? [failure localizedDescription]
                                    : @"The server didn't answer.";
        return 0;
    }

    reply = data != nil ? [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease]
                        : @"";
    if (reply == nil)
        reply = [[[NSString alloc] initWithData:data encoding:NSISOLatin1StringEncoding] autorelease];
    if (text != NULL)
        *text = reply;
    if (version != NULL)
        *version = HeaderValue((NSHTTPURLResponse *)response, @"X-Diary-Version");
    return [(NSHTTPURLResponse *)response statusCode];
}

+ (NSMutableArray *)daysInReply:(NSString *)reply
{
    NSArray *lines = [reply componentsSeparatedByString:@"\n"];
    NSMutableArray *days = [NSMutableArray array];
    unsigned i;
    int day;

    for (i = 0; i < [lines count]; i++) {
        NSString *line = [lines objectAtIndex:i];

        if ([line length] >= 10 && ParseEntryName([line substringToIndex:10], &day))
            [days addObject:[NSNumber numberWithInt:day]];
    }
    return days;
}

+ (NSString *)reasonForStatus:(int)status text:(NSString *)text
{
    NSString *reason;

    if (status == 403)
        return @"The server wants a different key.";
    reason = [text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if ([reason length] == 0)
        reason = [NSString stringWithFormat:@"The server answered with error %d.", status];
    return reason;
}

@end
