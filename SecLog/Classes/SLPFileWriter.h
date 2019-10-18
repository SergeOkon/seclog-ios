#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SLPFileWriter : NSObject

@property (nonatomic, readonly) NSUInteger totalLogged;
@property (nonatomic, readonly) NSUInteger nLoggedText;
@property (nonatomic, readonly) NSUInteger nLoggedGeneralData;
@property (nonatomic, readonly) NSUInteger nLoggedImages;

-(void)logText:(NSString *)text
      logLevel:(unsigned char)logLevel;

-(void)logGenericData:(NSData *)text
             logLevel:(unsigned char)logLevel;

-(void)logImageData:(NSData *)text
           logLevel:(unsigned char)logLevel;

@end

NS_ASSUME_NONNULL_END
