//
//  ImageTexture.m
//  annotium_native
//
//  Created by Hoang Le on 22/04/2022.
//

#import "ImageTexture.h"

static uint32_t bitmapInfoWithPixelFormatType(OSType pixelFormat, bool hasAlpha) {
    if (pixelFormat == kCVPixelFormatType_32BGRA) {
        uint32_t bitmapInfo = kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Host;
        if (!hasAlpha) {
            bitmapInfo = kCGImageAlphaNoneSkipFirst | kCGBitmapByteOrder32Host;
        }
        return bitmapInfo;
    }
    else if (pixelFormat == kCVPixelFormatType_32ARGB) {
        return kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Big;
    }
    else{
        return 0;
    }
}

BOOL CGImageRefContainsAlpha(CGImageRef imageRef) {
    if (!imageRef) {
        return NO;
    }
    
    CGImageAlphaInfo alphaInfo = CGImageGetAlphaInfo(imageRef);
    BOOL hasAlpha = !(alphaInfo == kCGImageAlphaNone ||
                      alphaInfo == kCGImageAlphaNoneSkipFirst ||
                      alphaInfo == kCGImageAlphaNoneSkipLast);
    
    return hasAlpha;
}

@interface ImageTexture()

@property (nonatomic, weak) NSObject<FlutterTextureRegistry>* textures;
@property (nonatomic, assign) UIImage* image;
@property (nonatomic) CVPixelBufferRef target;
@property (nonatomic,assign) CGSize size;
@property(nonatomic,assign)Boolean isCopy;

@end

@implementation ImageTexture

+ (instancetype)initWithImage:(UIImage*)image size:(CGSize)size textures:(NSObject<FlutterTextureRegistry>*) textures {
    return [[self alloc] initWithImage:image size:size textures: textures];
}

- (instancetype)initWithImage:(UIImage*)image size:(CGSize)size textures:(NSObject<FlutterTextureRegistry>*) textures {
    self = [super init];
    if (self){
        _textures = textures;
        self.image = image;
        self.size = size;
    }
    
    return self;
}

- (void) performRegister
{
    _target = [self CVPixelBufferRefFromUiImage:_image size:_size];
    _textureId = [_textures registerTexture:self];
}

- (void) dealloc {
    NSLog(@"Release texture '%lld'", _textureId);
    [_textures unregisterTexture:_textureId];
    CVPixelBufferRelease(_target);

}

- (CVPixelBufferRef) copyPixelBuffer {
    return _target;
}

- (CVPixelBufferRef) CVPixelBufferRefFromUiImage:(UIImage *)img size:(CGSize)size {
    if (!img) {
        return nil;
    }
    
    CGImageRef image = [img CGImage];
    CGFloat frameWidth = size.width;
    CGFloat frameHeight = size.height;
    
    if(frameWidth <= 0){
        frameWidth = CGImageGetWidth(image);
    }
    
    if(frameHeight <= 0){
        frameHeight = CGImageGetHeight(image);
    }
    
    BOOL hasAlpha = CGImageRefContainsAlpha(image);
    CFDictionaryRef dict = CFDictionaryCreate(kCFAllocatorDefault, NULL, NULL, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    
    NSDictionary *options = [
                             NSDictionary dictionaryWithObjectsAndKeys:
                         [NSNumber numberWithBool:YES], kCVPixelBufferCGImageCompatibilityKey,
                         [NSNumber numberWithBool:YES], kCVPixelBufferCGBitmapContextCompatibilityKey,
                             dict, kCVPixelBufferIOSurfacePropertiesKey, nil];
    
    CVPixelBufferRef pixelBuffer = NULL;
    
    CVReturn status = CVPixelBufferCreate(
                                          kCFAllocatorDefault,
                                          frameWidth,
                                          frameHeight,
                                          kCVPixelFormatType_32BGRA,
                                          (__bridge CFDictionaryRef) options,
                                          &pixelBuffer);
    
    NSParameterAssert(status == kCVReturnSuccess && pixelBuffer != NULL);
    
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    void *pixelData = CVPixelBufferGetBaseAddress(pixelBuffer);
    
    NSParameterAssert(pixelData != NULL);
    
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    
    uint32_t bitmapInfo = bitmapInfoWithPixelFormatType(kCVPixelFormatType_32BGRA, (bool)hasAlpha);
    
    CGContextRef context = CGBitmapContextCreate(pixelData, frameWidth, frameHeight, 8, CVPixelBufferGetBytesPerRow(pixelBuffer), rgbColorSpace, bitmapInfo);
    
    NSParameterAssert(context);
    
    CGContextConcatCTM(context, CGAffineTransformIdentity);
    CGContextDrawImage(context, CGRectMake(0, 0, frameWidth, frameHeight), image);
    
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);
    
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    
    return pixelBuffer;
}

@end
