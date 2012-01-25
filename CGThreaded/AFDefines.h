// taken and modified from http://www.gehacktes.net/2009/02/macros-for-iphone-programming/

#ifdef DEBUG
#define AFLog(format, ...) NSLog(@"%s | %@", __PRETTY_FUNCTION__,[NSString stringWithFormat:format, ## __VA_ARGS__])
#define AFDebug(format, ...) NSLog(@"%s | %@", __PRETTY_FUNCTION__,[NSString stringWithFormat:format, ## __VA_ARGS__])
#define AF_ENTER AFDebug(@"%@", @"entered")
#define AF_EXIT AFDebug(@"%@", @"exiting")
#define AF_MARK	AFDebug(@"")
#define AF_START_TIMER NSTimeInterval ___start = [NSDate timeIntervalSinceReferenceDate]
#define AF_END_TIMER(msg) 	NSTimeInterval ___stop = [NSDate timeIntervalSinceReferenceDate]; AFDebug([NSString stringWithFormat:@"%@ | Time=%f", msg, ___stop - ___start])
#else
#define AFLog(format, ...) NSLog(@"%s | %@", __PRETTY_FUNCTION__,[NSString stringWithFormat:format, ## __VA_ARGS__])
#define AFDebug(format, ...)
#define AF_ENTER
#define AF_EXIT
#define AF_MARK
#define AF_START_TIMER
#define AF_END_TIMER(msg)
#endif
