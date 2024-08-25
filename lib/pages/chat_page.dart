import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rtc/controllers/chat_controller.dart';
import 'package:rtc/enums/chat_status.dart';

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
    chatController.targetUserId = widget.targetUserId;
    // Initiate the connection when the screen is opened
    chatController.fetchCurrentUserDetails().then((value) {
      log("currentUserId => $value");
      // chatController.createConnection(value, widget.targetUserId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Obx(() {
          return Text(chatController.chatStatus.value == ChatStatus.calling
              ? 'Calling ${widget.targetUserId}...'
              : chatController.chatStatus.value == ChatStatus.connected
                  ? 'Chat with ${widget.targetUserId}'
                  : 'Disconnected');
        }),
      ),
      body: Obx(() {
        if (chatController.chatStatus.value == ChatStatus.calling) {
          return _buildCallingUI();
        } else if (chatController.chatStatus.value == ChatStatus.connected) {
          return _buildChatUI();
        } else {
          return _buildDisconnectedUI();
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

  Widget _buildDisconnectedUI() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('The call has been disconnected.'),
          ElevatedButton(
            onPressed: () {
              Get.back();
            },
            child: const Text('Back to Main Page'),
          ),
        ],
      ),
    );
  }

  Widget _buildChatUI() {
    return Column(
      children: [
        // Expanded(
        //   child: Obx(() {
        //     return ListView(
        //       children: [
        //         Text('SDP: ${chatController.sdp.value}'),
        //         const Text('ICE Candidates:'),
        //         for (var candidate in chatController.iceCandidates)
        //           Text(candidate.candidate ?? ''),
        //         if (chatController.chatStatus.value == ChatStatus.calling)
        //           Text('Call in progress with ${widget.targetUserId}...'),
        //       ],
        //     );
        //   }),
        // ),
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
