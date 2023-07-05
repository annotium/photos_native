//
//  ImageConverter.h
//  annotium_native
//
//  Created by Hoang Le on 12/26/20.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ImageConverter : NSObject

+(UIImage*) convertFromRGBData:(NSData* _Nonnull)rgbData width:(int) width height:(int) height;
+(NSData*) convertUIImageToRGBData:(UIImage*) image;

@end

NS_ASSUME_NONNULL_END
