//
//  ImageConverter.m
//  annotium_native
//
//  Created by Hoang Le on 12/26/20.
//

#import "ImageConverter.h"

const int RGBA_PIXEL_SIZE = 4;
const int BITS_PER_COMPONENT = 8;
const int BITS_PER_PIXEL = 32;

@implementation ImageConverter

+(UIImage*) convertFromRGBData:(NSData* _Nonnull)rgbData
                         width:(int) width
                        height:(int) height
{
    CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
    if(colorSpaceRef == NULL) {
        return nil;
    }
        
    size_t bufferLength = width * height * RGBA_PIXEL_SIZE;
    size_t bytesPerRow = RGBA_PIXEL_SIZE * width;
    
    CGDataProviderRef provider = CGDataProviderCreateWithData(
                                                              NULL,
                                                              rgbData.bytes,
                                                              bufferLength,
                                                              NULL);
    
    CGImageRef imageRef = CGImageCreate(width,
                                        height,
                                        BITS_PER_COMPONENT,
                                        BITS_PER_PIXEL,
                                        bytesPerRow,
                                        colorSpaceRef,
                                        kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedLast,
                                        provider,    // data provider
                                        NULL,        // decode
                                        YES,         // should interpolate
                                        kCGRenderingIntentDefault);
    
    CGRect bounds = CGRectMake(0.0, 0.0, width, height);
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(width, height), false, 1);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGAffineTransform flipVertical = CGAffineTransformMake(1, 0, 0, -1, 0, height);
    CGContextConcatCTM(context, flipVertical);
    CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
    CGContextDrawImage(context, bounds, imageRef);

    CGImageRef newImageRef = CGBitmapContextCreateImage(context);
    UIImage *image = [UIImage imageWithCGImage:newImageRef];
    CGImageRelease(newImageRef);
    UIGraphicsEndImageContext();
    
    CGColorSpaceRelease(colorSpaceRef);
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    
    return image;
}

+(NSData *) convertUIImageToRGBData:(UIImage*) image
{
    CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
    if(colorSpaceRef == NULL) {
        return nil;
    }
    
    CGSize size = image.size;
    int width = size.width;
    int height = size.height;
    NSUInteger bytesPerPixel = 4;
    NSUInteger bytesPerRow = bytesPerPixel * width;
    NSUInteger bitsPerComponent = 8;
    
    long dataSize = width * height * 4;
    unsigned char *rawData = (unsigned char*) calloc(dataSize, sizeof(unsigned char));

    CGContextRef context = CGBitmapContextCreate(rawData,
                                                 width,
                                                 height,
                                                 bitsPerComponent,
                                                 bytesPerRow,
                                                 colorSpaceRef,
                                                 kCGImageAlphaPremultipliedLast);
    CGColorSpaceRelease(colorSpaceRef);
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), image.CGImage);
    CGContextRelease(context);

    NSData* data = [NSData dataWithBytes:rawData length:dataSize];
    free(rawData);

    return data;
}

@end
