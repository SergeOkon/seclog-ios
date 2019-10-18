#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SLPFrame : NSObject


+(NSData *) frameWithText:(NSString *)text
                 logLevel:(unsigned char)logLevel
                       on:(NSTimeInterval)timeInverval;

+(NSData *) frameWithGenericData:(NSData *)genericData
                              on:(NSTimeInterval)timeInverval
                        logLevel:(unsigned char)logLevel;

+(NSData *) frameWithImageData:(NSData *)imageData
                            on:(NSTimeInterval)timeInverval
                      logLevel:(unsigned char)logLevel;

@end

NS_ASSUME_NONNULL_END
