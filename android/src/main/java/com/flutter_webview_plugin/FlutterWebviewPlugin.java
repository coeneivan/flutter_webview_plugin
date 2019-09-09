package com.flutter_webview_plugin;

import android.util.Log;
import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.graphics.Point;
import android.view.Display;
import android.widget.FrameLayout;
import android.webkit.CookieManager;
import android.webkit.ValueCallback;
import android.os.Build;

import java.util.Arrays;
import java.util.ArrayList;
import java.util.Map;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.PluginRegistry;
import io.flutter.plugin.common.PluginRegistry.Registrar;
import java.util.function.Function;

/**
 * FlutterWebviewPlugin
 */
public class FlutterWebviewPlugin implements MethodCallHandler, PluginRegistry.ActivityResultListener {
    private Activity activity;
    private WebviewManager[] webViewManagers;
    private Registrar registrar;
    private Context context;
    static MethodChannel channel;
    private static final String CHANNEL_NAME = "flutter_webview_plugin";

    public static void registerWith(Registrar registrar) {
        channel = new MethodChannel(registrar.messenger(), CHANNEL_NAME);
        final FlutterWebviewPlugin instance = new FlutterWebviewPlugin(registrar.activity(),registrar.activeContext(), registrar);
        registrar.addActivityResultListener(instance);
        channel.setMethodCallHandler(instance);
    }

    private FlutterWebviewPlugin(Activity activity, Context context, Registrar registrar) {
        this.registrar = registrar;
        this.activity = activity;
        this.context = context;
        this.webViewManagers = new WebviewManager[10];
    }

    @Override
    public void onMethodCall(MethodCall call, MethodChannel.Result result) {
       
        int instance = call.argument("instance");
        switch (call.method) {
            case "launch":
                openUrl(call, result, instance);
                break;
            case "close":
                close(call, result, instance);
                break;
            case "eval":
                eval(call, result, instance);
                break;
            case "resize":
                resize(call, result, instance);
                break;
            case "reload":
                reload(call, result, instance);
                break;
            case "back":
                back(call, result, instance);
                break;
            case "forward":
                forward(call, result, instance);
                break;
            case "hide":
                hide(call, result, instance);
                break;
            case "show":
                show(call, result, instance);
                break;
            case "reloadUrl":
                reloadUrl(call, result, instance);
                break;
            case "stopLoading":
                stopLoading(call, result, instance);
                break;
            case "cleanCookies":
                cleanCookies(call, result, instance);
                break;
                
            default:
                result.notImplemented();
                break;
        }
    }


    private void openUrl(MethodCall call, MethodChannel.Result result, int instance) {
        boolean hidden = call.argument("hidden");
        String url = call.argument("url");
        String userAgent = call.argument("userAgent");
        boolean withJavascript = call.argument("withJavascript");
        boolean clearCache = call.argument("clearCache");
        boolean clearCookies = call.argument("clearCookies");
        ArrayList<String> cookies = call.argument("cookies");
        ArrayList<String> permissions = call.argument("permissions");
        boolean withZoom = call.argument("withZoom");
        boolean withLocalStorage = call.argument("withLocalStorage");
        boolean supportMultipleWindows = call.argument("supportMultipleWindows");
        boolean appCacheEnabled = call.argument("appCacheEnabled");
        Map<String, String> headers = call.argument("headers");
        boolean scrollBar = call.argument("scrollBar");
        boolean allowFileURLs = call.argument("allowFileURLs");
        boolean useWideViewPort = call.argument("useWideViewPort");
        String invalidUrlRegex = call.argument("invalidUrlRegex");
        boolean geolocationEnabled = call.argument("geolocationEnabled");
        
        if (webViewManagers[instance] == null || webViewManagers[instance].closed == true) {
            webViewManagers[instance] = new WebviewManager(activity, context, registrar);
        }

        FrameLayout.LayoutParams params = buildLayoutParams(call);

        activity.addContentView(webViewManagers[instance].webView, params);

        webViewManagers[instance].openUrl(withJavascript,
                clearCache,
                hidden,
                clearCookies,
                cookies,
                userAgent,
                url,
                headers,
                withZoom,
                withLocalStorage,
                scrollBar,
                supportMultipleWindows,
                appCacheEnabled,
                allowFileURLs,
                useWideViewPort,
                invalidUrlRegex,
                geolocationEnabled,
                permissions
        );
        result.success(null);
    }

