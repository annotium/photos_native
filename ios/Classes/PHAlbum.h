//
//  PHAlbum.h
//  Runner
//
//  Created by Hoang Le on 10/30/20.
//  Copyright © 2020 The Chromium Authors. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface PHAlbum : NSObject

+ (instancetype) albumWithId:(NSString* _Nonnull) identifier title:(NSString*) title;

@property (nonatomic, strong) NSString* identifier;
@property (nonatomic, strong) NSString* title;
@property (nonatomic, strong) NSMutableArray<NSString*>* items;

- (instancetype) initWithIdentifier:(NSString* _Nonnull)identifier
                        title:(NSString *)title;

- (void) addPhoto:(NSString* _Nonnull) photoId;

- (NSDictionary*) toMessageCodec;

@end

NS_ASSUME_NONNULL_END
