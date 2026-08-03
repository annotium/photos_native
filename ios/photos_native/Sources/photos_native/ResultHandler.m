//
//  ResultHandler.m
//  annotium_native
//
//  Created by Hoang Le on 12/17/20.
//

#import "ResultHandler.h"

@implementation ResultHandler {
    BOOL replied;
}

+ (instancetype)handlerWithResult:(FlutterResult)result
{
    return [[self alloc] initWithResult:result];
}

- (instancetype) initWithResult:(FlutterResult)result
{
    self = [super init];
    if (self) {
        self.result = result;
        replied = false;
    }
    
    return self;
}

- (void) replyBool:(BOOL) value {
    if (replied) {
        return;
    }
    replied = YES;

    dispatch_async(dispatch_get_main_queue(), ^{
        self.result([NSNumber numberWithBool:value]);
    });
}

- (void)reply:(id)obj
{
    if (replied) {
        return;
    }
    replied = YES;

    dispatch_async(dispatch_get_main_queue(), ^{
        self.result(obj);
    });
}

- (void)replyError:(NSString *)errorCode
{
    if (replied) {
        return;
    }
    
    replied = YES;
  
//    __weak ResultHandler* weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        FlutterError *error = [FlutterError errorWithCode:errorCode message:nil details:nil];
        self.result(error);
    });
}

- (void)notImplemented
{
    if (replied) {
      return;
    }
    
    replied = YES;
//    __weak ResultHandler* weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        self.result(FlutterMethodNotImplemented);
    });
}

- (BOOL)isReplied
{
    return replied;
}

@end
