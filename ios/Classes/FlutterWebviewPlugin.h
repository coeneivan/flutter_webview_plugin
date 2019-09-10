#import <Flutter/Flutter.h>
#import <WebKit/WebKit.h>
#import "PermissionManager.h"

static FlutterMethodChannel *channel;

@interface FlutterWebviewPlugin : NSObject<FlutterPlugin>
@property (nonatomic, retain) UIViewController *viewController;
@property (nonatomic, retain) NSMutableDictionary *webviewDictionary;
@end
