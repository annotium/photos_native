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

+(NSData*) convertUIImageToRGBData:(UIImage*) orgImage
{
    UIImage* image = [ImageConverter scaleAndRotateImage: orgImage];
    if (image == nil) {
        return nil;
    }
    
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

+(UIImage*) scaleAndRotateImage:(UIImage *)image{
    // No-op if the orientation is already correct
    if (image.imageOrientation == UIImageOrientationUp) {
        return image;
    }

    // We need to calculate the proper transformation to make the image upright.
    // We do it in 2 steps: Rotate if Left/Right/Down, and then flip if Mirrored.
    CGAffineTransform transform = CGAffineTransformIdentity;

    switch (image.imageOrientation) {
        case UIImageOrientationDown:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, image.size.width, image.size.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;

        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
            transform = CGAffineTransformTranslate(transform, image.size.width, 0);
            transform = CGAffineTransformRotate(transform, M_PI_2);
            break;

        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, 0, image.size.height);
            transform = CGAffineTransformRotate(transform, -M_PI_2);
            break;
        case UIImageOrientationUp:
        case UIImageOrientationUpMirrored:
            break;
    }

    switch (image.imageOrientation) {
        case UIImageOrientationUpMirrored:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, image.size.width, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;

        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, image.size.height, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
        case UIImageOrientationUp:
        case UIImageOrientationDown:
        case UIImageOrientationLeft:
        case UIImageOrientationRight:
            break;
    }

    // Now we draw the underlying CGImage into a new context, applying the transform
    // calculated above.
    CGContextRef ctx = CGBitmapContextCreate(NULL, image.size.width, image.size.height,
                                             CGImageGetBitsPerComponent(image.CGImage), 0,
                                             CGImageGetColorSpace(image.CGImage),
                                             CGImageGetBitmapInfo(image.CGImage));
    CGContextConcatCTM(ctx, transform);
    switch (image.imageOrientation) {
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            // Grr...
            CGContextDrawImage(ctx, CGRectMake(0,0,image.size.height,image.size.width), image.CGImage);
            break;

        default:
            CGContextDrawImage(ctx, CGRectMake(0,0,image.size.width,image.size.height), image.CGImage);
            break;
    }

    // And now we just create a new UIImage from the drawing context
    CGImageRef cgimg = CGBitmapContextCreateImage(ctx);
    UIImage *img = [UIImage imageWithCGImage:cgimg];
    CGContextRelease(ctx);
    CGImageRelease(cgimg);
    
    return img;
}

@end
