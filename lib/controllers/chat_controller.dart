import 'dart:convert';

import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:get/get.dart';
import 'package:rtc/controllers/common_controller.dart';
import 'package:rtc/enums/chat_status.dart';

class ChatController extends CommonController {

  var currentUserId = "";

  final chatStatus = ChatStatus.calling.obs;

  RTCPeerConnection? peerConnection;
  RTCDataChannel? dataChannel;

  // var sdp = ''.obs;
  // var iceCandidates = <RTCIceCandidate>[].obs;

  @override
  void onInit() {
    super.onInit();

    fetchCurrentUserId();
  }

  fetchCurrentUserId() async {
    currentUserId = (await secureStorage.read(key: "userId")) ?? "";
  }

  contactUser(String targetUserId) {
    webSocketService.send({
      'type': 'call_user',
      'callerId': currentUserId,
      'calleeId': targetUserId,
    });
  }

  void acceptOffer(String targetUserId, String currentUserId) {
    webSocketService.send({
      'type': 'accept_call',
      'targetUserId': targetUserId,
      'currentUserId': currentUserId,
    });
  }

  @override
  shareOffer(callDetails) async {
    final configuration = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'}
      ]
    };

    peerConnection = await createPeerConnection(configuration);

    peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
      webSocketService.send({
        'type': 'ice',
        'calleeId': callDetails['calleeId'],
        'callerId': currentUserId,
        'callId': callDetails['callId'],
        'ice': json.encode(candidate),
      });
    };

    peerConnection!.onDataChannel = (RTCDataChannel channel) {
      dataChannel = channel;
      chatStatus.value = ChatStatus.connected;
    };

    final dataChannelConfig = RTCDataChannelInit()
      ..ordered = true
      ..maxRetransmits = 30;

    dataChannel =
        await peerConnection!.createDataChannel('chat', dataChannelConfig);

    final offer = await peerConnection!.createOffer();
    await peerConnection!.setLocalDescription(offer);

    // sdp.value = offer.sdp!;

    webSocketService.send({
      'type': 'offer',
      'calleeId': callDetails['calleeId'],
      'callerId': currentUserId,
      'callId': callDetails['callId'],
      'sdp': json.encode(offer.sdp),
    });
  }

  @override
  void addIceCandidate(RTCIceCandidate candidate) {
    peerConnection!.addCandidate(candidate);
  }

  Future<void> setRemoteDescription(String sdp) async {
    final description = RTCSessionDescription(sdp, 'answer');
    await peerConnection!.setRemoteDescription(description);
  }

  @override
  void onOfferReceived( Map<String, dynamic> data) async {
    String sdp = data['sdp'];
    String callerId = data['callerId'];
    String callId = data['callId'];

    await setRemoteDescription(sdp);
    final answer = await peerConnection!.createAnswer();
    await peerConnection!.setLocalDescription(answer);

    // Send answer back to the caller
    _sendAnswer( callerId, callId, answer.sdp!);
  }

  void _sendAnswer( String callerId, String callId, String sdp) {
    webSocketService.send({
      'type': 'answer',
      'calleeId': currentUserId,
      'callerId': callerId,
      'callId': callId,
      'sdp': sdp,
    });
  }

  // Handle incoming answer
  @override
  void onAnswerReceived(Map<String, dynamic> data) async {
    String sdp = data['sdp'];
    await setRemoteDescription(sdp);
  }
}