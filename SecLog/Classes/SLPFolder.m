#import "SLPKeychain.h"

#import "SLPFolder.h"

NSString* SECURE_LOG_FOLDER_NAME = @"SecureLog";
NSString* SECURE_LOG_PRESENT_NAME = @"seclog.present.bin";

const int ATTEMPTS_TO_CLOSE = 10;
const NSTimeInterval WAIT_INTERVAL_FOR_ATTEMPTS_TO_CLOSE = 0.1;

@implementation SLPFolder

// https://stackoverflow.com/questions/6644004
+ (BOOL) isAllDigits:(NSString *)string
{
    NSCharacterSet* nonNumbers = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
    NSRange r = [string rangeOfCharacterFromSet: nonNumbers];
    return r.location == NSNotFound && string.length > 0;
}

+(NSString *) getLogFolderPath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    NSString *libraryFolder = [paths objectAtIndex:0]; // Get documents folder
    NSString *logPath = [libraryFolder stringByAppendingPathComponent:SECURE_LOG_FOLDER_NAME];
    return logPath;
}

+(void) confirmOrCreateLogFolder {
    NSError *error;
    NSString *logPath = [SLPFolder getLogFolderPath];

    if (![[NSFileManager defaultManager] fileExistsAtPath:logPath]) {
        if (![[NSFileManager defaultManager] createDirectoryAtPath:logPath withIntermediateDirectories:NO attributes:nil error:&error]) {
            NSLog(@"Unable to create '%@', error: %@", logPath, error);
            return;
        }
        if (![[NSURL fileURLWithPath:logPath] setResourceValue: [NSNumber numberWithBool: YES]
                                                         forKey: NSURLIsExcludedFromBackupKey error: &error]) {
            NSLog(@"Unable to exclude from backup '%@', error: %@", logPath, error);
            return;
        }
    }
}

+(NSString *) presentLogFilePath {
    return [[self getLogFolderPath] stringByAppendingPathComponent:SECURE_LOG_PRESENT_NAME];
}

+(void) deletePreviousFile {
    NSString *presentLogPath = [self presentLogFilePath];
    if ([[NSFileManager defaultManager] fileExistsAtPath:presentLogPath]) {
        [[NSFileManager defaultManager] removeItemAtPath:presentLogPath error:nil];
    }
}

+(NSString *) getLogNameFromFilePath:(NSString *)path {
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        NSFileHandle *handle = [NSFileHandle fileHandleForReadingAtPath:path];
        NSData *fileData = [handle readDataOfLength:16 + 8 + 8 + 16]; // 16 header, 8+8 date&reserved, 16 for Name
        [handle closeFile];
        if (fileData.length < 32 + 16) {
            return nil;  // Invalid file - too short.
        }
        NSData *nameData = [NSData dataWithBytes:((unsigned char *)[fileData bytes] + 32) length:16];
        NSString *name = [[NSString alloc] initWithData:nameData encoding:NSASCIIStringEncoding];
        if (!name || [name length] != 16 || ![self isAllDigits:name]) {
            return nil; // Invalid file (name should be an all-digit date stamp), or name content.
        }
        return name;
    }
    return nil; // file does not exist
}

+(void) renamePreviousLogFile {
    NSString *presentLogPath = [self presentLogFilePath];

    NSString *name = [self getLogNameFromFilePath:presentLogPath];
    if (!name) {
        // Invalid file (name should be an all-digit date stamp), or name content  Let's just delete it.
        [self deletePreviousFile];
        return;
    }
    
    NSString *filename = [NSString stringWithFormat:@"seclog.%@.bin", name];
    NSString *newPath = [[self getLogFolderPath] stringByAppendingPathComponent:filename];
    
    BOOL success = FALSE;
    NSUInteger tryCount = 0;
    while (!success && tryCount < ATTEMPTS_TO_CLOSE) {
        success = [[NSFileManager defaultManager] moveItemAtPath:presentLogPath
                                                          toPath:newPath
                                                           error:nil];
        if (!success) {
            // To let the file be closed by another queue.
            [NSThread sleepForTimeInterval:WAIT_INTERVAL_FOR_ATTEMPTS_TO_CLOSE];
        }
        tryCount++;
    }
    if (!success && tryCount == ATTEMPTS_TO_CLOSE) {
        NSLog(@"SLPFolder - unable to renamePreviousLogFile after %d attempts to close", ATTEMPTS_TO_CLOSE);
    }
}

+(NSUInteger) getLogFileByteSize:(NSString *)filePath {
    return [[[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil] fileSize];
}

+(void) cleanOutLogsAndKeychainEntriesKeeping:(NSUInteger)logFilesToKeep
                          maxTotalLogSizeInMB:(NSUInteger)maxLogSize {
    NSString *logFolder = [self getLogFolderPath];

    // Get all keychain entries available
    NSMutableDictionary<NSString *, NSData * > *allKeychainEntriesUnaccountedFor = [NSMutableDictionary dictionaryWithDictionary:[SLPKeychain getAllKeychainItems]];

    NSArray<NSString *> *fullDirectoryListing = [[NSFileManager defaultManager]
                                     contentsOfDirectoryAtPath:logFolder error:nil];
    NSMutableArray<NSString *> *logFileNamesUnaccountedFor = [NSMutableArray
                             arrayWithArray:[[fullDirectoryListing filteredArrayUsingPredicate:
                                              [NSCompoundPredicate andPredicateWithSubpredicates:@[
        [NSPredicate predicateWithFormat:@"SELF beginswith[c] 'seclog.'"],
        [NSPredicate predicateWithFormat:@"SELF  endswith[c]  '.bin'"]
    ]]] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)]];
    
    if ([logFileNamesUnaccountedFor count] >= 1) {
        NSUInteger keptTotalSize = 0;
        NSUInteger totalLogsFiles = 0;
        NSUInteger skippedFiles = 0;
        
        do  {
            NSString *logFileName = [logFileNamesUnaccountedFor
                                     objectAtIndex:[logFileNamesUnaccountedFor count] - 1 - skippedFiles];
            NSString *logName = [self getLogNameFromFilePath:
                                 [logFolder stringByAppendingPathComponent:logFileName]];
            if (logName && allKeychainEntriesUnaccountedFor[logName]) {
                keptTotalSize += [self getLogFileByteSize:logName];
                totalLogsFiles += 1;
                [logFileNamesUnaccountedFor removeLastObject];
                [allKeychainEntriesUnaccountedFor removeObjectForKey:logName];
            } else {
                skippedFiles += 1;
            }
        } while ([logFileNamesUnaccountedFor count] > skippedFiles &&
                 keptTotalSize <= (maxLogSize * 1024 * 1024) &&
                 totalLogsFiles < logFilesToKeep);
    }
                                    
    // If not claimed - remove the log file and its keys from the keychain
    NSArray<NSString *> *filesToRemove = [NSArray arrayWithArray:logFileNamesUnaccountedFor];
    for (NSString *fileName in filesToRemove) {
        [[NSFileManager defaultManager] removeItemAtPath:[logFolder stringByAppendingPathComponent:fileName]
                                                   error:nil];
    }
    NSArray<NSString *> *keysToRemove = [allKeychainEntriesUnaccountedFor allKeys];
    for (NSString *keyId in keysToRemove) {
        [SLPKeychain keychainDeleteDataWithIdentifier:keyId];
    }
}


@end
