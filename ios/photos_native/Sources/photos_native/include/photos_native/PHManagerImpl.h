//
//  PHManagerImpl.h
//  annotium_native
//
//  Created by Hoang Le on 12/17/20.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class ResultHandler;

@interface PHManagerImpl : NSObject

+ (void) queryAlbums:(ResultHandler*) resultHandler;

@end

NS_ASSUME_NONNULL_END
