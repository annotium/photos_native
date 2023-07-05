//
//  LaunchUrl.h
//  annotium_native
//
//  Created by Hoang Le on 12/28/20.
//

#import <Foundation/Foundation.h>

@class ResultHandler;

NS_ASSUME_NONNULL_BEGIN

@interface UrlLauncher : NSObject

+ (void) launchUrl:(NSDictionary* _Nonnull) arguments resultHandler:(ResultHandler*) resultHandler;

@end

NS_ASSUME_NONNULL_END
