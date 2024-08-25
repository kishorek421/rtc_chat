import 'package:get/get.dart';
import 'package:rtc/controllers/common_controller.dart';
import 'package:rtc/enums/chat_status.dart';

class ChatController extends CommonController {

  final chatStatus = ChatStatus.calling.obs;

  contactUser(String targetUserId) {
    webSocketService.send({
      'type': 'call_user',
      'callerId': currentUserId,
      'calleeId': targetUserId,
    });
  }
}