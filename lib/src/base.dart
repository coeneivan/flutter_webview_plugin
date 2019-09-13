import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const _kChannel = 'flutter_webview_plugin';
int webviewInstance = -1;

// TODO: more general state for iOS/android
enum WebViewState { shouldStart, startLoad, finishLoad, abortLoad }

// TODO: use an id by webview to be able to manage multiple webview

/// Singleton class that communicate with a Webview Instance
class FlutterWebviewPlugin {
  factory FlutterWebviewPlugin() =>  new FlutterWebviewPlugin._();
  int _webviewInstance;
  FlutterWebviewPlugin._() {

    print(" $webviewInstance let\'s Count!");
    webviewInstance++;
    _webviewInstance = webviewInstance;

    _channel.setMethodCallHandler(_handleMessages);
  }


  static void resetWebviews(){ //todo support growing array or smt
    webviewInstance = 0;
  }


  final _channel = const MethodChannel(_kChannel);

  final _onBack = StreamController<Null>.broadcast();
  final _onDestroy = StreamController<Null>.broadcast();
  final _onUrlChanged = StreamController<String>.broadcast();
  final _onStateChanged = StreamController<WebViewStateChanged>.broadcast();
  final _onScrollXChanged = StreamController<double>.broadcast();
  final _onScrollYChanged = StreamController<double>.broadcast();
  final _onProgressChanged = new StreamController<double>.broadcast();
  final _onHttpError = StreamController<WebViewHttpError>.broadcast();

  Future<Null> _handleMessages(MethodCall call) async {
    switch (call.method) {
      case 'onBack':
        _onBack.add(null);
        break;
      case 'onDestroy':
        _onDestroy.add(null);
        break;
      case 'onUrlChanged':
        _onUrlChanged.add(call.arguments['url']);
        break;
      case 'onScrollXChanged':
        _onScrollXChanged.add(call.arguments['xDirection']);
        break;
      case 'onScrollYChanged':
        _onScrollYChanged.add(call.arguments['yDirection']);
        break;
      case "onProgressChanged":
        _onProgressChanged.add(call.arguments["progress"]);
        break;
      case 'onState':
        _onStateChanged.add(
          WebViewStateChanged.fromMap(
            Map<String, dynamic>.from(call.arguments),
          ),
        );
        break;
      case 'onHttpError':
        _onHttpError.add(WebViewHttpError(call.arguments['code'], call.arguments['url']));
        break;
    }
  }

  /// Listening the OnDestroy LifeCycle Event for Android
  Stream<Null> get onDestroy => _onDestroy.stream;

  /// Listening the back key press Event for Android
  Stream<Null> get onBack => _onBack.stream;

  /// Listening url changed
  Stream<String> get onUrlChanged => _onUrlChanged.stream;

  /// Listening the onState Event for iOS WebView and Android
  /// content is Map for type: {shouldStart(iOS)|startLoad|finishLoad}
  /// more detail than other events
  Stream<WebViewStateChanged> get onStateChanged => _onStateChanged.stream;

  /// Listening web view loading progress estimation, value between 0.0 and 1.0
  Stream<double> get onProgressChanged => _onProgressChanged.stream;

  /// Listening web view y position scroll change
  Stream<double> get onScrollYChanged => _onScrollYChanged.stream;

  /// Listening web view x position scroll change
  Stream<double> get onScrollXChanged => _onScrollXChanged.stream;

  Stream<WebViewHttpError> get onHttpError => _onHttpError.stream;

