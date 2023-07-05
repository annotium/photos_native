//
//  PHAlbum.m
//  Runner
//
//  Created by Hoang Le on 10/30/20.
//  Copyright © 2020 The Chromium Authors. All rights reserved.
//

#import "PHImageDescription.h"
#import "Constants.h"

@implementation PHImageDescription

+ (instancetype) imageWithWidth:(int) width height:(int) height data:(NSData* _Nonnull) data;
{
    return [[self alloc] initWithWidth:width height:height data:data];
}

- (instancetype) initWithWidth:(int) width height:(int) height data:(NSData* _Nonnull) data
{
    self = [super init];
    if (self) {
        _width = width;
        _height = height;
        _data = data;
    }
    
    return self;
}

- (NSDictionary*) toMessageCodec
{
    return @{
        KEY_WIDTH: [NSNumber numberWithInt:_width],
        KEY_HEIGHT: [NSNumber numberWithInt:_height],
        KEY_DATA: _data
    };
}

@end
