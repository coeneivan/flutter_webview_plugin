#import "FlutterWebviewPlugin.h"

static NSString *const CHANNEL_NAME = @"flutter_webview_plugin";

// UIWebViewDelegate
@interface FlutterWebviewPlugin() <WKNavigationDelegate, UIScrollViewDelegate, WKUIDelegate> {
    BOOL _enableAppScheme;
    BOOL _enableZoom;
}
@end

@implementation FlutterWebviewPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    channel = [FlutterMethodChannel
               methodChannelWithName:CHANNEL_NAME
               binaryMessenger:[registrar messenger]];
    
    UIViewController *viewController = [UIApplication sharedApplication].delegate.window.rootViewController;
    FlutterWebviewPlugin* instance = [[FlutterWebviewPlugin alloc] initWithViewController:viewController];
    
    [registrar addMethodCallDelegate:instance channel:channel];
}

- (instancetype)initWithViewController:(UIViewController *)viewController {
    self = [super init];
    if (self) {
        self.viewController = viewController;
        self.webviewDictionary = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    NSNumber *instance = call.arguments[@"instance"];
    
    if ([@"launch" isEqualToString:call.method]) {
        [self launch:call instance:instance result:result];
    } else if ([@"close" isEqualToString:call.method]) {
        [self closeWebView:instance];
        result(nil);
    } else if ([@"eval" isEqualToString:call.method]) {
        [self evalJavascript:call instance:instance completionHandler:^(NSString * response) {
            result(response);
        }];
    } else if ([@"resize" isEqualToString:call.method]) {
        [self resize:call instance:instance];
        result(nil);
    } else if ([@"reloadUrl" isEqualToString:call.method]) {
        [self reloadUrl:call instance:instance];
        result(nil);
    } else if ([@"show" isEqualToString:call.method]) {
        [self show:instance];
        result(nil);
    } else if ([@"hide" isEqualToString:call.method]) {
        [self hide:instance];
        result(nil);
    } else if ([@"stopLoading" isEqualToString:call.method]) {
        [self stopLoading:instance];
        result(nil);
    } else if ([@"cleanCookies" isEqualToString:call.method]) {
        [self cleanCookies];
    } else if ([@"back" isEqualToString:call.method]) {
        [self back:instance];
        result(nil);
    } else if ([@"forward" isEqualToString:call.method]) {
        [self forward:instance];
        result(nil);
    } else if ([@"reload" isEqualToString:call.method]) {
        [self reload:instance];
        result(nil);
    } else {
        result(FlutterMethodNotImplemented);
    }
}

- (void)launch:(FlutterMethodCall*)call instance:(NSNumber*)instance result:(FlutterResult)result  {
    if ([self.webviewDictionary objectForKey:instance]) {
        [self navigate:call instance:instance];
        result(@YES);
    } else {
        NSArray *permissions = call.arguments[@"permissions"];
        
        if(permissions != nil && [permissions isKindOfClass:[NSArray class]] && [permissions count] > 0) {
            [PermissionManager requestPermissions:permissions completionHandler:^(BOOL success) {
                if (success) {
                    dispatch_block_t block = ^{
                        [self initWebview:call instance:instance];
                    };
                    dispatch_async(dispatch_get_main_queue(), block);
                }
                
                result(@(success));
            }];
        } else {
            [self initWebview:call instance:instance];
            result(@YES);
        }
    }
}

- (void)initWebview:(FlutterMethodCall*)call instance:(NSNumber*)instance {
    NSString *url = call.arguments[@"url"];
    NSNumber *clearCache = call.arguments[@"clearCache"];
    NSNumber *clearCookies = call.arguments[@"clearCookies"];
    NSNumber *hidden = call.arguments[@"hidden"];
    NSDictionary *rect = call.arguments[@"rect"];
    _enableAppScheme = call.arguments[@"enableAppScheme"];
    NSString *userAgent = call.arguments[@"userAgent"];
    NSNumber *withZoom = call.arguments[@"withZoom"];
    NSArray *cookies = call.arguments[@"cookies"];
    NSNumber *scrollBar = call.arguments[@"scrollBar"];
    
    if (clearCache != (id)[NSNull null] && [clearCache boolValue]) {
        [[NSURLCache sharedURLCache] removeAllCachedResponses];
    }
    
    if (clearCookies != (id)[NSNull null] && [clearCookies boolValue]) {
        [[NSURLSession sharedSession] resetWithCompletionHandler:^{
        }];
    }
    
    if (userAgent != (id)[NSNull null]) {
        [[NSUserDefaults standardUserDefaults] registerDefaults:@{@"UserAgent": userAgent}];
    }
    
    CGRect rc;
    if (rect != (id)[NSNull null]) {
        rc = [self parseRect:rect];
    } else {
        rc = self.viewController.view.bounds;
    }
    
    WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
    WKWebsiteDataStore* store = [WKWebsiteDataStore nonPersistentDataStore];
    
    dispatch_group_t group = dispatch_group_create();
    
    if (cookies != nil) {
        NSURL* parsedUrl = [NSURL URLWithString:url];
        NSString* cookieString = [cookies componentsJoinedByString: @", "];
        NSDictionary* fakeHeaders = @{@"Set-Cookie": cookieString};
        NSArray* cookies = [NSHTTPCookie cookiesWithResponseHeaderFields:fakeHeaders forURL:parsedUrl];
        
        for(NSHTTPCookie *cookie in cookies) {
            dispatch_group_enter(group);
            [store.httpCookieStore setCookie:cookie completionHandler:^{
                dispatch_group_leave(group);
            }];
        };
    }

    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        config.websiteDataStore = store;
        
        WKWebView *webview = [[WKWebView alloc] initWithFrame:rc configuration:config];
        webview.UIDelegate = self;
        webview.navigationDelegate = self;
        webview.scrollView.delegate = self;
        webview.hidden = [hidden boolValue];
        webview.scrollView.showsHorizontalScrollIndicator = [scrollBar boolValue];
        webview.scrollView.showsVerticalScrollIndicator = [scrollBar boolValue];
        
        self.webviewDictionary[instance] = webview;
        
        _enableZoom = [withZoom boolValue];
        
        [self.viewController.view addSubview:self.webviewDictionary[instance]];
        
        [self navigate:call instance:instance];
    });
}

