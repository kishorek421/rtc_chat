import 'dart:developer';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:rtc/pages/chat_page.dart';
import 'package:rtc/services/websocket_service.dart';
import 'package:rtc/utils/db_helper.dart';

class UserController extends GetxController {
  var users = [].obs;
  var connections = [].obs;
  final DBHelper dbHelper = DBHelper();

  final currentUserMobileNumber = "".obs;

  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();

  final WebSocketService webSocketService = WebSocketService();

  var currentUserId = "";

  var notificationReceived = false.obs;

  @override
  void onInit() {
    super.onInit();

    fetchUsers();
  }

  Future<String> fetchCurrentUserDetails() async {
    currentUserId = (await secureStorage.read(key: "userId")) ?? "";
    log("currentUserId -> $currentUserId");
    _initializeWebSocket(currentUserId);
    var mobileNumber = (await secureStorage.read(key: 'mobile')) ?? "";
    currentUserMobileNumber.value = mobileNumber;
    return mobileNumber;
  }

  // Initialize the WebSocket connection
  void _initializeWebSocket(String currentUserId) {
    webSocketService.connect(); // Connect to WebSocket server

    // Listen to WebSocket messages
    webSocketService.onMessage((message) async {
      log("message $message");
      log("currentUserId -> $currentUserId");
      if (message['type'] == 'target_user_details_added' &&
          message['success']) {
        addUser(
            message['details']['targetUserId'],
            message['details']['targetUserMobile'],
            message['details']['targetUserName']);
      }

      // if (message['type'] == 'receiveNotification' &&
      //     message['toUser'] == currentUserId) {
      //   Get.to(() => AcceptNotificationPage(fromUser: message['fromUser']));
      // }

      if (message['type'] == 'callAccepted' &&
          message['fromUser'] == currentUserId) {
        Get.to(
            () => ChatPage(targetUserId: message['toUser']?.toString() ?? ""));
      }
    });
  }

  void fetchUsers() async {
    var mobileNumber = await fetchCurrentUserDetails();
    var result = await dbHelper.getUsers(mobileNumber);
    users.assignAll(result);
  }

  Future<void> addUser(String userId, String mobile, String name) async {
    await dbHelper.addUser(userId, mobile, name);
    fetchUsers();
  }
}
