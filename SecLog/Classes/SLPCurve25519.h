#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SLPCurve25519 : NSObject

+(NSMutableData *)generatePrivateKey;

+(NSMutableData *)publicKeyGivenPrivateKey:(NSData *)privateKey;

+(NSMutableData *)makeSharedSecretWithMyPrivateKey:(NSData *)privateKey
                          andTheirPublicKey:(NSData *)publicKey;

@end

NS_ASSUME_NONNULL_END
