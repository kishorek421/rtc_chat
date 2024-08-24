import 'dart:convert';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketService {
  final WebSocketChannel channel;

  WebSocketService(String url)
      : channel = IOWebSocketChannel.connect(Uri.parse(url));

  void send(Map<String, dynamic> data) {
    channel.sink.add(jsonEncode(data));
  }

  Stream<dynamic> get messages => channel.stream;

  void close() {
    channel.sink.close();
  }
}
