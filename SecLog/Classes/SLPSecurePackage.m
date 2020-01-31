@import Foundation;
@import CommonCrypto;

#import "SLPKeychain.h"
#import "SLPCurve25519.h"

#import "SLPSecurePackage.h"

@interface SLPSecurePackage()

@property (nonatomic) BOOL useCompression;
@property (nonatomic) NSMutableData *output;
@property (nonatomic) NSMutableData *symetricKey;
@property (nonatomic) CCCryptorRef cryptorRef;

@end

@implementation SLPSecurePackage : NSObject

NSString* const SLP_PACKAGE_FILE_SIGNATURE_V1 =     @"SecurePkgV01"; // Secure Logger, In Progress, V1
NSUInteger const MAX_PUBLIC_KEYS = 65535;


-(instancetype) initInMemoryPackageWithPrivateKey:(NSData *)privateKey
                               receiverPublicKeys:(NSArray<NSData *> *)publicKeys
                                      preCompress:(BOOL)useCompression
{
    if (!privateKey || [privateKey length] == 32) return nil;
    if (!publicKeys || [publicKeys count] == 0 || [publicKeys count] > MAX_PUBLIC_KEYS) return nil;
    
    self = [super init];
    if (self) {
        _useCompression = !!_useCompression;
        _symetricKey = [SLPKeychain randomDataGenerateSecure:32];
        _output = [self headerForPrivateKey:privateKey receiverPublicKeys:publicKeys];
        if (!_output) return nil;
        //CCCryptorStatus status = CCCryptorCreate(kCCEncrypt, kCCAlgorithmAES, 0,
        //                                         [sharedSecret bytes], [sharedSecret length], [iv bytes],  &_cryptorRef);
        //if (status != noErr) return nil;
    }
    return self;
}

-(NSMutableData *) headerForPrivateKey:(NSData *)privateKey
                    receiverPublicKeys:(NSArray<NSData *> *)publicKeys
{
    NSMutableData *result = [[NSMutableData alloc] init];
    
    // 16 byte header
    [result appendData:[SLP_PACKAGE_FILE_SIGNATURE_V1 dataUsingEncoding:NSASCIIStringEncoding]];
    const NSUInteger reserved = 0;
    const NSUInteger publicKeyCount = [publicKeys count];
    [result appendBytes:&reserved length: 2];
    [result appendBytes:&publicKeyCount length: 2];
    
    // Keys - { public Key (32b) - IVs (16b) - Symetric Key (32b) } ✕ n_keys
    
    unsigned char scratchSpace[[self.symetricKey length] + 16];
    for (NSData *publicKey in publicKeys) {
        NSMutableData *sharedSecret = [SLPCurve25519 makeSharedSecretWithMyPrivateKey:privateKey
                                                                    andTheirPublicKey:publicKey];
        NSData *iv = [SLPKeychain randomDataGenerateSecure:16];
       
        // Encrypt the Symetric key with the tempoary sharedSecret, and IV using AES-256
        CCCryptorRef ref;
        CCCryptorStatus status = CCCryptorCreate(kCCEncrypt, kCCAlgorithmAES, 0,
                                                 [sharedSecret bytes], [sharedSecret length], [iv bytes],  &ref);
        if (status != noErr) return nil;
        size_t dataOutProduced = 0;
        status = CCCryptorUpdate(ref, [self.symetricKey bytes], [self.symetricKey length],
                                                 &scratchSpace, sizeof(scratchSpace), &dataOutProduced);
        if (status != noErr) return nil;
        CCCryptorRelease(ref);

        // Add these to the resulting header
        [result appendData:publicKey];
        [result appendData:iv];
        [result appendBytes:&scratchSpace length:dataOutProduced];
        
        // Expunge key material
        //[sharedSecret ]
        
    }
    memset(&scratchSpace, 0, sizeof(scratchSpace));
    return result;
}

-(void) dealloc {
    //[self.symetricKey reset
   /* if (self.cryptorRef) {
        CCCryptorRelease(self.cryptorRef);
    }*/
   // _cryptorRef = nil
     
}


@end
 
