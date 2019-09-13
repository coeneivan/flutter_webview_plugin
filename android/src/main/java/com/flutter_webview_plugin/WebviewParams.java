package com.flutter_webview_plugin;
import java.util.ArrayList; 
import java.util.Map;
import java.util.function.Function;

class WebviewParams {
    public boolean withJavascript;
    public boolean clearCache;
    public boolean hidden;
    public boolean clearCookies;
    public ArrayList<String> cookies;
    public String userAgent;
    public String url;
    public Map<String, String> headers;
    public boolean withZoom;
    public boolean withLocalStorage;
    public boolean scrollBar;
    public boolean supportMultipleWindows;
    public boolean appCacheEnabled;
    public boolean allowFileURLs;
    public boolean useWideViewPort;
    public String invalidUrlRegex;
    public boolean geolocationEnabled;
}