@import Foundation;

NS_ASSUME_NONNULL_BEGIN

typedef enum {
    OFF = 0,
    SECLOG_FATAL = 10,
    SECLOG_ERROR = 20,
    SECLOG_WARNING = 30,
    SECLOG_INFO = 40,
    SECLOG_DEBUG = 50,
    SECLOG_TRACE = 60,
} SecLogLevel;

@interface SLPMain : NSObject

@property (nonatomic, readwrite) SecLogLevel consoleLoggingLevel;
@property (nonatomic, readwrite) SecLogLevel fileLoggingLevel;

@property (nonatomic, readwrite) BOOL outputDateToConsoleLog;

@property (nonatomic, readwrite) NSNumber *maxLogfiles;
@property (nonatomic, readwrite) NSNumber *maxLogSpaceMib;

+ (instancetype)sharedInstance;

// https://stackoverflow.com/a/22481129
+ (instancetype)alloc __attribute__((unavailable("not available, use sharedInstance")));
- (instancetype)init __attribute__((unavailable("not available, use sharedInstance")));
+ (instancetype)new __attribute__((unavailable("not available, use sharedInstance")));
- (instancetype)copy __attribute__((unavailable("not available, use sharedInstance")));

- (void)log:(NSString *)message level:(SecLogLevel)level;
- (void)fatal:(NSString *)fatalMessage;
- (void)error:(NSString *)errorMessage;
- (void)warn:(NSString *)warningMessage;
- (void)info:(NSString *)infoMessage;
- (void)debug:(NSString *)debugMessage;
- (void)trace:(NSString *)traceMessage;

- (void)cleanup;

@end

NS_ASSUME_NONNULL_END
