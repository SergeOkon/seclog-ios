@import Foundation;

#import "SLPFrame.h"

typedef enum {
    SECLOG_FRAME_NONE = 0,
    SECLOG_FRAME_TEXT = 10,
    SECLOG_FRAME_DATA_GENERIC = 20,
    SECLOG_FRAME_DATA_IMAGE = 21,
} SecLogFrameType;


@implementation SLPFrame

/* Frame format:
   @00h - 1 byte  - Loglevel
   @01h - 1 byte  - SecLogFrameType
   @02h - 4 bytes - date of entry (date of holding file + this value = ms)
   @08h - 4 bytes - size of following data or text.
   @0Ah - data - padded to total frame size %16 == 0.
 */

+ (NSMutableData *)allocateFrameWithDataSize:(size_t)dataLength
{
    // Calc needed frame size, padded to 16-bytes
    size_t headerLength = 10;
    size_t totalFrameBlocks = (headerLength + dataLength + 15) / 16; // round up to 16
    size_t totalFrameLength = totalFrameBlocks * 16;
    return [[NSMutableData alloc] initWithLength:totalFrameLength];
}

+ (void)writeHeaderTo:(NSMutableData *)frame
             logLevel:(unsigned char)logLevel
                 type:(unsigned char)type
               length:(size_t)length
                   on:(NSTimeInterval)timeInverval
{
    unsigned long dateULongLong = (unsigned long) (timeInverval * 1000);
    [frame replaceBytesInRange:NSMakeRange(0x00, 1) withBytes:&logLevel];
    [frame replaceBytesInRange:NSMakeRange(0x01, 1) withBytes:&type];
    [frame replaceBytesInRange:NSMakeRange(0x02, 4) withBytes:&dateULongLong];
    [frame replaceBytesInRange:NSMakeRange(0x08, 4) withBytes:&length];
}

+ (void)writeDataTo:(NSMutableData *)frame
               data:(NSData *) data
{
    [frame replaceBytesInRange:NSMakeRange(0x0C, [data length]) withBytes:[data bytes]];
}

+(NSData *) genericFrameOfLogLevel:(unsigned char)logLevel
                type:(unsigned char)type
                data:(NSData *)data
                 on:(NSTimeInterval)timeInverval
{
    NSMutableData *frame = [self allocateFrameWithDataSize:[data length]];
    [self writeHeaderTo:frame
               logLevel:logLevel
                   type:type
                 length:[data length]
                     on:timeInverval];
    [frame replaceBytesInRange:NSMakeRange(0x0A, [data length])
                     withBytes:[data bytes]];
    return [NSData dataWithData:frame];
}
    
+(NSData *) frameWithText:(NSString *)text
                 logLevel:(unsigned char)logLevel
                       on:(NSTimeInterval)timeInverval
{
    NSData *strAsData = [text dataUsingEncoding:NSUTF8StringEncoding];
    return [self genericFrameOfLogLevel:logLevel
                                   type:SECLOG_FRAME_TEXT
                                   data:strAsData
                                     on:timeInverval];
}

+(NSData *) frameWithGenericData:(NSData *)genericData
                              on:(NSTimeInterval)timeInverval
                        logLevel:(unsigned char)logLevel {
    return [self genericFrameOfLogLevel:logLevel
                                   type:SECLOG_FRAME_DATA_GENERIC
                                   data:genericData
                                     on:timeInverval];
}

+(NSData *) frameWithImageData:(NSData *)imageData
                            on:(NSTimeInterval)timeInverval
                      logLevel:(unsigned char)logLevel {
    return [self genericFrameOfLogLevel:logLevel
                                   type:SECLOG_FRAME_DATA_IMAGE
                                   data:imageData
                                     on:timeInverval];
}

@end
