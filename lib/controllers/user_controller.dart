import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:rtc/utils/db_helper.dart';

class UserController extends GetxController {
  var users = [].obs;
  var connections = [].obs;
  final DBHelper dbHelper = DBHelper();

  final currentUserMobileNumber = "".obs;

  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();


  @override
  void onInit() {
    super.onInit();

    fetchUsers();
  }

  Future<String> fetchCurrentUserDetails() async {
    var mobileNumber = (await secureStorage.read(key: 'mobile')) ?? "";
    currentUserMobileNumber.value = mobileNumber;
    return mobileNumber;
  }

  void fetchUsers() async {
    var mobileNumber = await fetchCurrentUserDetails();
    var result = await dbHelper.getUsers(mobileNumber);
    users.assignAll(result);
  }

  void fetchConnections(int userId) async {
    var result = await dbHelper.getConnections(userId);
    connections.assignAll(result);
  }

  Future<void> addUser(String mobile, String name) async {
    await dbHelper.addUser(mobile, name);
    fetchUsers();
  }

  Future<void> addConnection(int userId, String targetMobile, String targetName) async {
    await dbHelper.addConnection(userId, targetMobile, targetName);
    fetchConnections(userId);
  }
}
