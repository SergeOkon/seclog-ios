@import Foundation;

#import "SLPUtils.h"

@implementation SLPUtils

+ (NSData *) stringToHeaderData:(NSString *)string {
    if (!string) return nil;
    return [string dataUsingEncoding:NSASCIIStringEncoding];
}

+ (NSString *) stringFromHeaderData:(NSData *)data {
    if (!data) return nil;
    return [[NSString alloc] initWithData:data
                                 encoding:NSASCIIStringEncoding];
}

+ (NSString *)stringFromHeaderBytes:(void *)bytes
                             length:(NSUInteger)length {
    if (!bytes || length == 0) return nil;
    return [[NSString alloc] initWithBytes:bytes length: length encoding:NSASCIIStringEncoding];
}

+ (NSUInteger) getFileSizeInBytes:(NSString *)filePath
{
    return [[[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil] fileSize];
}

// https://stackoverflow.com/questions/6644004
+ (BOOL) isAllDigits:(NSString *)string
{
    NSCharacterSet* nonNumbers = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
    NSRange r = [string rangeOfCharacterFromSet: nonNumbers];
    return r.location == NSNotFound && string.length > 0;
}

@end
