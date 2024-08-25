import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rtc/controllers/login_controller.dart';

class LoginPage extends StatelessWidget {
  final LoginController loginController = Get.put(LoginController());
  final TextEditingController mobileController = TextEditingController();
  final TextEditingController nameController = TextEditingController();

  LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
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
