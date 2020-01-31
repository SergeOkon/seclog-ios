@import Foundation;

NS_ASSUME_NONNULL_BEGIN

// ---------------------------------------------------------------------
// Constants
extern NSString* const SLP_INPROGRESS_FILE_SIGNATURE_V1;

extern NSString* const SECURE_LOG_FOLDER_NAME;
extern NSString* const SECURE_LOG_PRESENT_NAME;

extern int const ATTEMPTS_TO_CLOSE;
extern NSTimeInterval const WAIT_INTERVAL_FOR_ATTEMPTS_TO_CLOSE;

// ---------------------------------------------------------------------
// Current Log file

/*
Current Log File Header
 @00h - 16 bytes - signature "SecureLoggerIPv1"
 @10h - 8 bytes  - date of creation
 @10h - 8 bytes  - reserved - keep zeros for now
 @20h - 16 bytes - 128-bit Log Name - numeric, date-based (also the key-ID - look it up in keychain)
 @30h - 16 bytes - 128-bit IV for AES (in plain text)
 @40h - 16 bytes * n - blocks start here.
*/

@interface SLPInProgressFileHeader : NSObject
@property (nonatomic) NSString  *signature;
@property (nonatomic) NSDate    *dateOfCreation;
@property (nonatomic) NSData    *reserved;
@property (nonatomic) NSString  *logName;
@property (nonatomic) NSData    *ivs;
@property (nonatomic) NSFileHandle * _Nullable openFileHandle;
@end


// ---------------------------------------------------------------------
// Packed Log file

/*
Packed Log File Header
 @00h - 16 bytes - signature "SecureLoggerPKv1"
 @10h - 32 bytes - Public Key Of Receiver, for reference.
 @30h - 32 bytes - Public Key Of Sender (generatd by createLogPackage, needed by the receiver)
 @50h - zlib'ed file blocks, encrypted with shared secret.
*/

@interface SLPPackedFileHeader : NSObject
@property (nonatomic) NSString  *signature;
@property (nonatomic) NSData    *receivedPublicKey;
@property (nonatomic) NSData    *senderPublicKey;
@property (nonatomic) NSFileHandle * _Nullable openFileHandle;
@end

/*
 Log File Package - block
  @00h - 4 bytes - signature "Bloc"
  @04h - 4 bytes - block counter - starting with 0
  @08h - 4 bytes - data size (minus this header)
  @10h - 8 bytes - references date - (date of creation for that block)
  @18h - data - (of "data size" bytes)
 */

@interface SLPPackedFileBlockHeader : NSObject
@property (nonatomic) NSString   *signature;
@property (nonatomic) NSUInteger  blockCounter;
@property (nonatomic) NSDate     *referenceDate;
@end

NS_ASSUME_NONNULL_END
