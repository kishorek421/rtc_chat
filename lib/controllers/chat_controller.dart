import 'dart:convert';

import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'dart:developer';

import 'package:get/get.dart';
import 'package:rtc/controllers/common_controller.dart';
import 'package:rtc/enums/chat_status.dart';

class ChatController extends CommonController {
  var currentUserId = "";

  final chatStatus = ChatStatus.calling.obs;

  RTCPeerConnection? peerConnection;
  RTCDataChannel? dataChannel;

  @override
  onInit() async {
    final configuration = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'}
      ]
    };

    peerConnection = await createPeerConnection(configuration);

    super.onInit();
  }

  // var sdp = ''.obs;
  // var iceCandidates = <RTCIceCandidate>[].obs;

  fetchCurrentUserId() async {
    currentUserId = (await secureStorage.read(key: "userId")) ?? "";
    log("fetchCurrentUserId :: currentUserId -> $currentUserId");
  }

  contactUser(String targetUserId) async {
    log("currentUserId -> $currentUserId");
    if (currentUserId.isEmpty) {
      await fetchCurrentUserId();
    }
    webSocketService.send({
      'type': 'call_user',
      'callerId': currentUserId,
      'calleeId': targetUserId,
    });
  }

  void acceptOffer(String callId, String targetUserId) {
    webSocketService.send({
      'type': 'accept_call',
      'callId': callId,
      'callerId': targetUserId,
      'calleeId': currentUserId,
    });
  }

  @override
  shareOffer(callDetails) async {
    peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
      if (chatStatus.value == ChatStatus.calling) {
        webSocketService.send({
          'type': 'ice',
          'calleeId': callDetails['calleeId'],
          'callerId': currentUserId,
          'callId': callDetails['callId'],
          // 'ice': json.encode(candidate.toMap()),
          'ice': candidate.toMap(),
          'iceUser': 'caller',
        });
      } else {
        webSocketService.send({
          'type': 'ice',
          'calleeId': currentUserId,
          'callerId': callDetails['callerId'],
          'callId': callDetails['callId'],
          // 'ice': json.encode(candidate.toMap()),
          'ice': candidate.toMap(),
          'iceUser': 'callee',
        });
      }
    };

    peerConnection!.onDataChannel = (RTCDataChannel channel) {
      dataChannel = channel;
      chatStatus.value = ChatStatus.connected;
      log("Data channel is open");
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
      // 'sdp': json.encode(offer.toMap()),
      'sdp': offer.toMap(),
    });
  }

  @override
  void addIceCandidate(RTCIceCandidate candidate) {
    log("adding ice");
    peerConnection!.addCandidate(candidate);
  }

  Future<void> setRemoteDescription(Map<String, dynamic> data) async {
    // var sdp = json.decode(data['sdp']);
    var sdp = data['sdp'];
    log("setting ${data['type']}");
    final description = RTCSessionDescription(sdp['sdp'], sdp['type']);
    await peerConnection!.setRemoteDescription(description);
  }

  @override
  void onOfferReceived(Map<String, dynamic> data) async {
    String callerId = data['callerId'];
    String callId = data['callId'];

    await setRemoteDescription(data);
    final answer = await peerConnection!.createAnswer();
    await peerConnection!.setLocalDescription(answer);

    // Send answer back to the caller
    // _sendAnswer( callerId, callId, json.encode(answer.toMap()));
    _sendAnswer(callerId, callId, answer.toMap());
  }

  void _sendAnswer(String callerId, String callId, Map<String, dynamic> sdp) {
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
    await setRemoteDescription(data);
  }
}
