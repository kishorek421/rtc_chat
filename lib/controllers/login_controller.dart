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
    webSocketService = WebSocketService('ws://106.51.106.43');
  }

  void checkAuthentication() async {
    var authStatus = await secureStorage.read(key: 'isAuthenticated');
    if (authStatus == 'true') {
      loginStatus.value = LoginStatus.authenticated;
      Get.offAllNamed('/home');  // Navigate to home page if authenticated
    } else {
      loginStatus.value = LoginStatus.notAuthenticated;
      Get.offAllNamed('/login'); // Navigate to login page if not authenticated
    }
  }

  Future<void> login(String mobile, String name) async {
    var user = await dbHelper.getUserByMobile(mobile);
    if (user == null) {
      await dbHelper.addUser(mobile, name);
    }
    await secureStorage.write(key: 'isAuthenticated', value: 'true');
    await secureStorage.write(key: 'mobile', value: mobile);

    webSocketService.send({
      'type': 'register',
      'mobile': mobile,
    });
    webSocketService.messages.listen((message) {
      var data = jsonDecode(message);
      if (data['type'] == 'register' && data['success']) {
        loginStatus.value = LoginStatus.authenticated;
      }
    });
  }

  Future<void> logout() async {
    await secureStorage.delete(key: 'isAuthenticated');
    await secureStorage.delete(key: 'mobile');
    loginStatus.value = LoginStatus.notAuthenticated;
    // todo if user is not setting offline automatically, call a ws to update the status
  }

  @override
  void onClose() {
    webSocketService.close();
    super.onClose();
  }
}
