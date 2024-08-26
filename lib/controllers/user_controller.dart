import 'dart:developer';

import 'package:get/get.dart';
import 'package:rtc/controllers/common_controller.dart';
import 'package:rtc/enums/current_user_type.dart';
import 'package:rtc/pages/chat_page.dart';

class UserController extends CommonController {
  var users = [].obs;

  var currentUserId = "";

  @override
  void onInit() {
    super.onInit();

    fetchUsers();
  }

  fetchCurrentUserId() async {
    currentUserId = (await secureStorage.read(key: "userId")) ?? "";
  }

  @override
  void fetchUsers() async {
    log("method calling");
    var mobileNumber = await fetchCurrentUserMobileNo();
    var result = await dbHelper.getUsers(mobileNumber);
    users.assignAll(result);
  }

  @override
  void ringUser(user) {
    Get.to(() => ChatPage(
      targetUserId: user['callerId']?.toString() ?? "",
      targetUserMobile: user['callerMobile'] ?? "",
      currentUserType: CurrentUserType.callee,
    ));
  }
}
