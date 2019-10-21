#import <Foundation/Foundation.h>


NS_ASSUME_NONNULL_BEGIN

@interface SLPKeychain : NSObject

+ (NSData *)randomDataGenerateSecure:(size_t)length;

+ (void) keychainDeleteDataWithIdentifier:(NSString *)identifier;
+ (BOOL) keychainStoreData:(NSData *)data
         withIdentifier:(NSString *)identifier;
+ (NSData * _Nullable)keychainGetDataWithIdentifier:(NSString *)identifier;

+ (NSDictionary *)getAllKeychainItems;

@end

NS_ASSUME_NONNULL_END