- (CGRect)parseRect:(NSDictionary *)rect {
    return CGRectMake([[rect valueForKey:@"left"] doubleValue],
                      [[rect valueForKey:@"top"] doubleValue],
                      [[rect valueForKey:@"width"] doubleValue],
                      [[rect valueForKey:@"height"] doubleValue]);
}

- (void) scrollViewDidScroll:(UIScrollView *)scrollView {
    id xDirection = @{@"xDirection": @(scrollView.contentOffset.x) };
    [channel invokeMethod:@"onScrollXChanged" arguments:xDirection];
    
    id yDirection = @{@"yDirection": @(scrollView.contentOffset.y) };
    [channel invokeMethod:@"onScrollYChanged" arguments:yDirection];
}

- (void)navigate:(FlutterMethodCall*)call instance:(NSNumber*)instance {
    if ([self.webviewDictionary objectForKey:instance]) {
        NSString *url = call.arguments[@"url"];
        NSNumber *withLocalUrl = call.arguments[@"withLocalUrl"];
        WKWebView *webview = self.webviewDictionary[instance];
        
        if ( [withLocalUrl boolValue]) {
            NSURL *htmlUrl = [NSURL fileURLWithPath:url isDirectory:false];
            if (@available(iOS 9.0, *)) {
                [webview loadFileURL:htmlUrl allowingReadAccessToURL:htmlUrl];
            } else {
                @throw @"not available on version earlier than ios 9.0";
            }
        } else {
            NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
            NSDictionary *headers = call.arguments[@"headers"];
            
            if (headers != nil) {
                [request setAllHTTPHeaderFields:headers];
            }
            
            [webview loadRequest:request];
        }
    }
}

- (void)evalJavascript:(FlutterMethodCall*)call instance:(NSNumber*)instance
     completionHandler:(void (^_Nullable)(NSString * response))completionHandler {
    if ([self.webviewDictionary objectForKey:instance]) {
        NSString *code = call.arguments[@"code"];
        WKWebView *webview = self.webviewDictionary[instance];
        [webview evaluateJavaScript:code
                  completionHandler:^(id _Nullable response, NSError * _Nullable error) {
                      completionHandler([NSString stringWithFormat:@"%@", response]);
                  }];
    } else {
        completionHandler(nil);
    }
}

- (void)resize:(FlutterMethodCall*)call instance:(NSNumber*)instance {
    if ([self.webviewDictionary objectForKey:instance]) {
        NSDictionary *rect = call.arguments[@"rect"];
        CGRect rc = [self parseRect:rect];
        WKWebView *webview = self.webviewDictionary[instance];
        webview.frame = rc;
    }
}

