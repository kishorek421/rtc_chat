import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rtc/pages/login_page.dart';
import 'package:rtc/pages/main_page.dart';
import 'package:rtc/pages/splash_page.dart';
import 'package:rtc/services/websocket_service.dart'; // Import the splash page

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp>  with WidgetsBindingObserver {
  final WebSocketService webSocketService =  Get.put(WebSocketService());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    webSocketService.disconnect();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      webSocketService.sendStatusUpdate('offline');
    } else if (state == AppLifecycleState.resumed) {
      webSocketService.sendStatusUpdate('online');
    }
  }
  @override
  Widget build(BuildContext context) {
    // Initialize WebSocketService when the app starts
    webSocketService.listenForNotifications(context);

    return GetMaterialApp(
      title: 'WebRTC Connections',
      initialRoute: '/', // Set the initial route to splash screen
      getPages: [
        GetPage(name: '/', page: () => SplashPage()), // Splash screen route
        GetPage(name: '/login', page: () => LoginPage()),
        GetPage(name: '/home', page: () => MainPage()),
      ],
    );
  }
}
