#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SLPFolder : NSObject

+ (NSString *) getLogFolderPath;
+ (void) confirmOrCreateLogFolder;
+ (NSString *) presentLogFilePath;

+(void) renamePreviousLogFile;

@end

NS_ASSUME_NONNULL_END
