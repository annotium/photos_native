//
//  ImageTexture.h
//  annotium_native
//
//  Created by Hoang Le on 22/04/2022.
//

#import <Foundation/Foundation.h>
#import <Flutter/Flutter.h>

NS_ASSUME_NONNULL_BEGIN

@interface ImageTexture : NSObject <FlutterTexture>

+ (instancetype) initWithImage:(UIImage* _Nonnull)image size:(CGSize)size textures:(NSObject<FlutterTextureRegistry>*) textures;

- (void) performRegister;

@property (nonatomic) int64_t textureId;

@end

NS_ASSUME_NONNULL_END
