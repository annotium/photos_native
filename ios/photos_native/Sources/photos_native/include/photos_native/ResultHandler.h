//
//  ResultHandler.h
//  annotium_native
//
//  Created by Hoang Le on 12/17/20.
//

#import <Foundation/Foundation.h>
#import <Flutter/Flutter.h>

@interface ResultHandler : NSObject

@property(nonatomic, copy) FlutterResult result;

+ (instancetype) handlerWithResult:(FlutterResult) result;
- (instancetype) initWithResult:(FlutterResult) result;
- (void) replyError:(NSString*) errorCode;
- (void) reply:(id)obj;
- (void) replyBool:(BOOL) value;
- (void) notImplemented;
- (BOOL) isReplied;

@end
