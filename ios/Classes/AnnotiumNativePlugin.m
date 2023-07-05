#import "AnnotiumNativePlugin.h"
#import "ResultHandler.h"
#import "PHManager.h"
#import "Constants.h"
#import "UrlLauncher.h"

@implementation AnnotiumNativePlugin {
    PHManager* photoManager;
}

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    FlutterMethodChannel* channel = [FlutterMethodChannel
      methodChannelWithName:@"annotium_native"
            binaryMessenger:[registrar messenger]];

//    AnnotiumNativePlugin* instance = [[AnnotiumNativePlugin alloc] init];
    AnnotiumNativePlugin* instance = [[AnnotiumNativePlugin alloc] initWithRegistrar: registrar];
    [registrar addMethodCallDelegate:instance channel:channel];
    [registrar addApplicationDelegate: instance];
}

- (instancetype) initWithRegistrar:(NSObject<FlutterPluginRegistrar>* _Nonnull)registrar {
    self = [super init];
    if (self) {
        photoManager = [PHManager initWithRegistrar: registrar];
    }
    
    return self;
}

- (void) handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result
{
    NSString* methodName = call.method;
    ResultHandler *resultHandler = [ResultHandler handlerWithResult:result];

    if ([FUNC_GET_VERSION isEqualToString:methodName]) {
        [resultHandler reply:[AnnotiumNativePlugin getVersion]];
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
    else if ([FUNC_GET_INITIAL_PATH isEqualToString:methodName]) {
        [photoManager getInitialImage:resultHandler];
    }
    else if ([FUNC_IS_MEDIA_STORE_CHANGED isEqualToString:methodName]) {
        [photoManager isMediaStoreChanged:resultHandler];
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
//        NSDictionary* activityDictionary = launchOptions[UIApplicationLaunchOptionsUserActivityDictionaryKey];
        return FALSE;
    }
    else {
        return [self handleUrl:url setInitialData:TRUE];
    }
}

- (BOOL) application:(UIApplication *)application openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options
{
    return [self handleUrl:url setInitialData:FALSE];
}

- (BOOL) application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void (^)(NSArray * _Nonnull))restorationHandler {
    return [self handleUrl:[userActivity webpageURL] setInitialData:TRUE];
}

- (BOOL) handleUrl:(NSURL*) url setInitialData:(BOOL)initialData
{
    if (url != nil) {
        NSUserDefaults* userDefaults = [[NSUserDefaults alloc] initWithSuiteName:ANNOTIUM_GROUP];
        
        if ([TYPE_MEDIA isEqualToString:url.fragment]) {
            NSArray<NSString*>* components = [url.host componentsSeparatedByString:@"="];
            NSString* key = [components lastObject];
            NSString* url = [userDefaults objectForKey:key];
            photoManager.initialImage = [url stringByStandardizingPath];
        }
    }
        
    return FALSE;
}
@end
