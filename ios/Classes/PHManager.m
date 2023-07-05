//
//  PHManager.m
//  annotium_native
//
//  Created by Hoang Le on 12/17/20.
//

#import <Photos/Photos.h>
#import "PHManager.h"
#import "ResultHandler.h"
#import "PHManagerImpl.h"
#import "Constants.h"
#import "QueryOptions.h"
#import "ImageConverter.h"
#import "PHImageDescription.h"
#import "ImageTexture.h"

@interface PHManager() <PHPhotoLibraryChangeObserver>

@property(nonatomic, strong) NSString* initialImage;
@property(nonatomic, weak) NSObject<FlutterTextureRegistry> *textures;

@end

@implementation PHManager {
    PHCachingImageManager* cachingManager;
    NSOperationQueue* operationQueue;
    BOOL _isMediaStoreChanged;
    NSMutableDictionary* textureMap;
}

+ (CGSize) getAssetSize:(PHAsset* _Nonnull) asset maxSize:(int) maxWidth
{
    CGFloat maxSize = (CGFloat)maxWidth;
    if (asset.pixelWidth > asset.pixelHeight) {
        CGFloat width = asset.pixelWidth > maxSize ? maxSize : asset.pixelWidth;
        return CGSizeMake(width, width * asset.pixelHeight / asset.pixelWidth);
    }
    else {
        CGFloat height = asset.pixelHeight > maxSize ? maxSize : asset.pixelHeight;
        return CGSizeMake(height * asset.pixelWidth / asset.pixelHeight,height);
    }
}

+ (instancetype) initWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    PHManager* phManager = [[self alloc] init];
    phManager.textures = registrar.textures;
    
    return phManager;
}

- (instancetype) init {
    self = [super init];
    if (self) {
        _authorized = NO;
        _initialImage = @"";
        _isMediaStoreChanged = FALSE;
        _cachedAssets = [NSMutableSet set];
        
        textureMap = [NSMutableDictionary dictionary];
        cachingManager = [PHCachingImageManager new];
        operationQueue = [NSOperationQueue new];
        operationQueue.maxConcurrentOperationCount = [[NSProcessInfo processInfo] processorCount];
        [self startObserve];
    }

    return self;
}

- (void) cleanupTextures:(NSArray<NSString*>*) ids {
    for (int i = 0; i < ids.count; ++i) {
        NSString* key = ids[i];
        [textureMap removeObjectForKey:key];
    }
}

- (void) dealloc {
    [textureMap removeAllObjects];
}

- (void) setInitialImage:(NSString* _Nonnull)path
{
    _initialImage = path;
}

- (void) requestPermissions:(ResultHandler*) resultHandler
{
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
        BOOL auth = PHAuthorizationStatusAuthorized == status;
        [self setAuthorized:auth];
        [resultHandler reply:[NSNumber numberWithBool:auth]];
    }];
}

- (void) queryAlbums:(ResultHandler*) resultHandler
{
    _isMediaStoreChanged = FALSE;
    [operationQueue addOperationWithBlock: ^{
        [PHManagerImpl queryAlbums:resultHandler];
    }];
}

- (void) getThumbnail:(NSDictionary* _Nonnull) arguments resultHandler:(ResultHandler*) resultHandler
{
    NSString* identifier = arguments[ARG_ID];
    int width = [arguments[ARG_WIDTH] intValue];
    int height = [arguments[ARG_HEIGHT] intValue];

    [operationQueue addOperationWithBlock: ^{
        [self getThumbnail:identifier width:width height:height resultHandler:resultHandler];
    }];
}

- (void) getBytes:(NSDictionary* _Nonnull) arguments resultHandler:(ResultHandler*) resultHandler
{
    NSString* identifier = arguments[ARG_ID];
    int maxWidth = [arguments[ARG_MAXSIZE] intValue];

    [operationQueue addOperationWithBlock: ^{
        [self getBytes:identifier maxWidth:maxWidth resultHandler:resultHandler];
    }];
}

