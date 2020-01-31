#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^SLPCreateLogReturnBlock)(NSData * _Nullable);

@interface SLPSecurePackage : NSObject

-(instancetype) initInMemoryPackageWithPrivateKey:(NSData *)privateKey
                               receiverPublicKeys:(NSArray <NSData *> *)publicKeys
                                      preCompress:(BOOL)useCompression;


@end

NS_ASSUME_NONNULL_END
