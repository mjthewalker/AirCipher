import 'package:flutter/material.dart';
import 'package:frontend/network/webrtc_service.dart';
import 'dart:async';
import 'dart:ui';

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

    return Theme(
      data: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
      ),
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: const Text('🔊 Voice Call'),
          flexibleSpace: ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0x99D16BA5), Color(0x9986A8E7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.fromLTRB(16, 150, 16, 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.call,
                size: 100,
                color: Colors.greenAccent,
              ),
              const SizedBox(height: 24),
              Text(
                'On Call with ${widget.peerId}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 50),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 8,
                  shadowColor: Colors.black54,
                ),
                onPressed: () {
                  widget.webrtc.stopVoiceCall();
                  widget.webrtc.sendMessage('hangup', widget.peerId);
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.call_end),
                label: const Text(
                  'Hang Up',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
