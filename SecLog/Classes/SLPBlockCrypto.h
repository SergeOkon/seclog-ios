#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SLPBlockCrypto : NSObject

-(instancetype _Nullable)initEncryptorWithKey:(NSData *)key
                                          ivs:(NSData *)ivs;

-(instancetype _Nullable)initDecryptorWithKey:(NSData *)key
                                          ivs:(NSData *)ivs;

-(NSData * _Nullable) updateBlock:(NSData *)plaintext;
-(NSData * _Nullable) encryptBlock:(NSData *)plaintext;
-(NSData * _Nullable) decryptBlock:(NSData *)ciphertext;

@end

NS_ASSUME_NONNULL_END
