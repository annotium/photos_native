//
//  LaunchUrl.m
//  annotium_native
//
//  Created by Hoang Le on 12/28/20.
//

#import "UrlLauncher.h"
#import "ResultHandler.h"
#import "Constants.h"

@implementation UrlLauncher

+ (void) launchUrl:(NSDictionary* _Nonnull) arguments resultHandler:(ResultHandler*) resultHandler
{
    NSString* urlString = arguments[ARG_URL];
    if (urlString == nil) {
        [resultHandler reply:[NSNumber numberWithBool:FALSE]];
        return;
    }
    
//    NSString* escaped = [urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSString* escaped = [urlString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    NSURL *url = [NSURL URLWithString:escaped];
    if (url == nil) {
        [resultHandler reply:[NSNumber numberWithBool:FALSE]];
        return;
    }

    UIApplication *application = [UIApplication sharedApplication];
    if ([application canOpenURL:url]) {
        [application openURL:url
                      options:@{}
            completionHandler:^(BOOL success) {
                [resultHandler reply:[NSNumber numberWithBool:success]];
            }];
    }
    else {
        [resultHandler reply:[NSNumber numberWithBool:FALSE]];
    }
}

@end
