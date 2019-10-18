#import "SLPFolder.h"

NSString* SECURE_LOG_FOLDER_NAME = @"SecureLog";
NSString* SECURE_LOG_PRESENT_NAME = @"seclog.present.bin";


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

+(void) renamePreviousLogFile {
    NSString *presentLogPath = [self presentLogFilePath];
    if ([[NSFileManager defaultManager] fileExistsAtPath:presentLogPath]) {
        NSFileHandle *handle = [NSFileHandle fileHandleForReadingAtPath:presentLogPath];
        NSData *fileData = [handle readDataOfLength:16 + 8 + 8 + 16]; // 16 header, 8+8 date&reserved, 16 for Name
        [handle closeFile];
        if (fileData.length < 32 + 16) {
            // Invalid file - too short. Let's just delete it.
            [self deletePreviousFile];
            return;
        }
        
        NSData *nameData = [NSData dataWithBytes:((unsigned char *)[fileData bytes] + 32) length:16];
        NSString *name = [[NSString alloc] initWithData:nameData encoding:NSASCIIStringEncoding];
        if ([name length] != 16 || ![self isAllDigits:name]) {
            // Invalid file - name should be an all-digit date stamp. Let's just delete it.
            [self deletePreviousFile];
            return;
        }
        
        NSString *filename = [NSString stringWithFormat:@"seclog.%@.bin", name];
        NSString *newPath = [[self getLogFolderPath] stringByAppendingPathComponent:filename];
        
        BOOL success = FALSE;
        NSUInteger tryCount = 0;
        while (!success && tryCount < 5) {
            success = [[NSFileManager defaultManager] moveItemAtPath:presentLogPath toPath:newPath error:nil];
            if (!success) {
                [NSThread sleepForTimeInterval: 0.1]; // To let the file be closed by another queue.
            }
            tryCount++;
        }
        if (!success && tryCount == 5) {
            NSLog(@"SLPFolder - unable to renamePreviousLogFile");
        }
    }
}




@end
