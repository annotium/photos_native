//
//  PHManager.h
//  annotium_native
//
//  Created by Hoang Le on 12/17/20.
//

#import <Foundation/Foundation.h>
#import <Flutter/Flutter.h>

NS_ASSUME_NONNULL_BEGIN

@class ResultHandler;

@interface PHManager : NSObject

@property(nonatomic) BOOL authorized;
@property(nonatomic, strong) NSMutableSet<NSString*> *cachedAssets;

+ (instancetype) initWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar;

- (void) requestPermissions:(ResultHandler*) resultHandler;
- (void) queryAlbums:(ResultHandler*) resultHandler;
- (void) getPixels:(NSDictionary* _Nonnull) arguments resultHandler:(ResultHandler*) resultHandler;
- (void) deleteImages:(NSDictionary* _Nonnull) arguments resultHandler:(ResultHandler*) resultHandler;
- (void) save:(NSDictionary* _Nonnull) arguments resultHandler:(ResultHandler*) resultHandler;
- (void) share:(NSDictionary* _Nonnull) arguments resultHandler:(ResultHandler*) resultHandler;
- (void) isMediaStoreChanged:(ResultHandler*) resultHandler;

- (void) acquireTexture:(NSDictionary* _Nonnull) arguments resultHandler:(ResultHandler*) resultHandler;

- (void) releaseTexture:(NSDictionary* _Nonnull) arguments resultHandler:(ResultHandler*) resultHandler;

// DEPRECATED
- (void) getThumbnail:(NSDictionary* _Nonnull) arguments resultHandler:(ResultHandler*) resultHandler;
- (void) getBytes:(NSDictionary* _Nonnull) arguments resultHandler:(ResultHandler*) resultHandler __deprecated;

@end

NS_ASSUME_NONNULL_END
