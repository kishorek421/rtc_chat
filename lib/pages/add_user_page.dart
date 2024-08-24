import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rtc/controllers/user_controller.dart';

class AddUserPage extends StatelessWidget {
  final UserController userController = Get.find();
  final TextEditingController mobileController = TextEditingController();
  final TextEditingController nameController = TextEditingController();

  AddUserPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add User'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: mobileController,
              decoration: const InputDecoration(labelText: 'Target Mobile Number'),
            ),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Target Name'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // userController.addUser(mobileController.text, nameController.text);
                userController.webSocketService.send({
                  'type': 'add_target_user_details',
                  'currentUserId': userController.currentUserId,
                  'targetUserName': nameController.text,
                  'targetUserMobile': mobileController.text,
                });
                Get.back();
              },
              child: const Text('Add User'),
            ),
          ],
        ),
      ),
    );
  }
}
