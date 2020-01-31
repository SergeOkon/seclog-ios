@import Foundation;
@import CommonCrypto;

#import "SLPBlockCrypto.h"


@interface SLPBlockCrypto()

@property (nonatomic) CCCryptorRef ref;

@end

@implementation SLPBlockCrypto

-(instancetype)initEncryptorWithKey:(NSData *)key
                                ivs:(NSData *)ivs
{
    self = [super init];
    if (self) {
        CCCryptorStatus status = CCCryptorCreate(
            kCCEncrypt, kCCAlgorithmAES, 0,
            [key bytes], [key length], [ivs bytes],
            &_ref);
        if (status != kCCSuccess) {
            NSLog(@"SLPBlockCrypto: Unable to initEncryptorWithKey - CCCryptorStatus: %d", status);
            return nil;
        }
    }
    return self;
}

-(instancetype)initDecryptorWithKey:(NSData *)key
                                ivs:(NSData *)ivs
{
    self = [super init];
    if (self) {
        CCCryptorStatus status = CCCryptorCreate(
            kCCDecrypt, kCCAlgorithmAES, 0,
            [key bytes], [key length], [ivs bytes],
            &_ref);
        if (status != kCCSuccess) {
            NSLog(@"SLPBlockCrypto: Unable to initDecryptorWithKey - CCCryptorStatus: %d", status);
            return nil;
        }
    }
    return self;
}

-(NSData *) updateBlock:(NSData *)plaintext {
    if ([plaintext length] % 16 != 0) {
        NSLog(@"SLPBlockCrypto: 16b blocks only, please.");
        return nil;
    }
    
    size_t dataOutAvailable = [plaintext length] + 16;
    size_t dataOutProduced = 0;
    void *dataOut = malloc(dataOutAvailable);
    
    CCCryptorStatus status = CCCryptorUpdate(self.ref,
                                             [plaintext bytes], [plaintext length],
                                             dataOut, dataOutAvailable, &dataOutProduced);
    if (status != kCCSuccess) {
        NSLog(@"SLPBlockCrypto: Unable to encrypt - CCCryptorStatus: %d", status);
        return nil;
    }
    return [NSData dataWithBytesNoCopy:dataOut
                                length:dataOutProduced
                          freeWhenDone:YES];
}

-(NSData *) encryptBlock:(NSData *)plaintext  { return [self updateBlock:plaintext];  }
-(NSData *) decryptBlock:(NSData *)ciphertext { return [self updateBlock:ciphertext]; }

-(void) dealloc {
    CCCryptorRelease(self.ref);
}


@end
