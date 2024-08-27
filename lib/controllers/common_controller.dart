import 'dart:convert';
import 'dart:developer';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:get/get.dart';
import 'package:rtc/services/websocket_service.dart';
import 'package:rtc/utils/db_helper.dart';

abstract class CommonController extends GetxController {
  var currentUserMobileNumber = "".obs;

  WebSocketService webSocketService = WebSocketService();

  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();

  final DBHelper dbHelper = DBHelper();

  @override
  void onInit() {
    super.onInit();

    fetchCurrentUserMobileNo();
  }

  Future<String> fetchCurrentUserMobileNo() async {
    initializeWebSocket();
    var mobileNumber = (await secureStorage.read(key: 'mobile')) ?? "";
    currentUserMobileNumber.value = mobileNumber;
    return mobileNumber;
  }

  // Initialize the WebSocket connection
  void initializeWebSocket() {
    // Connect to WebSocket server
    webSocketService.connect();

    // Listen to WebSocket messages
    webSocketService.onMessage((message) {
      _handleMessage(message);
    });
  }

  void _handleMessage(data) {
    switch (data['type']) {
      case "user_contact_added":
        if (data['success']) {
          addUserToLocalDB(
              data['details']['targetUserId'],
              data['details']['targetUserMobile'],
              data['details']['targetUserName']);
        }
        break;
      case "call_initiated":
        log("Incoming Call");
        if (data['success']) {
          notifyCallInitiated(data);
        }
        break;
      case "incoming_call":
        log("Incoming Call");
        if (data['success']) {
          ringUser(data['details']);
        }
        break;
      case "call_accepted":
        log("Call Accepted");
        if (data['success']) {
          shareOffer(data);
        }
        break;
      case "offer":
        log("received offer $data");
        if (data['success']) {
          onOfferReceived(data);
        }
        break;
      case "answer":
        log("received answer $data");
        if (data['success']) {
          onAnswerReceived(data);
        }
        break;
      case "ice":
        log("received ice $data");
        if (data['success']) {
          // var ice = json.decode(data['ice']);
          var ice = data['ice'];
          RTCIceCandidate candidate = RTCIceCandidate(
            ice['candidate'],
            ice['sdpMid'],
            ice['sdpMLineIndex'],
          );
          addIceCandidate(candidate);
        }
        break;
      case "reconnect":
        reconnect();
        break;
    }
  }

  Future<void> addUserToLocalDB(
      String userId, String mobile, String name) async {
    await dbHelper.addUser(userId, mobile, name);
    fetchUsers();
  }

  void reconnect() {}

  void notifyCallInitiated(data) {}

  void fetchUsers() {}

  void ringUser(userDetails) {}

  shareOffer(callDetails) async {}

  void addIceCandidate(RTCIceCandidate candidate) {}

  void onOfferReceived(Map<String, dynamic> data) async {}

  void onAnswerReceived(Map<String, dynamic> data) async {}
}
