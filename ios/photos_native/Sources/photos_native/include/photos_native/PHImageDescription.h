//
//  PHAlbum.h
//  Runner
//
//  Created by Hoang Le on 10/30/20.
//  Copyright © 2020 The Chromium Authors. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface PHImageDescription : NSObject

+ (instancetype) imageWithWidth:(int) width height:(int) height data:(NSData* _Nonnull) data;

@property (nonatomic) int width;
@property (nonatomic) int height;
@property (nonatomic, strong) NSData* data;

- (instancetype) initWithWidth:(int) width height:(int) height data:(NSData* _Nonnull) data;

- (NSDictionary*) toMessageCodec;

@end

NS_ASSUME_NONNULL_END
