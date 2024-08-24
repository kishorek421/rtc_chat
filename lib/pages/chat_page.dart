import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rtc/controllers/chat_controller.dart';

class ChatPage extends StatelessWidget {
  final ChatController chatController = Get.put(ChatController());
  final String targetUserId;

  ChatPage({super.key, required this.targetUserId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat with $targetUserId'),
      ),
      body: Column(
        children: [
          Expanded(
            child: Obx(() {
              return ListView(
                children: [
                  Text('SDP: ${chatController.sdp.value}'),
                  const Text('ICE Candidates:'),
                  for (var candidate in chatController.iceCandidates)
                    Text(candidate.candidate ?? ''),
                  if (chatController.isCallActive.value)
                    Text('Call in progress with $targetUserId...'),
                ],
              );
            }),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(hintText: 'Type your message'),
                    onSubmitted: (text) {
                      chatController.sendMessage(text);
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () {
                    // Send button logic if needed
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          chatController.createConnection(targetUserId);
        },
        child: const Icon(Icons.connect_without_contact),
      ),
    );
  }
}
