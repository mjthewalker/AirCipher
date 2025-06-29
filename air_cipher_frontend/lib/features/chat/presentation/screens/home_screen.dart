import 'dart:async';
import 'package:permission_handler/permission_handler.dart';
import 'package:frontend/network/signal_service.dart';
import 'package:uuid/uuid.dart';
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
  final Map<String, PeerInfo> _availablePeers = {};
  StreamSubscription<void>? _connSub;
  Timer? _timeoutTimer;
  bool _started = false;
  bool _navigated = false;
  final peerId = const Uuid().v4();
  late final SignalService signalService;
  late final WebRTCService webrtc;
  late final PeerDiscoveryService discovery;
  String? recieverId;
  bool sent = false;

  @override
  void initState() {
    super.initState();
    signalService = SignalService(peerId);
    webrtc = WebRTCService();
    discovery = PeerDiscoveryService(webrtc);
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
    _connSub?.cancel();
    _timeoutTimer?.cancel();
    super.dispose();
  }

  void _startDiscovery() async {
    if (!_started) {
      discovery.start();
      setState(() => _started = true);
    }
    else {
      discovery.stop();
      setState(() => _started = false);
    }
  }

  void _connectToPeer(PeerInfo peer) async {
    sent = true;
    _navigated = false;
    _timeoutTimer?.cancel();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    final sdp = await webrtc.createChatOffer();
    discovery.sendOffer(sdp, peer);
    recieverId = peer.id;
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
    return Theme(
      data: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF1E1E2C),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF2D2D44),
          elevation: 0,
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('🔒 AirCipher'),
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF00C6FF), Color(0xFF0072FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Discovery button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: const StadiumBorder(),
                  elevation: 4,
                ),
                onPressed: _startDiscovery,
                child: Text(
                  _started ? '🔴 Stop Discovery' : '🟢 Start Discovery',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 20),

              // Header
              Row(
                children: const [
                  Icon(Icons.wifi_tethering, color: Colors.cyanAccent),
                  SizedBox(width: 8),
                  Text(
                    'Discovered Peers',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Peer list
              Expanded(
                child: _availablePeers.isEmpty
                    ? Center(
                  child: Text(
                    _started
                        ? 'Searching for peers…'
                        : 'Tap “Start Discovery” above',
                    style:
                    TextStyle(color: Colors.white38, fontSize: 16),
                  ),
                )
                    : ListView.builder(
                  itemCount: _availablePeers.length,
                  itemBuilder: (ctx, i) {
                    final peer = _availablePeers.values.elementAt(i);
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: InkWell(
                        onTap: () => _connectToPeer(peer),
                        borderRadius: BorderRadius.circular(12),
                        child: Ink(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF3A3F51),
                                Color(0xFF2D2F44)
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black54,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              )
                            ],
                          ),
                          child: ListTile(
                            leading: const Icon(
                              Icons.person_pin_circle,
                              color: Colors.cyanAccent,
                              size: 32,
                            ),
                            title: Text(
                              'Peer ID: ${peer.id}',
                              style: const TextStyle(color: Colors.white),
                            ),
                            subtitle: Text(
                              '${peer.address}:${peer.port}',
                              style: const TextStyle(color: Colors.white54),
                            ),
                            trailing: const Icon(
                              Icons.chevron_right,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}