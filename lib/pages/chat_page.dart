import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rtc/controllers/chat_controller.dart';
import 'package:rtc/enums/chat_status.dart';
import 'package:rtc/enums/current_user_type.dart';

class ChatPage extends GetView<ChatController> {
  final String callId;
  final String targetUserId;
  final String targetUserMobile;
  final CurrentUserType currentUserType;
  final TextEditingController _textController = TextEditingController();

  ChatPage({
    super.key,
    required this.callId,
    required this.targetUserId,
    required this.targetUserMobile,
    required this.currentUserType,
  }) {
    Get.put(ChatController());

    controller.targetUserId = targetUserId;

    if (controller.callId.isEmpty) {
      controller.callId = callId;
    }

    if (currentUserType == CurrentUserType.callee) {
      controller.chatStatus.value = ChatStatus.ringing;
      controller.isCaller = false;
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
        body: Obx(() {
          return _buildUI() ??
              const Center(
                child: Text("Please try again"),
              );
        }),
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Getting call from $targetUserMobile..."),
            const SizedBox(
              height: 10,
            ),
            ElevatedButton(
              onPressed: () {
                controller.acceptOffer(callId, targetUserId);
              },
              child: const Text("Accept"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatUI() {
    return Obx(() {
      return Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: controller.messages.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(controller.messages[index]),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _textController,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: () {
                    controller.sendMessage(_textController.text);
                    _textController.clear();
                  },
                ),
              ],
            ),
          ),
        ],
      );
    });
  }
}
