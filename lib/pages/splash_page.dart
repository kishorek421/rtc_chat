import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rtc/controllers/login_controller.dart';

class SplashPage extends StatelessWidget {
  final LoginController loginController = Get.put(LoginController());

  SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Perform authentication check when splash screen is shown
    loginController.checkAuthentication();

    return const Scaffold(
      body: Center(
        child:
            CircularProgressIndicator(), // Show a loading spinner while checking
      ),
    );
  }
}
