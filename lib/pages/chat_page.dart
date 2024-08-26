import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rtc/controllers/chat_controller.dart';
import 'package:rtc/enums/chat_status.dart';
import 'package:rtc/enums/current_user_type.dart';

class ChatPage extends GetView<ChatController> {
  final String targetUserId;
  final String targetUserMobile;
  final CurrentUserType currentUserType;

  ChatPage({
    super.key,
    required this.targetUserId,
    required this.targetUserMobile,
    required this.currentUserType,
  }) {
    Get.put(ChatController());

    if (currentUserType == CurrentUserType.callee) {
      controller.chatStatus.value = ChatStatus.ringing;
    } else {
      controller.contactUser(targetUserId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text(targetUserMobile),
        ),
        body: _buildUI() ??
            const Center(
              child: Text("Please try again"),
            ),
      ),
    );
  }

  Widget? _buildUI() {
    switch (controller.chatStatus.value) {
      case ChatStatus.calling:
        return _buildCallingUI();
      case ChatStatus.ringing:
        return _buildRingingUI();
      case ChatStatus.connected:
        return _buildChatUI();
      default:
        return null;
    }
  }

  Widget _buildCallingUI() {
    return SizedBox(
      height: double.infinity,
      child: Center(
        child: Text("Calling $targetUserMobile..."),
      ),
    );
  }

  Widget _buildRingingUI() {
    return SizedBox(
      height: double.infinity,
      child: Center(
        child: Text("Getting call from $targetUserMobile..."),
      ),
    );
  }

  Widget _buildChatUI() {
    return Text("Chat UI");
  }
}
