@import Foundation;

#import "SLPConstants.h"

NS_ASSUME_NONNULL_BEGIN

@interface SLPFileReader : NSObject

+ (SLPInProgressFileHeader * _Nullable) getFileHeader:(NSString *)path
                                         keepFileOpen:(BOOL)keepFileOpen;

@end

NS_ASSUME_NONNULL_END
