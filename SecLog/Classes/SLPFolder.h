#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SLPFolder : NSObject

+(NSString *) getLogFolderPath;
+(void) confirmOrCreateLogFolder;
+(NSString *) presentLogFilePath;
+(void) renamePreviousLogFile;
+(NSArray<NSString *> *) getSortedLogFileList;

+(void) cleanOutLogsAndKeychainEntriesKeeping:(NSUInteger)logFilesToKeep
                          maxTotalLogSizeInMB:(NSUInteger)maxLogSize;
@end

NS_ASSUME_NONNULL_END
