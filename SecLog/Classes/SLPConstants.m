@import Foundation;

#import "SLPConstants.h"

NSString* const SLP_INPROGRESS_FILE_SIGNATURE_V1 =  @"SecureLoggerIPv1";
NSString* const SLP_PACKAGE_FILE_SIGNATURE_V1 =     @"SecurePkgV01"; // Secure Logger, In Progress, V1


NSString* const SECURE_LOG_FOLDER_NAME = @"SecureLog";
NSString* const SECURE_LOG_PRESENT_NAME = @"seclog.present.bin";

const int ATTEMPTS_TO_CLOSE = 10;
NSTimeInterval const WAIT_INTERVAL_FOR_ATTEMPTS_TO_CLOSE = 0.1;

@implementation SLPInProgressFileHeader
@end

@implementation SLPPackedFileHeader
@end

@implementation SLPPackedFileBlockHeader
@end
