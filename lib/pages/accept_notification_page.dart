import 'package:flutter/material.dart';

class AcceptNotificationPage extends StatelessWidget {
  const AcceptNotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Decline'),
          ),
          TextButton(
            onPressed: () {
              // Accept the offer

              // _acceptOffer(fromUser);
              // Navigator.pop(context);
              // Navigator.pushNamed(context, '/chatPage', arguments: fromUser);
            },
            child: Text('Accept'),
          ),
        ],
      ),
    );
  }
}
