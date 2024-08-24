import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:rtc/controllers/login_controller.dart';
import 'package:rtc/enums/login_status.dart';

class LoginPage extends StatelessWidget {
  final LoginController loginController = Get.put(LoginController());
  final TextEditingController mobileController = TextEditingController();
  final TextEditingController nameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    // Redirect to home if already authenticated
    // if (loginController.loginStatus.value == LoginStatus.authenticated) {
    //   WidgetsBinding.instance.addPostFrameCallback((_) {
    //     Get.offAllNamed('/home');
    //   });
    // }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: mobileController,
              decoration: const InputDecoration(labelText: 'Mobile Number'),
            ),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                if (loginController.webSocketService.isConnected) {
                  await loginController.login(
                      mobileController.text, nameController.text);
                }
              },
              child: const Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}
