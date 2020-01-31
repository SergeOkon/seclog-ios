@import Foundation;

#import "SLPConstants.h"
#import "SLPKeychain.h"
#import "SLPUtils.h"
#import "SLPFileReader.h"

#import "SLPFolder.h"


@implementation SLPFolder


+(NSString *) getLogFolderPath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    NSString *libraryFolder = [paths objectAtIndex:0]; // Get documents folder
    NSString *logPath = [libraryFolder stringByAppendingPathComponent:SECURE_LOG_FOLDER_NAME];
    return logPath;
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

+(void) renamePreviousLogFile {
    NSString *presentLogPath = [self presentLogFilePath];

    SLPInProgressFileHeader *fileHeader = [SLPFileReader getFileHeader:presentLogPath
                                                          keepFileOpen:NO];
    if (!fileHeader) {
        // invalid File
        [self deletePreviousFile];
        return;
    }
    
    NSString *filename = [NSString stringWithFormat:@"seclog.%@.bin", fileHeader.logName];
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

+(NSArray<NSString *> *) getSortedLogFileList {
    NSString *logFolder = [self getLogFolderPath];
    NSArray<NSString *> *fullDirectoryListing = [[NSFileManager defaultManager]
                                     contentsOfDirectoryAtPath:logFolder error:nil];
    NSArray<NSString *> *result = [[fullDirectoryListing filteredArrayUsingPredicate:
                                              [NSCompoundPredicate andPredicateWithSubpredicates:@[
        [NSPredicate predicateWithFormat:@"SELF beginswith[c] 'seclog.'"],
        [NSPredicate predicateWithFormat:@"SELF  endswith[c]  '.bin'"]
    ]]] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    return result;
}

+(void) cleanOutLogsAndKeychainEntriesKeeping:(NSUInteger)logFilesToKeep
                          maxTotalLogSizeInMB:(NSUInteger)maxLogSize {
    NSString *logFolder = [self getLogFolderPath];

    // Get all keychain entries available
    NSMutableDictionary<NSString *, NSData * > *allKeychainEntriesUnaccountedFor = [NSMutableDictionary dictionaryWithDictionary:[SLPKeychain getAllKeychainItems]];

    NSMutableArray<NSString *> *logFileNamesUnaccountedFor =
        [NSMutableArray arrayWithArray:[self getSortedLogFileList]];
    
    if ([logFileNamesUnaccountedFor count] >= 1) {
        NSUInteger keptTotalSize = 0;
        NSUInteger totalLogsFiles = 0;
        NSUInteger skippedFiles = 0;
        
        do  {
            NSString *logFileName = [logFileNamesUnaccountedFor
                                     objectAtIndex:[logFileNamesUnaccountedFor count] - 1 - skippedFiles];
            SLPInProgressFileHeader *fileHeader = [SLPFileReader getFileHeader:logFileName
                                                                  keepFileOpen:NO];
            
            if (fileHeader && allKeychainEntriesUnaccountedFor[fileHeader.logName]) {
                keptTotalSize += [SLPUtils getFileSizeInBytes:logFileName];
                totalLogsFiles += 1;
                [logFileNamesUnaccountedFor removeLastObject];
                [allKeychainEntriesUnaccountedFor removeObjectForKey:fileHeader.logName];
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
