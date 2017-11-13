package com.hekaiyou.wilddogauthexample;

import android.app.Application;

import com.wilddog.wilddogcore.WilddogApp;
import com.wilddog.wilddogcore.WilddogOptions;
import io.flutter.app.FlutterApplication;

import io.flutter.plugins.GeneratedPluginRegistrant;
import io.flutter.plugins.GeneratedPluginRegistrant;
/**
 * Created by hekaiyou on 2017/11/10.
 */

public class MyAppllication extends FlutterApplication {
    @Override
    public void onCreate() {
        super.onCreate();


        WilddogOptions options = new WilddogOptions.Builder().setSyncUrl("https://wd7039035262bkoubk.wilddogio.com/").build();
        WilddogApp.initializeApp(this, options);

    }
}
