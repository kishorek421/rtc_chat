import 'package:get/get.dart';
import 'package:rtc/controllers/common_controller.dart';
import 'package:rtc/enums/chat_status.dart';

class ChatController extends CommonController {

  var currentUserId = "";

  final chatStatus = ChatStatus.calling.obs;

  @override
  void onInit() {
    super.onInit();

    fetchCurrentUserId();
  }

  fetchCurrentUserId() async {
    currentUserId = (await secureStorage.read(key: "userId")) ?? "";
  }

  contactUser(String targetUserId) {
    webSocketService.send({
      'type': 'call_user',
      'callerId': currentUserId,
      'calleeId': targetUserId,
    });
  }
}