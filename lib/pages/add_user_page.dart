import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rtc/controllers/user_controller.dart';

class AddUserPage extends StatelessWidget {
  final UserController userController = Get.find();
  final TextEditingController mobileController = TextEditingController();
  final TextEditingController nameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add User'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: mobileController,
              decoration: InputDecoration(labelText: 'Target Mobile Number'),
            ),
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: 'Target Name'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                userController.addUser(mobileController.text, nameController.text);
                Get.back();
              },
              child: Text('Add User'),
            ),
          ],
        ),
      ),
    );
  }
}
