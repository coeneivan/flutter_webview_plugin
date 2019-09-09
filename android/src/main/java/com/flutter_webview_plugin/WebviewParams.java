package com.flutter_webview_plugin;
import java.util.ArrayList; 
import java.util.Map;
import java.util.function.Function;

class WebviewParams {
    public static boolean withJavascript;
    public static boolean clearCache;
    public static boolean hidden;
    public static boolean clearCookies;
    public static ArrayList<String> cookies;
    public static String userAgent;
    public static String url;
    public static Map<String, String> headers;
    public static boolean withZoom;
    public static boolean withLocalStorage;
    public static boolean scrollBar;
    public static boolean supportMultipleWindows;
    public static boolean appCacheEnabled;
    public static boolean allowFileURLs;
    public static boolean useWideViewPort;
    public static String invalidUrlRegex;
    public static boolean geolocationEnabled;
}