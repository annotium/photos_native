//
//  QueryOptions.m
//  annotium_native
//
//  Created by Hoang Le on 12/26/20.
//

#import "QueryOptions.h"

@implementation QueryOptions

+ (PHFetchOptions*) getAlbumFetchOptions
{
    PHFetchOptions *options = [[PHFetchOptions alloc] init];
    options.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO]];
    options.predicate = [NSPredicate predicateWithFormat:@"mediaType = %d", PHAssetMediaTypeImage];
    
    return options;
}

+ (PHImageRequestOptions*) getThumbnailRequestOptions
{
    PHImageRequestOptions* options = [[PHImageRequestOptions alloc] init];
    [options setSynchronous:TRUE];
    [options setNetworkAccessAllowed:TRUE];
    [options setDeliveryMode:PHImageRequestOptionsDeliveryModeOpportunistic];
//    [options setResizeMode:PHImageRequestOptionsResizeModeFast];
    [options setResizeMode:PHImageRequestOptionsResizeModeExact];
    
    return options;
}

+ (PHImageRequestOptions*) getImageRequestOptions
{
    PHImageRequestOptions* options = [[PHImageRequestOptions alloc] init];
    [options setSynchronous:TRUE];
    [options setNetworkAccessAllowed:TRUE];
    [options setDeliveryMode:PHImageRequestOptionsDeliveryModeHighQualityFormat];

    return options;
}

@end
