@import Foundation;

#import "SLPConstants.h"
#import "SLPFolder.h"
#import "SLPKeychain.h"
#import "SLPFrame.h"
#import "SLPBlockCrypto.h"

#import "SLPFileWriter.h"

const char *DISPATCH_QUEUE_NAME = "SecLog Serial File Queue";



@interface SLPFileWriter()

@property (nonatomic, readwrite) NSUInteger totalLogged;
@property (nonatomic, readwrite) NSUInteger nLoggedText;
@property (nonatomic, readwrite) NSUInteger nLoggedGeneralData;
@property (nonatomic, readwrite) NSUInteger nLoggedImages;

@property (nonatomic) NSDate *creationDate;
@property (nonatomic) NSDateFormatter *dateFormatter;
@property (nonatomic) NSFileManager *fileManager;
@property (nonatomic) SLPBlockCrypto *blockCrypto;


@property (nonatomic) NSFileHandle* fileHandle;
@property (readwrite, strong, nonatomic) dispatch_queue_t serialQueue;

@property (atomic) BOOL queueOpen;
@property (atomic) BOOL readyToShutdown;

@end

@implementation SLPFileWriter

- (instancetype)init {
    self = [super init];
    if (self) {
        _fileManager = [[NSFileManager alloc] init];
        _serialQueue = dispatch_queue_create("SecLog Serial Queue", DISPATCH_QUEUE_SERIAL);
        _queueOpen = TRUE;
        _readyToShutdown = FALSE;
        
        _dateFormatter = [[NSDateFormatter alloc] init];
        _dateFormatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
        [_dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
        [_dateFormatter setDateFormat:@"YYMMddHHmmssSSS0"];
        
        __weak SLPFileWriter *weakSelf = self;
        dispatch_async(self.serialQueue, ^{
            if (!weakSelf) return;
            
            // Create log folder, or rename the old log file, if present.
            [SLPFolder confirmOrCreateLogFolder];
            [SLPFolder renamePreviousLogFile];
        
            // Create a New Log file
            NSString *logFile =[SLPFolder presentLogFilePath];
            [weakSelf.fileManager createFileAtPath:logFile contents:[NSData new] attributes:nil];
            weakSelf.fileHandle = [NSFileHandle fileHandleForWritingAtPath:logFile];
            if (weakSelf && !weakSelf.fileHandle) {
                NSLog(@"SLPFileWriter: could not start present log file at '%@'", logFile);
                return;
            }
            
            // Generate Keys and Header data
            weakSelf.creationDate = [NSDate date];
            unsigned char reservedAsZerosForNow[8] = { 0, 0, 0, 0, 0, 0, 0, 0 };
            NSString *logName = [weakSelf.dateFormatter stringFromDate:weakSelf.creationDate];
            NSData* aesKey = [SLPKeychain randomDataGenerateSecure:32]; // 32b * 8 = 256bits
            NSData* IVs =[SLPKeychain randomDataGenerateSecure:16]; // 16b of IVs
            unsigned long long dateMs = (unsigned long long) weakSelf.creationDate.timeIntervalSince1970 * 1000;
            
            // Write the file header for the current log
            NSMutableData *header = [[NSMutableData alloc] init];
            [header appendData:[SLP_INPROGRESS_FILE_SIGNATURE_V1 dataUsingEncoding:NSASCIIStringEncoding]];
            [header appendBytes:&dateMs length:8];
            [header appendBytes:reservedAsZerosForNow length:sizeof(reservedAsZerosForNow)];
            [header appendData:[logName dataUsingEncoding:NSASCIIStringEncoding]];
            [header appendData:IVs];
            [weakSelf.fileHandle writeData:header];
            
            // Initiate the Block Cipher.
            weakSelf.blockCrypto = [[SLPBlockCrypto alloc] initEncryptorWithKey:aesKey
                                                                            ivs:IVs];
            [SLPKeychain keychainStoreData:aesKey
                            withIdentifier:logName];
        });
    }
    return self;
}

-(void)logText:(NSString*)text
      logLevel:(unsigned char)logLevel {
    if (!self.queueOpen) return;
    
    NSDate *now = [NSDate date];
    __weak SLPFileWriter *weakSelf = self;
    
    dispatch_async(self.serialQueue, ^{
        if (!weakSelf) return;
        
        NSTimeInterval timeInterval = [now timeIntervalSinceDate:weakSelf.creationDate];
        NSData *plaintextFrame = [SLPFrame frameWithText:text logLevel:logLevel on:timeInterval];
        [weakSelf.fileHandle writeData:[weakSelf.blockCrypto encryptBlock:plaintextFrame]];
    });
}

-(void)logGenericData:(NSData *)genericData
             logLevel:(unsigned char)logLevel {
    if (!self.queueOpen) return;
    
    NSDate *now = [NSDate date];
    __weak SLPFileWriter *weakSelf = self;
    
    dispatch_async(self.serialQueue, ^{
        if (!weakSelf) return;
        
        NSTimeInterval timeInterval = [now timeIntervalSinceDate:weakSelf.creationDate];
        NSData *plaintextFrame = [SLPFrame frameWithGenericData:genericData on:timeInterval logLevel:logLevel];
        [weakSelf.fileHandle writeData:[weakSelf.blockCrypto encryptBlock:plaintextFrame]];
    });
}

-(void)logImageData:(NSData *)imageData
           logLevel:(unsigned char)logLevel {
    if (!self.queueOpen) return;
    
    NSDate *now = [NSDate date];
    __weak SLPFileWriter *weakSelf = self;
    
    dispatch_async(self.serialQueue, ^{
        if (!weakSelf) return;
        
        NSTimeInterval timeInterval = [now timeIntervalSinceDate:weakSelf.creationDate];
        NSData *plaintextFrame = [SLPFrame frameWithImageData:imageData on:timeInterval logLevel:logLevel];
        [weakSelf.fileHandle writeData:[weakSelf.blockCrypto encryptBlock:plaintextFrame]];
    });
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
