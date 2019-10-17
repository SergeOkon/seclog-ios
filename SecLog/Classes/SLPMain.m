#import "SLPMain.h"
#import "SLPFileWriter.h"
#import "SLPFolder.h"

// DEFAULTS
const int DEFAULT_LOG_LEVEL = SECLOG_INFO;
#define DEFAULT_MAX_LOG_FILES @24
#define DEFAULT_MAX_LOG_FILE_SIZE_MIB @10.0

@interface SLPMain()
@property (nonatomic) SLPFileWriter* fileWriter;

@property (nonatomic) NSDateFormatter* consoleDateFormatter;

@end

@implementation SLPMain

// https://stackoverflow.com/q/5720029
+ (instancetype)sharedInstance {
    static dispatch_once_t once;
    static id sharedInstance;
    dispatch_once(&once, ^{  sharedInstance = [[self alloc] init]; });
    return sharedInstance;
}

- (instancetype) init {
    self = [super init];
    if (self) {
        // Set up defaults
        _consoleLoggingLevel = DEFAULT_LOG_LEVEL;
        _fileLoggingLevel = DEFAULT_LOG_LEVEL;
        _maxLogfiles = DEFAULT_MAX_LOG_FILES;
        _maxLogSpaceMib = DEFAULT_MAX_LOG_FILE_SIZE_MIB;
        
        [SLPFolder confirmOrCreateLogFolder];
        _fileWriter = [[SLPFileWriter alloc] init];
        _outputDateToConsoleLog = TRUE;
        _consoleDateFormatter = [[NSDateFormatter alloc] init];
        _consoleDateFormatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
        _consoleDateFormatter.dateFormat = @"yyyy-MM-dd'.'HH:mm:ss";
        _consoleDateFormatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
    }
    return self;
}

- (void)log:(NSString *)message level:(SecLogLevel)level {
    NSString *messageToWrite = message && [message isKindOfClass:[NSString class]] ? message : @"(no log message given)";
    
    if (self.consoleLoggingLevel >= self.consoleLoggingLevel) {
        NSString* dateStr = self.outputDateToConsoleLog ?
            [[self.consoleDateFormatter stringFromDate:[NSDate date]] stringByAppendingString:@" "] :
        @"";
        NSLog(@"%@%@", dateStr, messageToWrite);
    }
    
    if (self.consoleLoggingLevel >= self.fileLoggingLevel) {
            // TODO - send to file logging queue.
    }
}

// Shortcut log functions
-(void)fatal:(NSString *)fatalMessage   { [self log:fatalMessage level:SECLOG_FATAL]; }
-(void)error:(NSString *)errorMessage   { [self log:errorMessage level:SECLOG_ERROR]; }
-(void)warn: (NSString *)warningMessage { [self log:warningMessage level:SECLOG_WARNING]; }
-(void)info: (NSString *)infoMessage    { [self log:infoMessage level:SECLOG_INFO]; }
-(void)debug:(NSString *)debugMessage   { [self log:debugMessage level:SECLOG_DEBUG]; }
-(void)trace:(NSString *)traceMessage   { [self log:traceMessage level:SECLOG_TRACE]; }

// Use the max values to cleanup the logging folder.
// Suggest calling this on every start up.
-(void)cleanup {
    // TODO - write the cleanup procedure.
}


@end
