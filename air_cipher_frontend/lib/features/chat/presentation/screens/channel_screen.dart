import 'package:flutter/material.dart';
import 'package:frontend/network/webrtc_service.dart';
import 'package:flutter_emoji/flutter_emoji.dart';
import 'voice_call_screen.dart';

class ChannelScreen extends StatefulWidget {
  final WebRTCService webrtc;
  final String peerId;
  const ChannelScreen({Key? key, required this.webrtc, required this.peerId})
      : super(key: key);

  @override
  _ChannelScreenState createState() => _ChannelScreenState();
}

class _ChannelScreenState extends State<ChannelScreen> {
  final _ctrl = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<String> _msgs = [];
  bool _isTyping = false;
  final _emojiParser = EmojiParser();

  @override
  void initState() {
    super.initState();

    widget.webrtc.onMessageReceived.listen((m) {
      if (m == 'hangup') {
        if (Navigator.canPop(context)) Navigator.pop(context);
        return;
      }
      setState(() => _msgs.add('📥 Peer: $m'));
      _scrollToBottom();
    });

    widget.webrtc.onCallRequested.listen((_) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VoiceCallScreen(
            webrtc: widget.webrtc,
            isCaller: false,
            peerId: widget.peerId,
          ),
        ),
      );
    });

    widget.webrtc.onConnectionEstablished.listen((_) {});
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    Future.delayed(Duration(milliseconds: 100), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  void _sendText() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    final parsed = _emojiParser.emojify(text);
    widget.webrtc.sendMessage(parsed, widget.peerId);
    setState(() {
      _msgs.add('📤 You: $parsed');
      _isTyping = false;
    });
    _ctrl.clear();
    _scrollToBottom();
  }

  Future<void> _initiateCall() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VoiceCallScreen(
          webrtc: widget.webrtc,
          isCaller: true,
          peerId: widget.peerId,
        ),
      ),
    );
    await widget.webrtc.initiateCall();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF1E1E2C),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF2D2D44),
          elevation: 4,
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('🌙 Air Chat'),
          actions: [
            IconButton(
              icon: const Icon(Icons.lightbulb_outline),
              onPressed: () {
                // Future: Toggle theme
              },
            )
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(12),
                itemCount: _msgs.length,
                itemBuilder: (_, i) {
                  final m = _msgs[i];
                  final isSelf = m.startsWith('📤');
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    alignment:
                        isSelf ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      padding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 16),
                      decoration: BoxDecoration(
                        color: isSelf
                            ? const Color(0xFF3B82F6)
                            : const Color(0xFF374151),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        m.replaceFirst(RegExp(r'^📤 |^📥 '), ''),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (_isTyping)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: const [
                    SizedBox(width: 6),
                    Text('Peer is typing...',
                        style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: const BoxDecoration(
                color: Color(0xFF2D2D44),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black54,
                    blurRadius: 6,
                    offset: Offset(0, -2),
                  )
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.emoji_emotions_outlined,
                        color: Colors.amberAccent),
                    onPressed: () {
                      _ctrl.text += " 😄";
                      _ctrl.selection = TextSelection.fromPosition(
                        TextPosition(offset: _ctrl.text.length),
                      );
                      setState(() => _isTyping = true);
                    },
                  ),
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      onChanged: (v) =>
                          setState(() => _isTyping = v.trim().isNotEmpty),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: TextStyle(color: Colors.grey.shade500),
                        filled: true,
                        fillColor: const Color(0xFF1F2937),
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (_) => _sendText(),
                    ),
                  ),
                  const SizedBox(width: 6),
                  _circleButton(Icons.send, _sendText, Colors.blueAccent),
                  const SizedBox(width: 6),
                  _circleButton(Icons.phone, _initiateCall, Colors.greenAccent),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _circleButton(IconData icon, VoidCallback onPressed, Color color) {
    return Material(
      color: color,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Icon(icon, color: Colors.black, size: 20),
        ),
      ),
    );
  }
}
