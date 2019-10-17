#import "SLPFolder.h"

#import "SLPFileWriter.h"

NSString *PRESENT_LOG_FILENAME = @"seclog.present.bin";

@interface SLPFileWriter()
@property (nonatomic) NSFileManager *fileManager;
@property (nonatomic) NSFileHandle* fileHandle;
@property (readwrite, strong, nonatomic) dispatch_queue_t serialQueue;
@property (atomic) BOOL queueOpen;
@property (atomic) BOOL readyToShutdown;
@end

const char* DISPATCH_QUEUE_NAME = "SecLog Serial File Queue";

@implementation SLPFileWriter

- (instancetype)init {
    self = [super init];
    if (self) {
        _fileManager = [[NSFileManager alloc] init];
        _serialQueue = dispatch_queue_create("SecLog Serial Queue", DISPATCH_QUEUE_SERIAL);
        _queueOpen = TRUE;
        _readyToShutdown = FALSE;
        __weak SLPFileWriter *weakSelf = self;
        dispatch_async(self.serialQueue, ^{
            NSString *logFile =[SLPFolder presentLogFilePath];
            weakSelf.fileHandle = [NSFileHandle fileHandleForWritingAtPath:logFile];
            if (weakSelf && !weakSelf.fileHandle) {
                NSLog(@"SLPFileWriter: could not present log file at '%@'", logFile);
            }
        });
    }
    return self;
}

-(void)logText:(NSString*)text {
    // TODO
}


- (void)dealloc {
    // Drain the serial queue of events. It will be released once its reference is closed.
    self.queueOpen = FALSE;
    __weak SLPFileWriter *weakSelf = self;
    dispatch_async(self.serialQueue, ^{ weakSelf.readyToShutdown = TRUE; });
    while (!self.readyToShutdown ) {
        [NSThread sleepForTimeInterval:20];
    }
    
    // And close the logfile
    [self.fileHandle synchronizeFile];
    [self.fileHandle closeFile];
}

@end



