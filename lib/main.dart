import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rtc/pages/login_page.dart';
import 'package:rtc/pages/main_page.dart';
import 'package:rtc/pages/splash_page.dart'; // Import the splash page

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
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
