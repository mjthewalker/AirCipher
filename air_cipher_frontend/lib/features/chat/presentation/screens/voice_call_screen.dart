import 'package:flutter/material.dart';
import 'package:frontend/network/webrtc_service.dart';
import 'dart:async';
class VoiceCallScreen extends StatefulWidget {
  final WebRTCService webrtc;
  final bool isCaller;
  final String peerId;

  const VoiceCallScreen({
    Key? key,
    required this.webrtc,
    required this.isCaller,
    required this.peerId,
  }) : super(key: key);

  @override
  _VoiceCallScreenState createState() => _VoiceCallScreenState();
}

class _VoiceCallScreenState extends State<VoiceCallScreen> {
  bool _connected = false;
  late final StreamSubscription _connectionSub;

  @override
  void initState() {
    super.initState();
    _connectionSub = widget.webrtc.onConnectionEstablished.listen((_) {
      if (mounted) {
        setState(() => _connected = true);
      }
    });
  }

  @override
  void dispose() {
    _connectionSub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      appBar: AppBar(
        backgroundColor: isDark ? Colors.grey[900] : null,
        title: const Text('Voice Call'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              widget.isCaller
                  ? (_connected ? Icons.call_end : Icons.call)
                  : (_connected ? Icons.call : Icons.call_received),
              size: 100,
              color: _connected ? Colors.green : Colors.red,
            ),
            const SizedBox(height: 20),
            Text(
              _connected
                  ? 'You are now connected'
                  : (widget.isCaller ? 'Calling...' : 'Incoming call'),
              style: theme.textTheme.titleLarge!
                  .copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.call_end),
              label: const Text('Hang Up'),
              onPressed: () {
                widget.webrtc.stopVoiceCall();
                widget.webrtc.sendMessage('hangup',widget.peerId);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
