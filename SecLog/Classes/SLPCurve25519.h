#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SLPCurve25519 : NSObject

+(NSData *)generatePrivateKey;

+(NSData *)publicKeyGivenPrivateKey:(NSData *)privateKey;

+(NSData *)makeSharedSecretWithMyPrivateKey:(NSData *)privateKey
                          andTheirPublicKey:(NSData *)publicKey;

@end

NS_ASSUME_NONNULL_END