  /// Start the Webview with [url]
  /// - [headers] specify additional HTTP headers
  /// - [withJavascript] enable Javascript or not for the Webview
  /// - [clearCache] clear the cache of the Webview
  /// - [clearCookies] clear all cookies of the Webview
  /// - [cookies] An initial list of cookies to populate the Webview's cookiejar
  /// - [hidden] not show
  /// - [rect]: show in rect, fullscreen if null
  /// - [enableAppScheme]: false will enable all schemes, true only for httt/https/about
  ///     android: Not implemented yet
  /// - [userAgent]: set the User-Agent of WebView
  /// - [withZoom]: enable zoom on webview
  /// - [withLocalStorage] enable localStorage API on Webview
  ///     Currently Android only.
  ///     It is always enabled in UIWebView of iOS and  can not be disabled.
  /// - [withLocalUrl]: allow url as a local path
  ///     Allow local files on iOs > 9.0
  /// - [scrollBar]: enable or disable scrollbar
  /// - [supportMultipleWindows] enable multiple windows support in Android
  /// - [invalidUrlRegex] is the regular expression of URLs that web view shouldn't load.
  /// For example, when webview is redirected to a specific URL, you want to intercept
  /// this process by stopping loading this URL and replacing webview by another screen.
  Future<bool> launch(String url, {
    Map<String, String> headers,
    bool withJavascript,
    bool clearCache,
    bool clearCookies,
    List<Cookie> cookies,
    bool hidden,
    bool enableAppScheme,
    Rect rect,
    String userAgent,
    bool withZoom,
    bool withLocalStorage,
    bool withLocalUrl,
    bool scrollBar,
    bool supportMultipleWindows,
    bool appCacheEnabled,
    bool allowFileURLs,
    bool useWideViewPort,
    String invalidUrlRegex,
    bool geolocationEnabled,
    List<String> permissions,
  }) async {
    final List<String> serializedCookies = cookies.map((cookie) => cookie.toString()).toList();
    final args = <String, dynamic>{
      'url': url,
      'withJavascript': withJavascript ?? true,
      'clearCache': clearCache ?? false,
      'hidden': hidden ?? false,
      'clearCookies': clearCookies ?? false,
      'cookies': serializedCookies,
      'enableAppScheme': enableAppScheme ?? true,
      'userAgent': userAgent,
      'withZoom': withZoom ?? false,
      'withLocalStorage': withLocalStorage ?? true,
      'withLocalUrl': withLocalUrl ?? false,
      'scrollBar': scrollBar ?? true,
      'supportMultipleWindows': supportMultipleWindows ?? false,
      'appCacheEnabled': appCacheEnabled ?? false,
      'allowFileURLs': allowFileURLs ?? false,
      'useWideViewPort': useWideViewPort ?? false,
      'invalidUrlRegex': invalidUrlRegex,
      'geolocationEnabled': geolocationEnabled ?? false,
      'instance': _webviewInstance,
      'permissions': permissions
    };

    if (headers != null) {
      args['headers'] = headers;
    }

    if (rect != null) {
      args['rect'] = {
        'left': rect.left,
        'top': rect.top,
        'width': rect.width,
        'height': rect.height,
      };
    }
    return await _channel.invokeMethod('launch', args);
  }



  /// Execute Javascript inside webview
  Future<String> evalJavascript(String code) async {
    final res = await _channel.invokeMethod('eval', {'code': code, 'instance': _webviewInstance});
    return res;
  }

  /// Close the Webview
  /// Will trigger the [onDestroy] event
  Future<Null> close() async => await _channel.invokeMethod('close',  {'instance': _webviewInstance});

  /// Reloads the WebView.
  Future<Null> reload() async => await _channel.invokeMethod('reload', {'instance': _webviewInstance});

  /// Navigates back on the Webview.
  Future<Null> goBack() async => await _channel.invokeMethod('back',  {'instance': _webviewInstance});

  /// Navigates forward on the Webview.
  Future<Null> goForward() async => await _channel.invokeMethod('forward', {'instance': _webviewInstance});

  // Hides the webview
  Future<Null> hide() async => await _channel.invokeMethod('hide', {'instance': _webviewInstance});

  // Shows the webview
  Future<Null> show() async => await _channel.invokeMethod('show', {'instance': _webviewInstance});

  // Reload webview with a url
  Future<Null> reloadUrl(String url) async {
    await _channel.invokeMethod('reloadUrl', {'url': url, 'instance': _webviewInstance});
  }

  // Clean cookies on WebView
  Future<Null> cleanCookies() async => await _channel.invokeMethod('cleanCookies', {'instance': _webviewInstance});

  // Stops current loading process
  Future<Null> stopLoading() async => await _channel.invokeMethod('stopLoading', {'instance': _webviewInstance});

  /// Close all Streams
  void dispose() {
    _onDestroy.close();
    _onUrlChanged.close();
    _onStateChanged.close();
    _onProgressChanged.close();
    _onScrollXChanged.close();
    _onScrollYChanged.close();
    _onHttpError.close();

  }

  Future<Map<String, String>> getCookies() async {
    final cookiesString = await evalJavascript('document.cookie');
    final cookies = <String, String>{};

    if (cookiesString?.isNotEmpty == true) {
      cookiesString.split(';').forEach((String cookie) {
        final split = cookie.split('=');
        cookies[split[0]] = split[1];
      });
    }

    return cookies;
  }

  /// resize webview
  Future<Null> resize(Rect rect, {int instance}) async {
    final args = {};
    args['rect'] = {
      'left': rect.left,
      'top': rect.top,
      'width': rect.width,
      'height': rect.height,
    };
    args['instance'] = instance;
    await _channel.invokeMethod('resize', args);
  }
}

class WebViewStateChanged {
  WebViewStateChanged(this.type, this.url, this.navigationType);

  factory WebViewStateChanged.fromMap(Map<String, dynamic> map) {
    WebViewState t;
    switch (map['type']) {
      case 'shouldStart':
        t = WebViewState.shouldStart;
        break;
      case 'startLoad':
        t = WebViewState.startLoad;
        break;
      case 'finishLoad':
        t = WebViewState.finishLoad;
        break;
      case 'abortLoad':
        t = WebViewState.abortLoad;
        break;
    }
    return WebViewStateChanged(t, map['url'], map['navigationType']);
  }

  final WebViewState type;
  final String url;
  final int navigationType;
}

class WebViewHttpError {
  WebViewHttpError(this.code, this.url);

  final String url;
  final String code;
}
