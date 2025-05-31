import 'package:flutter/material.dart';
import 'package:frontend/network/webrtc_service.dart';

class ChannelScreen extends StatefulWidget{
  final WebRTCService webrtc;
  const ChannelScreen({super.key, required this.webrtc});

  @override
  State<ChannelScreen> createState() => _ChannelScreenState();
}

class _ChannelScreenState extends State<ChannelScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Air Chat")),
      body: Column(
        children: [
          const Expanded(
            child: Center(child: Text("Chat messages will appear here")),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Send message',
              ),
              onSubmitted: (text) {
                widget.webrtc.sendMessage(text);
              },
            ),
          ),
        ],
      ),
    );
  }
}