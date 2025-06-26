import 'dart:async';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:frontend/network/peer_discovery.dart';
import 'package:frontend/core/entities/peer_entity.dart';
import 'package:frontend/network/webrtc_service.dart';
import 'package:frontend/features/chat/presentation/screens/channel_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final WebRTCService webrtc = WebRTCService();
  late final PeerDiscoveryService discovery = PeerDiscoveryService(webrtc);

  final Map<String, PeerInfo> _availablePeers = {};
  StreamSubscription<void>? _connSub;
  Timer? _timeoutTimer;
  bool _started = false;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();

    discovery.onPeerFound.listen((peer) {
      if (!_availablePeers.containsKey(peer.id)) {
        setState(() {
          _availablePeers[peer.id] =
              PeerInfo(id: peer.id, address: peer.ip, port: peer.port);
        });
      }
    });


    _connSub = webrtc.onConnectionEstablished.listen((_) {
      if (_navigated) return;
      _navigated = true;

      _timeoutTimer?.cancel();

      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ChannelScreen(webrtc: webrtc)),
      );
    });
  }

  @override
  void dispose() {
    discovery.stop();
    _connSub?.cancel();
    _timeoutTimer?.cancel();
    super.dispose();
  }

  void _startDiscovery() async {
    final status = await Permission.location.status;
    if (!status.isGranted) {
      final result = await Permission.location.request();
      if (!result.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission is required.')),
        );
        return;
      }
    }
    if (!_started) {
      discovery.start();
      setState(() => _started = true);
    }
  }

  void _connectToPeer(PeerInfo peer) async {
    // Reset state
    _navigated = false;
    _timeoutTimer?.cancel();

    // Show spinner
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    // Send the offer
    final sdp = await webrtc.createOffer();
    discovery.sendOffer(sdp, peer);

    _timeoutTimer = Timer(const Duration(seconds: 15), () {
      if (!_navigated && mounted) {

        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Connection timed out. Try again.")),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("AirCipher")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _started ? null : _startDiscovery,
              child: Text(_started ? "Discovery Started" : "Start Peer Discovery"),
            ),
            const SizedBox(height: 16),
            const Text(
              "Discovered Peers:",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _availablePeers.isEmpty
                  ? const Center(child: Text('Searching for peers...'))
                  : ListView(
                children: _availablePeers.entries.map((e) {
                  final peerId = e.key;
                  final info = e.value;
                  return Card(
                    elevation: 4,
                    child: ListTile(
                      leading: const Icon(Icons.wifi_tethering),
                      title: Text('Peer ID: $peerId'),
                      subtitle: const Text('Tap to connect'),
                      onTap: () => _connectToPeer(info),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
