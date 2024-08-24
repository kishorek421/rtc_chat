import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:rtc/enums/login_status.dart';

class SplashController extends GetxController {

  final loginStatus = LoginStatus.checking.obs;

  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();

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
}