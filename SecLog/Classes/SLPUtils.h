#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SLPUtils : NSObject

// File Utils

+ (NSUInteger) getFileSizeInBytes:(NSString *)filePath;

// String Utils
+ (NSData *)   stringToHeaderData:(NSString *)string;
+ (NSString *) stringFromHeaderData:(NSData *)data;
+ (NSString *) stringFromHeaderBytes:(void *)bytes length:(NSUInteger)length;

+ (BOOL) isAllDigits:(NSString *)string;

@end

NS_ASSUME_NONNULL_END
