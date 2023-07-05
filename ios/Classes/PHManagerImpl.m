//
//  PHManagerImpl.m
//  annotium_native
//
//  Created by Hoang Le on 12/17/20.
//

#import "PHManagerImpl.h"
#import <Photos/Photos.h>
#import "PHAlbum.h"
#import "ResultHandler.h"
#import "QueryOptions.h"

@implementation PHManagerImpl

+ (void) queryAlbums:(ResultHandler*) resultHandler
{
    PHFetchResult<PHAssetCollection*>* albumCollections = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum
                                                          subtype: PHAssetCollectionSubtypeAny
                                                          options: nil];
    NSMutableArray* albums = [NSMutableArray array];
    PHFetchOptions* options = [QueryOptions getAlbumFetchOptions];
    [albumCollections enumerateObjectsUsingBlock:^(id  _Nonnull collection, NSUInteger idx, BOOL * _Nonnull stop) {
        NSLog(@"Read album collection %@", ((PHAssetCollection*)collection).localizedTitle);
        
        PHFetchResult *fetchResult = [PHAsset fetchAssetsInAssetCollection:collection options:options];
        if (fetchResult.count > 0) {
            NSString* albumId = [collection localIdentifier];
            NSString* title = [collection localizedTitle];

            PHAlbum* album = [PHAlbum albumWithId: albumId title:title];

            [fetchResult enumerateObjectsUsingBlock:^(PHAsset* _Nonnull asset, NSUInteger idx, BOOL * _Nonnull stop) {
                [album addPhoto:asset.localIdentifier];
            }];
            
            [albums addObject:album];
        }
    }];
    
    [albums sortUsingComparator:^NSComparisonResult(id  _Nonnull id0, id  _Nonnull id1) {
        long count0 = [(PHAlbum*)id0 items].count;
        long count1 = [(PHAlbum*)id1 items].count;
        
        return count0 < count1;
    }];
    
    NSMutableArray* codecs = [NSMutableArray array];
    for (PHAlbum* album in albums) {
        [codecs addObject:[album toMessageCodec]];
    }
    
    [resultHandler reply: codecs];
}

@end
