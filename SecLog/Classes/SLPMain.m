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
        
        // Set up console Logging.
        _outputDateToConsoleLog = TRUE;
        _consoleDateFormatter = [[NSDateFormatter alloc] init];
        _consoleDateFormatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
        _consoleDateFormatter.dateFormat = @"yyyy-MM-dd'.'HH:mm:ss";
        _consoleDateFormatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
        
        // Set up file logging
        _fileWriter = [[SLPFileWriter alloc] init];
    }
    return self;
}

- (void)logMessage:(NSString *)message
      logLevel:(SecLogLevel)level {
    NSString *messageToWrite = message && [message isKindOfClass:[NSString class]] ? message : @"(no log message given)";
    
    if (level <= self.consoleLoggingLevel) {
        NSString* dateStr = self.outputDateToConsoleLog ?
            [[self.consoleDateFormatter stringFromDate:[NSDate date]] stringByAppendingString:@" "] :
        @"";
        NSLog(@"%@%@", dateStr, messageToWrite);
    }
    
    if (level <= self.fileLoggingLevel) {
        [self.fileWriter logText:message
                        logLevel:level];
    }
}

-(void)logData:(NSData *)data
         logLevel:(SecLogLevel)level {
    if (level <= self.fileLoggingLevel) {
        [self.fileWriter logGenericData:data
                               logLevel:level];
    }
}

-(void)logImage:(NSData *)imageData
          logLevel:(SecLogLevel)level {
    if (level <= self.fileLoggingLevel) {
        [self.fileWriter logImageData:imageData
                               logLevel:level];
    }
}

-(void)logData: (NSData *)data      { [self logData:data       logLevel:DEFAULT_LOG_LEVEL]; }
-(void)logImage:(NSData *)imageData { [self logImage:imageData logLevel:DEFAULT_LOG_LEVEL]; }


// Shortcut log functions
-(void)fatal:(NSString *)fatalMessage   { [self logMessage:fatalMessage   logLevel:SECLOG_FATAL];   }
-(void)error:(NSString *)errorMessage   { [self logMessage:errorMessage   logLevel:SECLOG_ERROR];   }
-(void)warn: (NSString *)warningMessage { [self logMessage:warningMessage logLevel:SECLOG_WARNING]; }
-(void)info: (NSString *)infoMessage    { [self logMessage:infoMessage    logLevel:SECLOG_INFO];    }
-(void)debug:(NSString *)debugMessage   { [self logMessage:debugMessage   logLevel:SECLOG_DEBUG];   }
-(void)trace:(NSString *)traceMessage   { [self logMessage:traceMessage   logLevel:SECLOG_TRACE];   }

// Use the max values to cleanup the logging folder.
// Suggest calling this on every start up.
-(void)cleanup {
    [SLPFolder cleanOutLogsAndKeychainEntriesKeeping:4
                                 maxTotalLogSizeInMB:1];
}


@end