- (void) getPixels:(NSDictionary* _Nonnull) arguments resultHandler:(ResultHandler*) resultHandler
{
    NSString* identifier = arguments[ARG_ID];
    int maxWidth = [arguments[ARG_MAXSIZE] intValue];

    if (identifier == nil || identifier.length == 0) {
        NSString* url = arguments[ARG_URI];
        if (url == nil || url.length == 0) {
            url = _initialImage;
        }
        
        if (url == nil || url.length == 0) {
            [resultHandler replyError:ERR_PARAMETER_MISSING];
            return;
        }
        else {
            [self getPixelsFromUrl:url maxWidth:maxWidth resultHandler:resultHandler];
        }
    }
    else {
        [operationQueue addOperationWithBlock: ^{
            [self getPixels:identifier maxWidth:maxWidth resultHandler:resultHandler];
        }];
    }
}

- (void) deleteImages:(NSDictionary* _Nonnull) arguments resultHandler:(ResultHandler*) resultHandler
{
    NSArray* ids = arguments[ARG_IDS];
    int count = (int)ids.count;

    [operationQueue addOperationWithBlock: ^{
        [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
                PHFetchResult *fetchResult = [PHAsset fetchAssetsWithLocalIdentifiers:ids options:nil];
                [PHAssetChangeRequest deleteAssets:fetchResult];
            } completionHandler:^(BOOL success, NSError * _Nullable error) {
                if (success) {
                    [self mediaStoreUpdated];
                    [resultHandler reply: [NSNumber numberWithInt:count]];
                }
                else {
                    if (error == nil) {
                        [resultHandler reply: [NSNumber numberWithInt:0]];
                    } else {
                        [resultHandler replyError:error.localizedDescription];
                    }
                }
            }
         ];
    }];
}

- (void) save:(NSDictionary* _Nonnull) arguments resultHandler:(ResultHandler*) resultHandler
{
    NSData* data = [arguments[ARG_DATA] data];
    NSString* mime = arguments[ARG_MIME];
    int width = [arguments[ARG_WIDTH] intValue];
    int height = [arguments[ARG_HEIGHT] intValue];
    CGFloat quality = [arguments[ARG_QUALITY] floatValue] / 100.0;

    [operationQueue addOperationWithBlock: ^{
        UIImage* image = [ImageConverter convertFromRGBData:data width:width height:height];
        BOOL isPng = [MIME_PNG caseInsensitiveCompare:mime] == NSOrderedSame;
        NSData* imageData = isPng ?
            UIImagePNGRepresentation(image) :
            UIImageJPEGRepresentation(image, quality);

        __block NSString* identifier = @"";
        NSError* error;
        PHAssetCollection* assetCollection = [self getAssetCollectionTitle:ANNOTIUM error:&error];
        if (error != nil) {
            [resultHandler replyError:error.localizedDescription];
            return;
        }
        else if (assetCollection == nil) {
            [resultHandler replyError:ERR_UNKNOWN];
            return;
        }

        [PHPhotoLibrary.sharedPhotoLibrary performChanges:^{
            PHAssetCreationRequest* request = [PHAssetCreationRequest creationRequestForAsset];
            [request addResourceWithType:PHAssetResourceTypePhoto data:imageData options:nil];

            PHAssetCollectionChangeRequest *assetCollectionChangeRequest =
                [PHAssetCollectionChangeRequest changeRequestForAssetCollection:assetCollection];

            PHObjectPlaceholder* requestHolder = [request placeholderForCreatedAsset];
            [assetCollectionChangeRequest addAssets:@[requestHolder]];
            identifier = [requestHolder localIdentifier];
        } completionHandler:^(BOOL success, NSError * _Nullable error) {
            if (success) {
                [self mediaStoreUpdated];
                [resultHandler reply: [NSNumber numberWithBool:success]];
            }
            else {
                if (error == nil) {
                    [resultHandler reply: [NSNumber numberWithBool:false]];
                } else {
                    [resultHandler replyError:error.localizedDescription];
                }
            }
        }];
    }];
}

