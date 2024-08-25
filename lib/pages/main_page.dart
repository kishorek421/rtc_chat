import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rtc/enums/current_user_type.dart';
import 'package:rtc/pages/add_user_page.dart';
import 'package:rtc/controllers/user_controller.dart';
import 'package:rtc/pages/chat_page.dart';

class MainPage extends GetView<UserController> {
  MainPage({super.key}) {
    Get.put(UserController());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Obx(() {
          return Text(controller.currentUserMobileNumber.value.isEmpty
              ? "Hi User"
              : controller.currentUserMobileNumber.value);
        }),
      ),
      body: Obx(() {
        return controller.users.isEmpty
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
                itemCount: controller.users.length,
                itemBuilder: (context, index) {
                  var user = controller.users[index];
                  return ListTile(
                    title: Text(user['name']),
                    subtitle: Text(user['mobile']),
                    onTap: () {
                      // WebSocketService().sendNotification(user['userId']?.toString() ?? "");
                      Get.to(() => ChatPage(
                            targetUserId: user['userId']?.toString() ?? "",
                            targetUserMobile: user['mobile'] ?? "",
                            currentUserType: CurrentUserType.caller,
                          ));
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
