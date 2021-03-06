@import Foundation;

#import "SLPKeychain.h"
#import "SLPCurve25519.h"

static const uint8_t basepoint[32] = { 9 };

extern void curve25519_donna(uint8_t *mypublic, const uint8_t *secret, const uint8_t *basepoint);

@implementation SLPCurve25519

+(NSMutableData *)generatePrivateKey {
    NSMutableData *privateKey = [NSMutableData dataWithData:[SLPKeychain randomDataGenerateSecure:32]];
    uint8_t *privKeyBytes = [privateKey mutableBytes];
    privKeyBytes[0]  &= 248;
    privKeyBytes[31] &= 127;
    privKeyBytes[31] |= 64;
    return privateKey;
}

+(NSMutableData *)publicKeyGivenPrivateKey:(NSData *)privateKey {
    NSMutableData *publicKey = [[NSMutableData alloc] initWithLength:32];
    curve25519_donna([publicKey mutableBytes], [privateKey bytes], basepoint);
    return publicKey;
}

+(NSMutableData *)makeSharedSecretWithMyPrivateKey:(NSData *)privateKey
                                 andTheirPublicKey:(NSData *)publicKey {
    NSMutableData *sharedSecret = [[NSMutableData alloc] initWithLength:32];
    curve25519_donna([sharedSecret mutableBytes], [privateKey bytes], [publicKey bytes]);
    return sharedSecret;
}

@end