- (void) share:(NSDictionary* _Nonnull) arguments resultHandler:(ResultHandler*) resultHandler
{
    NSData* data = [arguments[ARG_DATA] data];
    int width = [arguments[ARG_WIDTH] intValue];
    int height = [arguments[ARG_HEIGHT] intValue];

    [operationQueue addOperationWithBlock: ^{
        UIImage* image = [ImageConverter convertFromRGBData:data width:width height:height];
        if(image == nil) {
            [resultHandler reply:[NSNumber numberWithBool:FALSE]];
            return;
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            UIViewController* rootViewController = [UIApplication sharedApplication].keyWindow.rootViewController;
            UIActivityViewController *activityViewController =
                [[UIActivityViewController alloc] initWithActivityItems:@[image] applicationActivities:nil];
            activityViewController.popoverPresentationController.sourceView = rootViewController.view;
            if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
//                activityViewController.popoverPresentationController.sourceRect = UIScreen.mainScreen.bounds;
                activityViewController.popoverPresentationController.sourceRect = CGRectMake(UIScreen.mainScreen.bounds.size.width - 40, 68, 0 , 0);
                activityViewController.popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionUnknown;
            }

            [rootViewController presentViewController:activityViewController animated:TRUE completion:^{
                [resultHandler reply:[NSNumber numberWithBool:TRUE]];
            }];
        });
    }];
}

- (void) getThumbnail:(NSString* _Nonnull) identifier width:(int) width height:(int) height resultHandler:(ResultHandler*) resultHandler
{
    PHFetchResult *fetchResult = [PHAsset fetchAssetsWithLocalIdentifiers:@[identifier] options:nil];
    if (fetchResult.count == 0) {
        [resultHandler replyError:ERR_NOT_FOUND];
        return;
    }

    PHAsset* asset = (PHAsset*)fetchResult.firstObject;
    BOOL cached = [_cachedAssets containsObject:[asset localIdentifier]];

    PHImageRequestOptions* options = [QueryOptions getThumbnailRequestOptions];
    CGSize size = CGSizeMake(width, height);
    [cachingManager requestImageForAsset:asset targetSize:size contentMode:PHImageContentModeAspectFill options:options resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
        if (result != nil) {
            NSData* data = [ImageConverter convertUIImageToRGBData:result];
            if (data == nil) {
                [resultHandler replyError:ERR_UNKNOWN];
                return;
            }
            
            CGSize size = result.size;
            PHImageDescription* imageDescription = [PHImageDescription
                                                    imageWithWidth:size.width
                                                    height:size.height
                                                    data:data];
            
            [resultHandler reply: [imageDescription toMessageCodec]];
        }
    }];

    if (!cached) {
        [cachingManager startCachingImagesForAssets:@[asset] targetSize:size contentMode:PHImageContentModeAspectFill options:options];
        dispatch_async(dispatch_get_main_queue(), ^{
            [[self cachedAssets] addObject:[asset localIdentifier]];
        });
    }
}

- (void) getPixels:(NSString* _Nonnull) identifier maxWidth:(int) maxWidth resultHandler:(ResultHandler*) resultHandler
{
    PHFetchResult *fetchResult = [PHAsset fetchAssetsWithLocalIdentifiers:@[identifier] options:nil];
    if (fetchResult.count == 0) {
        [resultHandler replyError:ERR_NOT_FOUND];
        return;
    }

    PHAsset* asset = (PHAsset*)fetchResult.firstObject;
    PHImageRequestOptions* options = [QueryOptions getImageRequestOptions];
    CGSize size = [PHManager getAssetSize: asset maxSize: maxWidth];

    [[PHImageManager defaultManager] requestImageForAsset:asset targetSize:size contentMode:PHImageContentModeAspectFill options:options resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
        if (result != nil) {
            if (![info objectForKey:PHImageResultIsDegradedKey] || ![info[PHImageResultIsDegradedKey] boolValue]) {
                NSData* data = [ImageConverter convertUIImageToRGBData:result];
                if (data == nil) {
                    [resultHandler replyError:ERR_UNKNOWN];
                    return;
                }
                
                CGSize size = result.size;
                PHImageDescription* imageDescription = [PHImageDescription
                                                        imageWithWidth:size.width
                                                        height:size.height
                                                        data:data];
                
                [resultHandler reply: [imageDescription toMessageCodec]];
            }
        }
    }];
}

