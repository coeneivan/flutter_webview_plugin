#import "PermissionManager.h"

@implementation PermissionManager

+ (BOOL)hasPermission:(AVMediaType)mediaType {
    AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:mediaType];
    
    return status == AVAuthorizationStatusAuthorized;
}

+ (AVMediaType)getMediaType:(NSString *)permission {
    if ([permission isEqualToString:@"CAMERA"]) {
        return AVMediaTypeVideo;
    }
    
    return AVMediaTypeAudio;
}

+ (void)requestPermissions:(NSArray *)permissions completionHandler:(void(^)(BOOL success))completionHandler {
    NSMutableArray *resultArray = [NSMutableArray arrayWithCapacity:permissions.count];
    NSMutableArray *permissionsToCheck = [NSMutableArray array];
    
    for (NSString *permission in permissions) {
        AVMediaType mediaType = [PermissionManager getMediaType:permission];
        
        if (![PermissionManager hasPermission:mediaType]) {
            [permissionsToCheck addObject:permission];
        }
    }
    
    if (permissionsToCheck.count == 0) {
        completionHandler(true);
        return;
    }
    
    NSMutableSet *requestQueue = [[NSMutableSet alloc] initWithArray:permissionsToCheck];
    
    for (int i = 0; i < permissionsToCheck.count; ++i) {
        NSString *permission = permissionsToCheck[i];
        AVMediaType mediaType = [PermissionManager getMediaType:permission];
        
        [AVCaptureDevice requestAccessForMediaType:mediaType completionHandler:^(BOOL granted) {
            [requestQueue removeObject:permission];
            resultArray[i] = @(granted);
            
            if(requestQueue.count == 0) {
                BOOL isSuccessful = ![resultArray containsObject:@(NO)];
                completionHandler(isSuccessful);
                return;
            }
        }];
    }
}

@end
