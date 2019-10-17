#import "SLPFolder.h"

NSString* SECURE_LOG_FOLDER_NAME = @"SecureLog";
NSString* SECURE_LOG_PRESENT_NAME = @"seclog.present.bin";


@implementation SLPFolder

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

@end