- (void) getBytes:(NSString* _Nonnull) identifier maxWidth:(int) maxWidth resultHandler:(ResultHandler*) resultHandler
{
    PHFetchResult *fetchResult = [PHAsset fetchAssetsWithLocalIdentifiers:@[identifier] options:nil];
    if (fetchResult.count == 0) {
        [resultHandler replyError:ERR_NOT_FOUND];
        return;
    }

    PHAsset* asset = (PHAsset*)fetchResult.firstObject;
    PHImageRequestOptions* options = [QueryOptions getImageRequestOptions];
    CGSize size = [PHManager getAssetSize: asset maxSize: maxWidth];

    [[PHImageManager defaultManager] requestImageForAsset:asset targetSize:size contentMode:PHImageContentModeAspectFill options:options resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
        if (result != nil) {
            if (![info objectForKey:PHImageResultIsDegradedKey] || ![info[PHImageResultIsDegradedKey] boolValue]) {
                [resultHandler reply: [FlutterStandardTypedData typedDataWithBytes:UIImagePNGRepresentation(result)]];
            }
        }
    }];
}

- (void) getPixelsFromUrl:(NSString* _Nonnull) path maxWidth:(int) maxWidth resultHandler:(ResultHandler*) resultHandler
{
    if (path == nil) {
        [resultHandler replyError:ERR_UNKNOWN];
        return;
    }
    
    UIImage *image = [UIImage imageWithData:[[NSFileManager defaultManager] contentsAtPath:path]];
    if (image == nil) {
        [resultHandler replyError:ERR_UNKNOWN];
        return;
    }

    _initialImage = @"";

    NSData* data = [ImageConverter convertUIImageToRGBData:image];
    if (data == nil) {
        [resultHandler replyError:ERR_UNKNOWN];
        return;
    }
    
    CGSize size = image.size;
    PHImageDescription* imageDescription = [PHImageDescription
                                            imageWithWidth:size.width
                                            height:size.height
                                            data:data];
    
    [resultHandler reply: [imageDescription toMessageCodec]];
}


-(PHAssetCollection*) getAssetCollectionTitle:(NSString * _Nonnull) title error:(NSError**) error
{
    // check if album existed
    PHFetchOptions *options = [[PHFetchOptions alloc] init];
    options.predicate = [NSPredicate predicateWithFormat:@"title = %@", title];

    PHFetchResult<PHAssetCollection*>* albumCollections = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum
                                                          subtype: PHAssetCollectionSubtypeAny
                                                          options: options];
    if (albumCollections.count > 0) {
//        NSLog(@"Found collection name %@", title);
        return albumCollections.firstObject;
    }

    // if not existed, create new
//    NSLog(@"Create collection name %@", title);
    __block NSString* targetId;
    [PHPhotoLibrary.sharedPhotoLibrary performChangesAndWait:^{
        PHAssetCollectionChangeRequest *request =
            [PHAssetCollectionChangeRequest creationRequestForAssetCollectionWithTitle: title];
        targetId = request.placeholderForCreatedAssetCollection.localIdentifier;
    } error:error];

    if (targetId != nil) {
        PHFetchResult<PHAssetCollection*>* collections =
            [PHAssetCollection fetchAssetCollectionsWithLocalIdentifiers: @[targetId] options: nil];
        if (collections.count > 0) {
            return collections.firstObject;
        }

    }

    return nil;
}

- (void) getInitialImage:(ResultHandler*) resultHandler;
{
    [resultHandler reply:_initialImage];
}

- (void) isMediaStoreChanged:(ResultHandler*) resultHandler
{
    [resultHandler replyBool:_isMediaStoreChanged];
}

- (void) mediaStoreUpdated {
    _isMediaStoreChanged = TRUE;
}

#pragma mark - <PHPhotoLibraryChangeObserver>
- (void) startObserve
{
    [[PHPhotoLibrary sharedPhotoLibrary] registerChangeObserver:self];
}

