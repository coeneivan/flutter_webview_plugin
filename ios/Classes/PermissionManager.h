#import <Flutter/Flutter.h>
#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>

@interface PermissionManager : NSObject

+ (BOOL)hasPermission:(AVMediaType)mediaType;

+ (AVMediaType)getMediaType:(NSString *)permission;

+ (void)requestPermissions:(NSArray *)permissions completionHandler:(void(^)(BOOL success))completionHandler;

@end
