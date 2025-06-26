import 'package:flutter/material.dart';
import 'package:frontend/network/webrtc_service.dart';

class ChannelScreen extends StatefulWidget {
  final WebRTCService webrtc;
  const ChannelScreen({super.key, required this.webrtc});

  @override
  State<ChannelScreen> createState() => _ChannelScreenState();
}

class _ChannelScreenState extends State<ChannelScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<String> _messages = [];

  @override
  void initState() {
    super.initState();

    // Listen for incoming messages
    widget.webrtc.onMessageReceived.listen((message) {
      setState(() {
        _messages.add("📥 Peer: $message");
      });
    });
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;
    widget.webrtc.sendMessage(text,'1');
    setState(() {
      _messages.add("📤 You: $text");
    });
    _controller.clear();
  }

  @override
  void dispose() {
    _controller.dispose();
    widget.webrtc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Air Chat")),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12.0),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Align(
                    alignment: _messages[index].startsWith("📤")
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _messages[index].startsWith("📤")
                            ? Colors.blue[200]
                            : Colors.grey[300],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(_messages[index]),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Send message',
                    ),
                    onSubmitted: _sendMessage,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () => _sendMessage(_controller.text),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