    private FrameLayout.LayoutParams buildLayoutParams(MethodCall call) {
        Map<String, Number> rc = call.argument("rect");
        FrameLayout.LayoutParams params;
        if (rc != null) {
            params = new FrameLayout.LayoutParams(
                    dp2px(activity, rc.get("width").intValue()), dp2px(activity, rc.get("height").intValue()));
            params.setMargins(dp2px(activity, rc.get("left").intValue()), dp2px(activity, rc.get("top").intValue()),
                    0, 0);
        } else {
            Display display = activity.getWindowManager().getDefaultDisplay();
            Point size = new Point();
            display.getSize(size);
            int width = size.x;
            int height = size.y;
            params = new FrameLayout.LayoutParams(width, height);
        }

        return params;
    }

    private void stopLoading(MethodCall call, MethodChannel.Result result, int instance) {
        if (webViewManagers[instance] != null) {
            webViewManagers[instance].stopLoading(call, result);
        }
        result.success(null);
    }

    private void close(MethodCall call, MethodChannel.Result result, int instance) {
        if (webViewManagers[instance] != null) {
            webViewManagers[instance].close(call, result);
            webViewManagers[instance] = null;
        }
    }

    /**
     * Navigates back on the Webview.
     */
    private void back(MethodCall call, MethodChannel.Result result, int instance) {
        if (webViewManagers[instance] != null) {
            webViewManagers[instance].back(call, result);
        }
        result.success(null);
    }

    /**
     * Navigates forward on the Webview.
     */
    private void forward(MethodCall call, MethodChannel.Result result, int instance) {
        if (webViewManagers[instance] != null) {
            webViewManagers[instance].forward(call, result);
        }
        result.success(null);
    }

    /**
     * Reloads the Webview.
     */
    private void reload(MethodCall call, MethodChannel.Result result, int instance) {
        if (webViewManagers[instance] != null) {
            webViewManagers[instance].reload(call, result);
        }
        result.success(null);
    }

    private void reloadUrl(MethodCall call, MethodChannel.Result result, int instance) {
        if (webViewManagers[instance] != null) {
            String url = call.argument("url");
            webViewManagers[instance].reloadUrl(url);
        }
        result.success(null);
    }

    private void eval(MethodCall call, final MethodChannel.Result result, int instance) {
        if (webViewManagers[instance] != null) {
            webViewManagers[instance].eval(call, result);
        }
    }

    private void resize(MethodCall call, final MethodChannel.Result result, int instance) {
        if (webViewManagers[instance] != null) {
            FrameLayout.LayoutParams params = buildLayoutParams(call);
            webViewManagers[instance].resize(params);
        }
        result.success(null);
    }

    private void hide(MethodCall call, final MethodChannel.Result result, int instance) {
        if (webViewManagers[instance] != null) {
            webViewManagers[instance].hide(call, result);
        }
        result.success(null);
    }
    private void hide2(MethodCall call, final MethodChannel.Result result, int instance) {
        if (webViewManagers[instance] != null) {
            webViewManagers[instance].hide(call, result);
        }
        result.success(null);
    }

    private void show(MethodCall call, final MethodChannel.Result result, int instance) {
        if (webViewManagers[instance] != null) {
            webViewManagers[instance].show(call, result);
        }
        result.success(null);
    }

    private void cleanCookies(MethodCall call, final MethodChannel.Result result, int instance) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            CookieManager.getInstance().removeAllCookies(new ValueCallback<Boolean>() {
                @Override
                public void onReceiveValue(Boolean aBoolean) {

                }
            });
        } else {
            CookieManager.getInstance().removeAllCookie();
        }
        result.success(null);
    }

    private int dp2px(Context context, float dp) {
        final float scale = context.getResources().getDisplayMetrics().density;
        return (int) (dp * scale + 0.5f);
    }

    @Override
    public boolean onActivityResult(int i, int i1, Intent intent) {
        if (webViewManagers[0] != null && webViewManagers[0].resultHandler != null) {
            return webViewManagers[0].resultHandler.handleResult(i, i1, intent);
        }
        return false;
    }
}
