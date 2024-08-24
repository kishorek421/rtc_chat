import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rtc/pages/add_user_page.dart';
import 'package:rtc/pages/chat_page.dart';
import 'package:rtc/controllers/user_controller.dart';

class MainPage extends StatelessWidget {
  final UserController userController = Get.put(UserController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Obx(() {
          return Text(userController.currentUserMobileNumber.value.isEmpty
              ? "Hi User"
              : userController.currentUserMobileNumber.value);
        }),
      ),
      body: Obx(() {
        return userController.users.isEmpty
            ? const SizedBox(
                height: double.infinity,
                child: Center(
                  child: Text(
                    "Users list is empty",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            : ListView.builder(
                shrinkWrap: true,
                itemCount: userController.users.length,
                itemBuilder: (context, index) {
                  var user = userController.users[index];
                  return ListTile(
                    title: Text(user['name']),
                    subtitle: Text(user['mobile']),
                    onTap: () {
                      userController.fetchConnections(user['id']);
                      Get.to(() =>
                          ChatPage(targetUserId: user['id']?.toString() ?? ""));
                    },
                  );
                },
              );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Get.to(() => AddUserPage());
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

/*class ConnectionPage extends StatelessWidget {
  final int userId;
  final String userName;

  ConnectionPage(this.userId, this.userName);

  @override
  Widget build(BuildContext context) {
    final UserController userController = Get.find();
    return Scaffold(
      appBar: AppBar(
        title: Text('$userName\'s Connections'),
      ),
      body: Obx(() {
        return ListView.builder(
          itemCount: userController.connections.length,
          itemBuilder: (context, index) {
            var connection = userController.connections[index];
            return ListTile(
              title: Text(connection['targetName']),
              subtitle: Text(connection['targetMobile']),
            );
          },
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Get.to(() => AddConnectionPage(userId));
        },
        child: Icon(Icons.add),
      ),
    );
  }
}*/
