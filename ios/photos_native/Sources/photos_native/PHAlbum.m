//
//  PHAlbum.m
//  Runner
//
//  Created by Hoang Le on 10/30/20.
//  Copyright © 2020 The Chromium Authors. All rights reserved.
//

#import "PHAlbum.h"
#import "Constants.h"

@implementation PHAlbum

+ (instancetype) albumWithId:(NSString* _Nonnull) identifier title:(NSString*) title
{
    return [[self alloc] initWithIdentifier:identifier title:title];
}

- (instancetype) initWithIdentifier:(NSString* _Nonnull)identifier
                        title:(NSString *)title
{
    self = [super init];
    if (self) {
        _identifier = identifier;
        _title = title;
        _items = [NSMutableArray array];
    }
    
    return self;
}

- (NSDictionary*) toMessageCodec
{
    return @{
        KEY_ID: _identifier,
        KEY_TITLE: _title,
        KEY_ITEMS: _items
    };
}

- (void) addPhoto:(NSString* _Nonnull) photoId
{
    [_items addObject:photoId];
}

@end
