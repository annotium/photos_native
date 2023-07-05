//
//  QueryOptions.h
//  annotium_native
//
//  Created by Hoang Le on 12/26/20.
//

#import <Foundation/Foundation.h>
#import <Photos/Photos.h>

NS_ASSUME_NONNULL_BEGIN

@interface QueryOptions : NSObject

+ (PHFetchOptions*) getAlbumFetchOptions;
+ (PHImageRequestOptions*) getThumbnailRequestOptions;
+ (PHImageRequestOptions*) getImageRequestOptions;

@end

NS_ASSUME_NONNULL_END
