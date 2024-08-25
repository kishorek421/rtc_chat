import 'dart:developer';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:rtc/services/websocket_service.dart';
import 'package:rtc/utils/db_helper.dart';

abstract class CommonController extends GetxController {
  var currentUserId = "";
  var currentUserMobileNumber = "".obs;

  WebSocketService webSocketService = WebSocketService();

  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();

  final DBHelper dbHelper = DBHelper();

  @override
  void onInit() {
    super.onInit();

    fetchCurrentUserDetails();
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
    // Connect to WebSocket server
    webSocketService.connect();

    // Listen to WebSocket messages
    webSocketService.onMessage((message) async {
      log("message $message");
      log("currentUserId -> $currentUserId");
      _handleMessage(message);
    });
  }

  void _handleMessage(data) {
    switch (data['type']) {
      case "user_contact_added":
        if (data['success']) {
          addUserToLocalDB(
              data['details']['targetUserId'],
              data['details']['targetUserMobile'],
              data['details']['targetUserName']);
        }
        break;
      case "incoming_call":
        if (data['success']) {
          ringUser(data['details']);
        }
        break;
    }
  }

  Future<void> addUserToLocalDB(
      String userId, String mobile, String name) async {
    await dbHelper.addUser(userId, mobile, name);
    fetchUsers();
  }

  void fetchUsers() {}

  void ringUser(user) {}
}
