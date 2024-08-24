import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:get/get.dart';
import 'package:rtc/services/websocket_service.dart';

class ChatController extends GetxController {
  RTCPeerConnection? peerConnection;
  RTCDataChannel? dataChannel;
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final WebSocketService webSocketService =
      WebSocketService('ws://106.51.106.43'); // Initialize WebSocket service
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();

  var sdp = ''.obs;
  var iceCandidates = <RTCIceCandidate>[].obs;
  var isCallActive = false.obs;
  var currentUserId = "";

  @override
  void onInit() {
    super.onInit();
    _initializeNotifications();
  }

  Future<String> fetchCurrentUserDetails() async {
    currentUserId = (await secureStorage.read(key: "userId")) ?? "";
    _initializeWebSocket(currentUserId);
    return currentUserId;
  }

  void _initializeNotifications() {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettings =
        InitializationSettings(android: androidSettings);
    flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  // Initialize the WebSocket connection
  void _initializeWebSocket(String currentUserId) {
    webSocketService.connect(); // Connect to WebSocket server

    // Listen to WebSocket messages
    webSocketService.onMessage((message) {
      _handleWebSocketMessage(currentUserId, message);
    });
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
      // Add more cases as needed
    }
  }

  Future<void> createConnection(
      String currentUserId, String targetUserId) async {
    isCallActive.value = true;
    _showNotification(
        targetUserId, 'Incoming call', 'You have a connection request.');

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

  void _handleTimeout(String targetUserId) async {
    await Future.delayed(const Duration(seconds: 20));

    if (isCallActive.value) {
      isCallActive.value = false;
      _showNotification(targetUserId, 'Missed call',
          'You missed a connection from $targetUserId.');
    }
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

  Future<void> _showNotification(
      String title, String body, String payload) async {
    const androidDetails = AndroidNotificationDetails(
      'call_channel',
      'Call Notifications',
      channelDescription: 'Notifications for incoming calls',
      importance: Importance.max,
      priority: Priority.high,
    );
    const notificationDetails = NotificationDetails(android: androidDetails);
    await flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  // Method to cancel the ongoing call
  void cancelCall(String currentUserId, String targetUserId) async {
    try {
      // Notify the signaling server to cancel the call
      webSocketService.send({
        'type': 'cancel',
        'from': currentUserId,
        'to': targetUserId,
      });

      // Handle any UI updates here, e.g., navigating back to the main page
      Get.back();
      Get.snackbar('Call Canceled', 'You have canceled the call.');
    } catch (e) {
      print('Error canceling call: $e');
      Get.snackbar('Error', 'Failed to cancel the call.');
    }
  }

  @override
  void onClose() {
    peerConnection?.close();
    webSocketService.disconnect(); // Close WebSocket connection
    super.onClose();
  }

  // Send offer via WebSocket
  void _sendOffer(String currentUserId, String targetUserId, String sdp) {
    webSocketService.send({
      'type': 'offer',
      'from': currentUserId,
      'to': targetUserId,
      'sdp': sdp,
    });
  }

  // Send answer via WebSocket
  void _sendAnswer(String currentUserId, String targetUserId, String sdp) {
    webSocketService.send({
      'type': 'answer',
      'from': currentUserId,
      'to': targetUserId,
      'sdp': sdp,
    });
  }

  // Send ICE candidate via WebSocket
  void _sendIceCandidate(
      String currentUserId, String targetUserId, RTCIceCandidate candidate) {
    webSocketService.send({
      'type': 'candidate',
      'from': currentUserId,
      'to': targetUserId,
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
    isCallActive.value = false;
    Get.snackbar('Call Canceled', 'The call was canceled by the other user.');
  }
}
