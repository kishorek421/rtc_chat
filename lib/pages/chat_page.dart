import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rtc/controllers/chat_controller.dart';

class ChatPage extends StatefulWidget {
  final String targetUserId;

  const ChatPage({super.key, required this.targetUserId});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final ChatController chatController = Get.put(ChatController());

  @override
  void initState() {
    super.initState();
    // Initiate the connection when the screen is opened
    chatController.fetchCurrentUserDetails().then((value) {
      log("currentUserId => $value");
      chatController.createConnection(value, widget.targetUserId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Obx(() {
          return Text(chatController.isCallActive.value
              ? 'Chat with ${widget.targetUserId}'
              : 'Calling ${widget.targetUserId}...');
        }),
      ),
      body: Obx(() {
        if (!chatController.isCallActive.value) {
          return _buildCallingUI();
        } else {
          return _buildChatUI();
        }
      }),
    );
  }

  Widget _buildCallingUI() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 20),
          Text('Waiting for ${widget.targetUserId} to answer...'),
          ElevatedButton(
            onPressed: () {
              chatController.cancelCall(
                  chatController.currentUserId, widget.targetUserId);
              Get.back();
            },
            child: const Text('Cancel Call'),
          ),
        ],
      ),
    );
  }

  Widget _buildChatUI() {
    return Column(
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
                  Text('Call in progress with ${widget.targetUserId}...'),
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
                  decoration:
                      const InputDecoration(hintText: 'Type your message'),
                  onSubmitted: (text) {
                    chatController.sendMessage(text);
                  },
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send),
                onPressed: () {
                  // You can implement any additional logic if needed when the send button is pressed
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