- (void)closeWebView:(NSNumber*)instance {
    if ([self.webviewDictionary objectForKey:instance]) {
        WKWebView *webview = self.webviewDictionary[instance];
        [webview stopLoading];
        [webview removeFromSuperview];
        webview.navigationDelegate = nil;
        self.webviewDictionary[instance] = nil;
        
        // manually trigger onDestroy
        [channel invokeMethod:@"onDestroy" arguments:nil];
    }
}

- (void)reloadUrl:(FlutterMethodCall*)call instance:(NSNumber*)instance {
    if ([self.webviewDictionary objectForKey:instance]) {
        NSString *url = call.arguments[@"url"];
        WKWebView *webview = self.webviewDictionary[instance];
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
        [webview loadRequest:request];
    }
}
- (void)show:(NSNumber*)instance {
    if ([self.webviewDictionary objectForKey:instance]) {
        WKWebView *webview = self.webviewDictionary[instance];
        webview.hidden = false;
    }
}

- (void)hide:(NSNumber*)instance {
    if ([self.webviewDictionary objectForKey:instance]) {
        WKWebView *webview = self.webviewDictionary[instance];
        webview.hidden = true;
    }
}
- (void)stopLoading:(NSNumber*)instance {
    if ([self.webviewDictionary objectForKey:instance]) {
        WKWebView *webview = self.webviewDictionary[instance];
        [webview stopLoading];
    }
}
- (void)back:(NSNumber*)instance {
    if ([self.webviewDictionary objectForKey:instance]) {
        WKWebView *webview = self.webviewDictionary[instance];
        [webview goBack];
    }
}
- (void)forward:(NSNumber*)instance {
    if ([self.webviewDictionary objectForKey:instance]) {
        WKWebView *webview = self.webviewDictionary[instance];
        [webview goForward];
    }
}
- (void)reload :(NSNumber*)instance{
    if ([self.webviewDictionary objectForKey:instance]) {
        WKWebView *webview = self.webviewDictionary[instance];
        [webview reload];
    }
}

- (void)cleanCookies {
    [[NSURLSession sharedSession] resetWithCompletionHandler:^{
    }];
}

#pragma mark -- WkWebView Delegate
- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction
decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    
    id data = @{@"url": navigationAction.request.URL.absoluteString,
                @"type": @"shouldStart",
                @"navigationType": [NSNumber numberWithInt:navigationAction.navigationType]};
    [channel invokeMethod:@"onState" arguments:data];
    
    if (navigationAction.navigationType == WKNavigationTypeBackForward) {
        [channel invokeMethod:@"onBackPressed" arguments:nil];
    } else {
        id data = @{@"url": navigationAction.request.URL.absoluteString};
        [channel invokeMethod:@"onUrlChanged" arguments:data];
    }
    
    if (_enableAppScheme ||
        ([webView.URL.scheme isEqualToString:@"http"] ||
         [webView.URL.scheme isEqualToString:@"https"] ||
         [webView.URL.scheme isEqualToString:@"about"])) {
            decisionHandler(WKNavigationActionPolicyAllow);
        } else {
            decisionHandler(WKNavigationActionPolicyCancel);
        }
}

- (WKWebView *)webView:(WKWebView *)webView createWebViewWithConfiguration:(WKWebViewConfiguration *)configuration
   forNavigationAction:(WKNavigationAction *)navigationAction windowFeatures:(WKWindowFeatures *)windowFeatures {
    
    if (!navigationAction.targetFrame.isMainFrame) {
        [webView loadRequest:navigationAction.request];
    }
    
    return nil;
}

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation {
    [channel invokeMethod:@"onState" arguments:@{@"type": @"startLoad", @"url": webView.URL.absoluteString}];
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    [channel invokeMethod:@"onState" arguments:@{@"type": @"finishLoad", @"url": webView.URL.absoluteString}];
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    [channel invokeMethod:@"onError" arguments:@{@"code": [NSString stringWithFormat:@"%ld", error.code], @"error": error.localizedDescription}];
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler {
    if ([navigationResponse.response isKindOfClass:[NSHTTPURLResponse class]]) {
        NSHTTPURLResponse * response = (NSHTTPURLResponse *)navigationResponse.response;
        
        [channel invokeMethod:@"onHttpError" arguments:@{@"code": [NSString stringWithFormat:@"%ld", response.statusCode], @"url": webView.URL.absoluteString}];
    }
    decisionHandler(WKNavigationResponsePolicyAllow);
}

#pragma mark -- UIScrollViewDelegate
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    if (scrollView.pinchGestureRecognizer.isEnabled != _enableZoom) {
        scrollView.pinchGestureRecognizer.enabled = _enableZoom;
    }
}

@end
