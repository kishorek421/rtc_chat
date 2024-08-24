import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:get/get.dart';

class ChatController extends GetxController {
  RTCPeerConnection? peerConnection;
  RTCDataChannel? dataChannel;
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  var sdp = ''.obs;
  var iceCandidates = <RTCIceCandidate>[].obs;
  var isCallActive = false.obs;

  @override
  void onInit() {
    super.onInit();
    _initializeNotifications();
  }

  void _initializeNotifications() {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettings = InitializationSettings(android: androidSettings);
    flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> createConnection(String targetUserId) async {
    isCallActive.value = true;
    _showNotification(targetUserId, 'Incoming call', 'You have a connection request.');


    final configuration = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'}
      ]
    };

    peerConnection = await createPeerConnection(configuration);

    peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
      iceCandidates.add(candidate);
    };

    peerConnection!.onDataChannel = (RTCDataChannel channel) {
      dataChannel = channel;
    };

    final dataChannelConfig = RTCDataChannelInit()
      ..ordered = true
      ..maxRetransmits = 30;

    dataChannel = await peerConnection!.createDataChannel('chat', dataChannelConfig);

    final offer = await peerConnection!.createOffer();
    await peerConnection!.setLocalDescription(offer);
    sdp.value = offer.sdp!;

    _handleTimeout(targetUserId);
  }

  void _handleTimeout(String targetUserId) async {
    await Future.delayed(const Duration(seconds: 20));

    if (isCallActive.value) {
      isCallActive.value = false;
      _showNotification(targetUserId, 'Missed call', 'You missed a connection from $targetUserId.');
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

  Future<void> _showNotification(String title, String body, String payload) async {
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

  @override
  void onClose() {
    peerConnection?.close();
    super.onClose();
  }
}