- (void) stopObserve
{
    [[PHPhotoLibrary sharedPhotoLibrary] unregisterChangeObserver:self];
}

- (void)photoLibraryDidChange:(PHChange *)changeInstance {
    _isMediaStoreChanged = TRUE;
}

- (void) acquireTexture:(NSDictionary* _Nonnull) arguments resultHandler:(ResultHandler*) resultHandler
{
    NSString* identifier = arguments[ARG_ID];
//    NSLog(@"Acquire texture '%@'", identifier);

    int width = [arguments[ARG_WIDTH] intValue];
    int height = [arguments[ARG_HEIGHT] intValue];

    int minWidth = MIN(width, height);

    __weak NSObject<FlutterTextureRegistry> *weakTextures = _textures;
    __weak NSMutableDictionary* weakMap = textureMap;
    
    [operationQueue addOperationWithBlock: ^{
        [self loadImageWithId:identifier width:minWidth addCompletionHandler:^(UIImage *image) {
            ImageTexture* imageTexture = [ImageTexture initWithImage: image size: image.size textures:weakTextures];
            [imageTexture performRegister];
            if (imageTexture.textureId == 0) {
                usleep(20000);
                NSLog(@"Register texture '%@' second time", identifier);
                [imageTexture performRegister];
            }
            
            if (imageTexture.textureId > 0) {
                NSNumber* value = [NSNumber numberWithLong:imageTexture.textureId];
                [weakMap setObject:imageTexture forKey:identifier];
                [resultHandler reply:value];
            } else {
                [resultHandler replyError:ERR_UNKNOWN];
            }
        }];
    }];
}

- (void) releaseTexture:(NSDictionary* _Nonnull) arguments resultHandler:(ResultHandler*) resultHandler
{
    NSString* identifier = arguments[ARG_ID];
//    NSLog(@"Release texture '%@'", identifier);
    
    ImageTexture* imageTexture = [textureMap objectForKey:identifier];
    if (imageTexture) {
        [textureMap removeObjectForKey:identifier];
    }
}

- (void) loadImageWithId:(NSString* _Nonnull) identifier width:(int) width addCompletionHandler:(void(^)(UIImage* image)) completionHandler
{
    PHFetchResult *fetchResult = [PHAsset fetchAssetsWithLocalIdentifiers:@[identifier] options:nil];
    if (fetchResult.count == 0) {
        completionHandler(nil);
        return;
    }

    PHAsset* asset = (PHAsset*)fetchResult.firstObject;
    BOOL cached = [_cachedAssets containsObject:[asset localIdentifier]];
    
    PHImageRequestOptions* options = [QueryOptions getThumbnailRequestOptions];
//    CGSize size = CGSizeMake(asset.pixelWidth, asset.pixelHeight);
    CGSize size = CGSizeMake(width, width);
//    CGRect square = CGRectMake(0, 0, width, width);
//    CGRect cropRect = CGRectApplyAffineTransform(square,
//                     CGAffineTransformMakeScale(1.0 / asset.pixelWidth,
//                                                1.0 / asset.pixelHeight));
//    options.normalizedCropRect = cropRect;

//    [[PHImageManager defaultManager] requestImageForAsset:asset targetSize:size contentMode:PHImageContentModeAspectFill options:options resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
//        if (result != nil) {
//            if (![info objectForKey:PHImageResultIsDegradedKey] || ![info[PHImageResultIsDegradedKey] boolValue]) {
//                completionHandler(result);
//            }
//        }
//    }];
    
    [cachingManager requestImageForAsset:asset targetSize:size contentMode:PHImageContentModeAspectFill options:options resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
        if (result != nil) {
            if (![info objectForKey:PHImageResultIsDegradedKey] || ![info[PHImageResultIsDegradedKey] boolValue]) {
                completionHandler(result);
            }
        }
    }];

    if (!cached) {
        [cachingManager startCachingImagesForAssets:@[asset] targetSize:size contentMode:PHImageContentModeAspectFill options:options];
        dispatch_async(dispatch_get_main_queue(), ^{
            [[self cachedAssets] addObject:[asset localIdentifier]];
        });
    }
}

@end
