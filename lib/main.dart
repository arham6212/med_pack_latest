// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: public_member_api_docs

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:flutter_webview_pro/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

void main() => runApp(const MaterialApp(
    debugShowCheckedModeBanner: false, home: WebViewExample()));

class WebViewExample extends StatefulWidget {
  const WebViewExample({super.key});

  @override
  _WebViewExampleState createState() => _WebViewExampleState();
}

class _WebViewExampleState extends State<WebViewExample> {
  final Completer<WebViewController> _controller =
      Completer<WebViewController>();
  bool pageLoaded = false;

  @override
  void initState() {
    super.initState();
    if (Platform.isAndroid) {
      WebView.platform = SurfaceAndroidWebView();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: FutureBuilder(
          future: _controller.future,
          builder: (context, AsyncSnapshot<WebViewController> snapshot) {
            final WebViewController? controller = snapshot.data;

            return WillPopScope(
              onWillPop: () async {
                if ((await controller?.canGoBack() == true)) {
                  controller?.goBack();
                  return Future.value(false);
                } else {
                  return Future.value(false);
                }
              },
              child: SafeArea(
                child: Stack(
                  children: [
                    WebView(
                      initialUrl: 'https://4labs.medpack.helloapps.io/',
                      javascriptMode: JavascriptMode.unrestricted,
                      onWebViewCreated: (WebViewController webViewController) {
                        _controller.complete(webViewController);
                        setState(() {});
                      },
                      debuggingEnabled: true,
                      userAgent:
                          "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/80.0.3987.106 Safari/537.36",
                      onProgress: (int progress) {
                        print('WebView is loading (progress : $progress%)');
                      },
                      javascriptChannels: <JavascriptChannel>{
                        _toasterJavascriptChannel(context),
                      },
                      navigationDelegate: (NavigationRequest request) {
                        if (request.url.contains('accounts.google.com/')) {
                          FlutterWebAuth2.authenticate(
                            url: request.url,
                            callbackUrlScheme: 'myapp',
                          ).then((result) {
                            // Use authorization token to authenticate user in your app
                            // ...
                          }).catchError((error) {
                            print(error);
                          });
                          return NavigationDecision.navigate;
                        }
                        return NavigationDecision.navigate;
                      },
                      onPageStarted: (String url) {
                        setState(() {
                          pageLoaded = false;
                        });

                        debugPrint('Page started loading: $url');
                      },
                      onPageFinished: (String url) {
                        setState(() {
                          pageLoaded = true;
                        });
                        print('Page finished loading: $url');
                      },
                      gestureNavigationEnabled: true,
                      backgroundColor: const Color(0x00000000),
                      geolocationEnabled: true,
                    ),
                    !pageLoaded
                        ? const Center(
                            child: SpinKitRotatingCircle(
                              color: Colors.orange,
                              size: 50,
                            ),
                          )
                        : const SizedBox.shrink(),
                  ],
                ),
              ),
            );
          }),
    );
  }

  JavascriptChannel _toasterJavascriptChannel(BuildContext context) {
    return JavascriptChannel(
        name: 'Toaster',
        onMessageReceived: (JavascriptMessage message) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message.message)),
          );
        });
  }

}
