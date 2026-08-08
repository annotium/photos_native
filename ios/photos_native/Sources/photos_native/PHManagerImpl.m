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

        if (count0 < count1) {
            return NSOrderedAscending;
        }
        if (count0 > count1) {
            return NSOrderedDescending;
        }
        return NSOrderedSame;
    }];

    // "Recents" (formerly "Camera Roll") is Apple's own most-complete
    // personal-library album — the semantic equivalent of Android's
    // synthesized "AllPhotos" pseudo-album, which is always index 0. The
    // count-ascending sort above puts it near the END of the list (it's
    // typically the largest album), so callers defaulting to index 0 (see
    // `GalleryController._selectedAlbumIndex`) would not land on it. Pin it
    // to index 0 to match that expectation, without disturbing relative
    // order of the rest.
    PHFetchResult<PHAssetCollection*>* userLibraryCollections =
        [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum
                                                  subtype:PHAssetCollectionSubtypeSmartAlbumUserLibrary
                                                  options:nil];
    NSString* userLibraryId = userLibraryCollections.firstObject.localIdentifier;
    if (userLibraryId != nil) {
        NSUInteger index = [albums indexOfObjectPassingTest:^BOOL(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            return [[(PHAlbum*)obj identifier] isEqualToString:userLibraryId];
        }];
        if (index != NSNotFound && index != 0) {
            PHAlbum* userLibraryAlbum = albums[index];
            [albums removeObjectAtIndex:index];
            [albums insertObject:userLibraryAlbum atIndex:0];
        }
    }

    NSMutableArray* codecs = [NSMutableArray array];
    for (PHAlbum* album in albums) {
        [codecs addObject:[album toMessageCodec]];
    }
    
    [resultHandler reply: codecs];
}

@end
