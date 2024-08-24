import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rtc/pages/chat_page.dart';
import 'package:rtc/services/websocket_service.dart';

class AcceptNotificationPage extends StatelessWidget {

  final String fromUser;

  AcceptNotificationPage({super.key, required this.fromUser});

  final WebSocketService webSocketService = WebSocketService();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Decline'),
              ),
              TextButton(
                onPressed: () {
                  webSocketService.acceptOffer(fromUser);
                  Get.back();
                  Get.to(() => ChatPage(targetUserId: fromUser));
                  // Accept the offer

                  // _acceptOffer(fromUser);
                  // Navigator.pop(context);
                  // Navigator.pushNamed(context, '/chatPage', arguments: fromUser);
                },
                child: Text('Accept'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
