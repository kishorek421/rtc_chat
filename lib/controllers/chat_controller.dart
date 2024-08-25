import 'dart:developer';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:get/get.dart';
import 'package:rtc/enums/chat_status.dart';
import 'package:rtc/services/websocket_service.dart';

class ChatController extends GetxController {
  RTCPeerConnection? peerConnection;
  RTCDataChannel? dataChannel;
  // FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  //     FlutterLocalNotificationsPlugin();
  final WebSocketService webSocketService =
      WebSocketService(); // Initialize WebSocket service
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();

  var sdp = ''.obs;
  var iceCandidates = <RTCIceCandidate>[].obs;
  var currentUserId = "";
  var targetUserId = "";

  var chatStatus = ChatStatus.calling.obs;

  @override
  void onInit() {
    super.onInit();
    // _initializeNotifications();
  }

  Future<String> fetchCurrentUserDetails() async {
    currentUserId = (await secureStorage.read(key: "userId")) ?? "";
    _initializeWebSocket(currentUserId);
    return currentUserId;
  }

  // void _initializeNotifications() {
  //   const androidSettings =
  //       AndroidInitializationSettings('@mipmap/ic_launcher');
  //   const initializationSettings =
  //       InitializationSettings(android: androidSettings);
  //   flutterLocalNotificationsPlugin.initialize(initializationSettings);
  // }

  // Initialize the WebSocket connection
  void _initializeWebSocket(String currentUserId) {
    webSocketService.connect(); // Connect to WebSocket server

    // Listen to WebSocket messages
    webSocketService.onMessage((message) {
      _handleWebSocketMessage(currentUserId, message);
    });
  }


  // This method is invoked when the user picks up the call
  void callNotify(String currentUserId, String targetUserId) async {
    chatStatus.value = ChatStatus.connected;
    final DateTime connectedTime = DateTime.now();

    // Update signaling server with the call connected status
    webSocketService.send({
      'type': 'call_notify',
      'currentUserId': currentUserId,
      'targetUserId': targetUserId,
      'connectedTime': connectedTime.toIso8601String(),
    });
  }

  // This method is invoked when the call is disconnected
  void onCallDisconnected(String currentUserId, String targetUserId) async {
    final DateTime disconnectedTime = DateTime.now();

    // Update signaling server with the call disconnected status
    webSocketService.send({
      'type': 'call_disconnected',
      'currentUserId': currentUserId,
      'targetUserId': targetUserId,
      'disconnectedTime': disconnectedTime.toIso8601String(),
    });

    // Handle any UI updates here, e.g., navigating back to the main page
    Get.back();
    Get.snackbar('Call Ended', 'The call has been disconnected.');
  }

  // This method handles call timeout, marking the call as missed
  void _handleTimeout(String targetUserId) async {
    await Future.delayed(const Duration(seconds: 20));

    if (chatStatus.value == ChatStatus.calling) {
      // isCallActive.value = false;
      // _showNotification(targetUserId, 'Missed call',
      //     'You missed a connection from $targetUserId.');

      // Update signaling server with the missed call status
      webSocketService.send({
        'type': 'missed_call',
        'currentUserId': currentUserId,
        'targetUserId': targetUserId,
      });
    }
  }

  // Handle incoming WebSocket messages
  void _handleWebSocketMessage(
      String currentUserId, Map<String, dynamic> message) {
    switch (message['type']) {
      case 'offer':
        _onOfferReceived(currentUserId, message);
        break;
      case 'answer':
        _onAnswerReceived(message);
        break;
      case 'candidate':
        _onCandidateReceived(message);
        break;
      case 'cancel':
        _onCallCanceled(message);
        break;
      case 'missed_call':
      // Handle missed call
      _handleTimeout(targetUserId);
        break;
      case 'call_accepted':
      // Handle call connected
      // onCallConnected(currentUserId, targetUserId);
        break;
      case 'call_disconnected':
      // Handle call disconnected
      onCallDisconnected(currentUserId, targetUserId);
        break;
      // Add more cases as needed
    }
  }

