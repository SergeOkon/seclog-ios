#import "SLPKeychain.h"
#import <Security/Security.h>

@implementation SLPKeychain

const long keySize = 32;

+ (NSData *)randomDataGenerateSecure:(size_t)length {
    // https://developer.apple.com/documentation/security/1399291-secrandomcopybytes?language=objc
    SInt8 bytes[length];
    return SecRandomCopyBytes(kSecRandomDefault, length, &bytes) == noErr ?
        [[NSData alloc] initWithBytes:bytes length:length] :
        nil;
}

+ (NSString *) makeKeychainIdentifierForLogFileKey:(NSString *)logId {
    return [NSString stringWithFormat:@"seclog-%@", logId];
}

+ (void) keychainDeleteDataWithIdentifier: (NSString *)identifier {
    if (!identifier || [identifier length] == 0) return;
    NSDictionary *query = @{ (id)kSecAttrGeneric: identifier,
                             (id)kSecClass: (id)kSecClassGenericPassword };
    SecItemDelete((CFDictionaryRef)query); // OK to ignore status here
}

+ (BOOL) keychainStoreData:(NSData *)data
            withIdentifier:(NSString *)identifier
{
    if (!data || [data length] == 0 || !identifier || [identifier length] == 0) return FALSE;
    NSDictionary *query = @{ (id)kSecAttrGeneric: identifier,
                             (id)kSecClass: (id)kSecClassGenericPassword };
    
    NSMutableDictionary *item = [NSMutableDictionary dictionaryWithDictionary:query];
    [item setObject:data forKey:(id)kSecValueData];
    OSStatus status = SecItemAdd((CFDictionaryRef)item, NULL);
    if(status == errSecDuplicateItem) {
        status = SecItemUpdate((CFDictionaryRef)query, (CFDictionaryRef)item);
    }
    return status == noErr;
}

+ (NSData *)keychainGetDataWithIdentifier:(NSString *)identifier
{
    if (!identifier || [identifier length] == 0) return nil;
    NSDictionary *query = @{ (id)kSecAttrGeneric: identifier,
                             (id)kSecClass: (id)kSecClassGenericPassword,
                             (id)kSecReturnData: (id)kCFBooleanTrue,
                             (id)kSecMatchLimit: (id)kSecMatchLimitOne };
    CFTypeRef data = NULL;
    OSStatus status = SecItemCopyMatching((CFDictionaryRef)query,  (CFTypeRef *)&data);
    if (status == noErr && data) {
        return (__bridge NSData *)data;
    }
    return nil;
}

@end
