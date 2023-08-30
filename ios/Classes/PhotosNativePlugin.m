// Copyright 2023 Annotium

#import "PhotosNativePlugin.h"
#import "ResultHandler.h"
#import "PHManager.h"
#import "Constants.h"
#import "UrlLauncher.h"

@implementation PhotosNativePlugin {
    PHManager* photoManager;
    NSMutableDictionary* memoMap;
}

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  FlutterMethodChannel* channel = [FlutterMethodChannel
      methodChannelWithName:LIBRARY_CHANNEL_NAME
            binaryMessenger:[registrar messenger]];
    PhotosNativePlugin* instance = [[PhotosNativePlugin alloc] initWithRegistrar: registrar];
    [registrar addMethodCallDelegate:instance channel:channel];
    [registrar addApplicationDelegate: instance];
}

- (instancetype) initWithRegistrar:(NSObject<FlutterPluginRegistrar>* _Nonnull)registrar {
    self = [super init];
    if (self) {
        memoMap = [NSMutableDictionary new];
        photoManager = [PHManager initWithRegistrar: registrar];
    }
    
    return self;
}

- (void) handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result
{
    NSString* methodName = call.method;
    ResultHandler *resultHandler = [ResultHandler handlerWithResult:result];

    if ([FUNC_GET_VERSION isEqualToString:methodName]) {
        [resultHandler reply:[PhotosNativePlugin getVersion]];
    }
    else if ([FUNC_REQUEST_PERMISSIONS isEqualToString:methodName]) {
        [photoManager requestPermissions:resultHandler];
    }
    else if ([FUNC_QUERY_ALBUMS isEqualToString:methodName]) {
        [photoManager queryAlbums:resultHandler];
    }
    else if ([FUNC_GET_THUMBNAIL isEqualToString:methodName]) {
        [photoManager getThumbnail:call.arguments resultHandler:resultHandler];
    }
    else if ([FUNC_GET_BYTES isEqualToString:methodName]) {
        [photoManager getBytes:call.arguments resultHandler:resultHandler];
    }
    else if ([FUNC_GET_PIXELS isEqualToString:methodName]) {
        [photoManager getPixels:call.arguments resultHandler:resultHandler];
    }
    else if ([FUNC_DELETE isEqualToString:methodName]) {
        [photoManager deleteImages:call.arguments resultHandler:resultHandler];
    }
    else if ([FUNC_SAVE isEqualToString:methodName]) {
        [photoManager save:call.arguments resultHandler:resultHandler];
    }
    else if ([FUNC_SHARE isEqualToString:methodName]) {
        [photoManager share:call.arguments resultHandler:resultHandler];
    }
    else if ([FUNC_LAUNCH_URL isEqualToString:methodName]) {
        [UrlLauncher launchUrl:call.arguments resultHandler:resultHandler];
    }
    else if ([FUNC_IS_MEDIA_STORE_CHANGED isEqualToString:methodName]) {
        [photoManager isMediaStoreChanged:resultHandler];
    }
    else if ([FUNC_GET_MEMO isEqualToString:methodName]) {
        NSString* key = call.arguments[ARG_KEY];
        id value = [self getMemo:key];
        [resultHandler reply:value];
    }
    else if ([FUNC_SET_MEMO isEqualToString:methodName]) {
        NSString* key = call.arguments[ARG_KEY];
        id value = call.arguments[ARG_VALUE];
        BOOL result = [self setMemo:key value:value];
        [resultHandler replyBool:result];

    }
    else if ([FUNC_ACQUIRE_TEXTURE isEqualToString:methodName]) {
        [photoManager acquireTexture:call.arguments resultHandler:resultHandler];
    }
    else if ([FUNC_RELEASE_TEXTURE isEqualToString:methodName]) {
        [photoManager releaseTexture:call.arguments resultHandler:resultHandler];
    }
    else {
        result(FlutterMethodNotImplemented);
    }
}

+ (NSDictionary*) getVersion
{
    NSDictionary* info = [[NSBundle mainBundle] infoDictionary];
    return @{
        KEY_APP_VERSION: info[@"CFBundleShortVersionString"],
        KEY_BUILD_NUMBER: info[@"CFBundleVersion"],
        KEY_SDK_INT: @0
    };
}

#pragma mark - App Delegate

- (BOOL) application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary<UIApplicationLaunchOptionsKey, id> *)launchOptions {
    //url = launchOptions[UIApplication.LaunchOptionsKey.url]
    NSURL* url = launchOptions[UIApplicationLaunchOptionsURLKey];
    if (url == nil) {
        return FALSE;
    }
    
    return [self handleUrl:url];
}

- (BOOL) application:(UIApplication *)application openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options
{
    return [self handleUrl:url];
}

- (BOOL) application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void (^)(NSArray * _Nonnull))restorationHandler {
    return [self handleUrl:[userActivity webpageURL]];
}

- (BOOL) handleUrl:(NSURL*) url
{
    if (url == nil) {
        return FALSE;
    }
        
    if ([TYPE_MEDIA isEqualToString:url.fragment]) {
        NSArray<NSString*>* components = [url.host componentsSeparatedByString:@"="];
        NSString* key = [components lastObject];
        NSUserDefaults* userDefaults = [[NSUserDefaults alloc] initWithSuiteName:ANNOTIUM_GROUP];
        NSString* url = [userDefaults objectForKey:key];
        NSString* path = [url stringByStandardizingPath];
        if (path && path.length) {
            [self setMemo:KEY_SHARED_URI value:path];
        }
    }
        
    return FALSE;
}

- (BOOL) setMemo:(NSString* _Nonnull) key value:(id) value {
    if (!key.length) {
        return FALSE;
    }
    
    if (value == nil) {
        [memoMap removeObjectForKey:key];
    } else {
        [memoMap setValue:value forKey:key];
    }
    
    return TRUE;
}

- (id) getMemo:(NSString* _Nonnull) key {
    if (!key.length) {
        return nil;
    }
    
    id value = [memoMap objectForKey:key];
    [memoMap removeObjectForKey:key];

    return value;
}

@end

