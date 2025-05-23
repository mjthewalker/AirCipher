import 'package:flutter/material.dart';
import 'package:frontend/core/grpc_client.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final client = ChatClient();

  @override
  void initState() {
    super.initState();
    client.init();
  }

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    await client.sendMessage("phone_1", "phone_2", text);
    _controller.clear();
  }

  @override
  void dispose() {
    client.shutdown();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("AirCipher")),
      body: Column(
        children: [
          const SizedBox(height: 200,),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(child: TextField(controller: _controller)),
                IconButton(onPressed: _sendMessage, icon: Icon(Icons.send)),
              ],
            ),
          )
        ],
      ),
    );
  }
}
