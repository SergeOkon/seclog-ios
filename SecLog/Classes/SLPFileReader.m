@import Foundation;

#import "SLPUtils.h"
#import "SLPConstants.h"
#import "SLPFileReader.h"

@implementation SLPFileReader

+ (SLPInProgressFileHeader *) getFileHeader:(NSString *)path
                               keepFileOpen:(BOOL)keepFileOpen
{
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        SLPInProgressFileHeader *result = [[SLPInProgressFileHeader alloc] init];
        result.openFileHandle = [NSFileHandle fileHandleForReadingAtPath:path];
        
        // length is: 16 header, 8+8 date&reserved, 16 for Name, 16 for ivs
        const NSUInteger headerLength = 16 + 8 + 8 + 16 + 16;
        NSData *headerData = [result.openFileHandle readDataOfLength:headerLength];
        if (!headerData || [headerData length] != headerLength) {
            [result.openFileHandle closeFile];
             return nil;  // Invalid file - too short.
        }
        
        unsigned char const *headerBytes = [headerData bytes];
        result.signature = [SLPUtils stringFromHeaderBytes:(void *)(headerBytes + 0) length:16];
        if (!result.signature || ![result.signature isEqualToString:SLP_INPROGRESS_FILE_SIGNATURE_V1]) {
            [result.openFileHandle closeFile];
             return nil;  // Invalid file - wrong signature
        }
        
        /*
         @property (nonatomic) NSDate    *dateOfCreation;
         @property (nonatomic) NSData    *reserved;
         @property (nonatomic) NSString  *logName;
         @property (nonatomic) NSData    *ivs;
        */
        
        long long dateOfCreationInt64 = *((long long *)(headerBytes + 16)); // byte size: 8
        result.dateOfCreation = [[NSDate alloc] initWithTimeIntervalSince1970:((NSTimeInterval)dateOfCreationInt64 / 1000.0)];
        result.reserved = [NSData dataWithBytes:(void *)(headerBytes + 24) length:8];
        result.logName = [SLPUtils stringFromHeaderBytes:(void *)(headerBytes + 32) length:16];
        if (!result.logName || [result.logName length] != 16 || ![SLPUtils isAllDigits:result.logName]) {
            [result.openFileHandle closeFile];
            return nil; // Invalid file (name should be an all-digit date stamp), or name content.
        }
        
        result.ivs = [NSData dataWithBytes:(void *)(headerBytes + 48) length:16];
        
        if (!keepFileOpen) {
            [result.openFileHandle closeFile];
            result.openFileHandle = nil;
        }
        
        return result;
    }
    return nil; // file does not exist
}


@end
