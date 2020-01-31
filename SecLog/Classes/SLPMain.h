@import Foundation;

NS_ASSUME_NONNULL_BEGIN

// Keep these values in the range of 0-255
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

+ (instancetype)sharedInstance;

// https://stackoverflow.com/a/22481129
+ (instancetype)alloc __attribute__((unavailable("not available, use sharedInstance")));
- (instancetype)init __attribute__((unavailable("not available, use sharedInstance")));
+ (instancetype)new __attribute__((unavailable("not available, use sharedInstance")));
- (instancetype)copy __attribute__((unavailable("not available, use sharedInstance")));

// Convinient Calls for Messages
- (void)fatal:(NSString *)fatalMessage;
- (void)error:(NSString *)errorMessage;
- (void)warn:(NSString *)warningMessage;
- (void)info:(NSString *)infoMessage;
- (void)debug:(NSString *)debugMessage;
- (void)trace:(NSString *)traceMessage;

// Generic Loggers for all data types.
-(void)logMessage:(NSString *)message logLevel:(SecLogLevel)level;
-(void)logData:(NSData *)data logLevel:(SecLogLevel)level;
-(void)logImage:(NSData *)imageData logLevel:(SecLogLevel)level;
-(void)logData: (NSData *)data;
-(void)logImage:(NSData *)imageData;

+(void)cleanUpKeepingLogFiles:(NSUInteger)nFiles
         maxTotalLogSizeInMiB:(NSUInteger)maxSizeMb;

@end

NS_ASSUME_NONNULL_END
