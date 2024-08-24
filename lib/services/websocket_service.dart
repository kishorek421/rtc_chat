import 'dart:convert';
import 'dart:developer';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketService {
  final String url;
  WebSocketChannel? _channel;
  bool isConnected = false;
  void Function(Map<String, dynamic>)? onMessageCallback;

  WebSocketService(this.url);

  // Connect to the WebSocket server
  void connect() {
    _channel = IOWebSocketChannel.connect(Uri.parse(url));
    isConnected = true;

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

  // Close the WebSocket connection
  void disconnect() {
    if (isConnected && _channel != null) {
      log("Websocket service is disconnected");
      _channel!.sink.close();
      isConnected = false;
    }
  }
}