  Future<void> createConnection(
      String currentUserId, String targetUserId) async {
    // _showNotification(
    //     targetUserId, 'Incoming call', 'You have a connection request.');

    final configuration = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'}
      ]
    };

    peerConnection = await createPeerConnection(configuration);

    peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
      iceCandidates.add(candidate);
      _sendIceCandidate(currentUserId, targetUserId, candidate);
    };

    peerConnection!.onDataChannel = (RTCDataChannel channel) {
      dataChannel = channel;
    };

    final dataChannelConfig = RTCDataChannelInit()
      ..ordered = true
      ..maxRetransmits = 30;

    dataChannel =
        await peerConnection!.createDataChannel('chat', dataChannelConfig);

    final offer = await peerConnection!.createOffer();
    await peerConnection!.setLocalDescription(offer);
    sdp.value = offer.sdp!;

    // Send offer via WebSocket
    _sendOffer(currentUserId, targetUserId, offer.sdp!);

    _handleTimeout(targetUserId);
  }

  Future<void> setRemoteDescription(String sdp) async {
    final description = RTCSessionDescription(sdp, 'answer');
    await peerConnection!.setRemoteDescription(description);
  }

  void addIceCandidate(RTCIceCandidate candidate) {
    peerConnection!.addCandidate(candidate);
  }

  Future<void> sendMessage(String message) async {
    dataChannel!.send(RTCDataChannelMessage(message));
  }

  // Future<void> _showNotification(
  //     String title, String body, String payload) async {
  //   const androidDetails = AndroidNotificationDetails(
  //     'call_channel',
  //     'Call Notifications',
  //     channelDescription: 'Notifications for incoming calls',
  //     importance: Importance.max,
  //     priority: Priority.high,
  //   );
  //   const notificationDetails = NotificationDetails(android: androidDetails);
  //   await flutterLocalNotificationsPlugin.show(
  //     0,
  //     title,
  //     body,
  //     notificationDetails,
  //     payload: payload,
  //   );
  // }

  // Method to cancel the ongoing call
  void cancelCall(String currentUserId, String targetUserId) async {
    try {
      // Notify the signaling server to cancel the call
      webSocketService.send({
        'type': 'cancel',
        'currentUserId': currentUserId,
        'targetUserId': targetUserId,
      });

      // Handle any UI updates here, e.g., navigating back to the main page
      Get.back();
      Get.snackbar('Call Canceled', 'You have canceled the call.');
    } catch (e) {
      log('Error canceling call: $e');
      Get.snackbar('Error', 'Failed to cancel the call.');
    }
  }

// Override the onClose method to handle disconnection
  @override
  void onClose() {
    if (chatStatus.value == ChatStatus.connected) {
      onCallDisconnected(currentUserId, targetUserId);
    }
    peerConnection?.close();
    // webSocketService.disconnect(); // Close WebSocket connection
    super.onClose();
  }

  // Send offer via WebSocket
  void _sendOffer(String currentUserId, String targetUserId, String sdp) {
    webSocketService.send({
      'type': 'offer',
      'currentUserId': currentUserId,
      'targetUserId': targetUserId,
      'sdp': sdp,
    });
  }

  // Send answer via WebSocket
  void _sendAnswer(String currentUserId, String targetUserId, String sdp) {
    webSocketService.send({
      'type': 'answer',
      'currentUserId': currentUserId,
      'targetUserId': targetUserId,
      'sdp': sdp,
    });
  }

  // Send ICE candidate via WebSocket
  void _sendIceCandidate(
      String currentUserId, String targetUserId, RTCIceCandidate candidate) {
    webSocketService.send({
      'type': 'candidate',
      'currentUserId': currentUserId,
      'targetUserId': targetUserId,
      'candidate': candidate.toMap(),
    });
  }

  // Handle incoming offer
  void _onOfferReceived(
      String currentUserId, Map<String, dynamic> message) async {
    String sdp = message['sdp'];
    String fromUserId = message['from'];

    await setRemoteDescription(sdp);
    final answer = await peerConnection!.createAnswer();
    await peerConnection!.setLocalDescription(answer);

    // Send answer back to the caller
    _sendAnswer(currentUserId, fromUserId, answer.sdp!);
  }

  // Handle incoming answer
  void _onAnswerReceived(Map<String, dynamic> message) async {
    String sdp = message['sdp'];
    await setRemoteDescription(sdp);
  }

  // Handle incoming ICE candidate
  void _onCandidateReceived(Map<String, dynamic> message) async {
    RTCIceCandidate candidate = RTCIceCandidate(
      message['candidate']['candidate'],
      message['candidate']['sdpMid'],
      message['candidate']['sdpMLineIndex'],
    );
    addIceCandidate(candidate);
  }

  // Handle call cancellation
  void _onCallCanceled(Map<String, dynamic> message) {
    // isCallActive.value = false;
    Get.snackbar('Call Canceled', 'The call was canceled by the other user.');
  }
}
