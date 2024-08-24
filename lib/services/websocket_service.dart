import 'dart:convert';
import 'dart:developer';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketService extends GetxService {
  static final WebSocketService _instance = WebSocketService._internal();
  late WebSocketChannel? _channel;
  bool isConnected = false;
  void Function(Map<String, dynamic>)? onMessageCallback;
  final String url = 'ws://106.51.106.43';
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();

  factory WebSocketService() {
    return _instance;
  }

  WebSocketService._internal();

  @override
  void onInit() {
    super.onInit();
    connect();
  }

  // Connect to the WebSocket server
  void connect() {
    if (isConnected) return; // Prevent reconnecting if already connected
    _channel = IOWebSocketChannel.connect(Uri.parse(url));
    isConnected = true;
    log("WebSocket connected");

    // Listen for incoming messages
    _channel?.stream.listen((message) {
      try {
        final decodedMessage = jsonDecode(message);
        if (onMessageCallback != null) {
          onMessageCallback!(decodedMessage);
        }
      } catch (e) {
        print('Error decoding WebSocket message: $e');
      }
    }, onError: (error) {
      print('WebSocket error: $error');
    }, onDone: () {
      print('WebSocket connection closed');
      isConnected = false;
    });

    // Update status to online
    sendStatusUpdate('online');
  }

  // Register a callback to handle incoming messages
  void onMessage(void Function(Map<String, dynamic>) callback) {
    onMessageCallback = callback;
  }

  // Send a message to the WebSocket server
  void send(Map<String, dynamic> data) {
    if (isConnected && _channel != null) {
      _channel!.sink.add(jsonEncode(data));
    } else {
      print('WebSocket channel is not connected or already closed');
    }
  }

  // Update user status (online/offline)
  void sendStatusUpdate(String status) async {
    // Assume userId is stored securely and retrieved when needed
    final userId = await secureStorage.read(key: "userId"); // Replace with actual retrieval
    send({
      'type': 'status_update',
      'userId': userId,
      'status': status,
    });
  }

  // Close the WebSocket connection and update status to offline
  void disconnect() {
    if (isConnected && _channel != null) {
      log("WebSocket service is disconnected");
      sendStatusUpdate('offline');
      _channel!.sink.close();
      isConnected = false;
    }
  }

  @override
  void onClose() {
    disconnect();
    super.onClose();
  }
}
