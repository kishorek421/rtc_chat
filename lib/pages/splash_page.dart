import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rtc/controllers/login_controller.dart';
import 'package:rtc/controllers/splash_controller.dart';

class SplashPage extends GetView<SplashController> {
  SplashPage({super.key}) {
    Get.put(SplashController());
    // Perform authentication check when splash screen is shown
    controller.checkAuthentication();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child:
            CircularProgressIndicator(), // Show a loading spinner while checking
      ),
    );
  }
}
