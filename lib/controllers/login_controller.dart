import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:rtc/enums/login_status.dart';
import 'package:rtc/utils/db_helper.dart';
import 'package:rtc/services/websocket_service.dart';

class LoginController extends GetxController {
  final loginStatus = LoginStatus.checking.obs;
  final DBHelper dbHelper = DBHelper();
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();
  late WebSocketService webSocketService;

  @override
  void onInit() {
    super.onInit();
    webSocketService = WebSocketService();
    webSocketService.connect();
  }

  Future<void> login(String mobile, String name) async {
    // Send registration message only if WebSocket is connected
    if (webSocketService.isConnected) {
      webSocketService.send({
        'type': 'register',
        'mobile': mobile,
      });
    } else {
      print('WebSocket is not connected');
    }

    webSocketService.onMessage((message) async {
      if (message['type'] == 'registered' && message['success']) {
        var secureStorage = const FlutterSecureStorage();
        await secureStorage.write(key: 'userId', value: message['userId']);
        await secureStorage.write(key: 'isAuthenticated', value: 'true');
        await secureStorage.write(key: 'mobile', value: mobile);

        var user = await dbHelper.getUserByMobile(mobile);
        if (user == null) {
          await dbHelper.addUser(message['userId'], mobile, name);
        }
        loginStatus.value = LoginStatus.authenticated;
        Get.offAllNamed('/home');
      }
    });
  }

  Future<void> logout() async {
    await secureStorage.delete(key: 'isAuthenticated');
    await secureStorage.delete(key: 'mobile');
    await secureStorage.delete(key: 'userId');
    loginStatus.value = LoginStatus.notAuthenticated;
    // todo if user is not setting offline automatically, call a ws to update the status
  }

  @override
  void onClose() {
    // webSocketService.disconnect();
    super.onClose();
  }
}
