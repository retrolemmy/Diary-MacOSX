/* A client for the Diary Server (https://github.com/retrolemmy/Diary-Server):
   plain HTTP, entries in UTF-8 with LF line ends. */

#import <Foundation/Foundation.h>

#define kDefaultPort 8642

@interface DiaryServer : NSObject
{
    NSString *address;      /* host:port */
    NSString *key;
}

/* address is "host" or "host:port"; key may be empty. */
- (id)initWithAddress:(NSString *)serverAddress key:(NSString *)serverKey;
- (NSString *)address;

/* Sends a request and waits for the answer (10 seconds at most for a
   connection). Returns the HTTP status, or 0 if the server couldn't be
   reached; then *error says why. *text gets the response body and *version
   its X-Diary-Version; base, if not nil, is sent as X-Diary-Base. Any of
   the out parameters may be NULL. */
- (int)request:(NSString *)method path:(NSString *)path body:(NSString *)body
          base:(NSString *)base text:(NSString **)text version:(NSString **)version
         error:(NSString **)error;

/* The days in a reply to GET /entries or GET /search, as NSNumbers. */
+ (NSMutableArray *)daysInReply:(NSString *)reply;

/* A short explanation for a refused request. */
+ (NSString *)reasonForStatus:(int)status text:(NSString *)text;

@end
