import 'dart:async';
import 'package:permission_handler/permission_handler.dart';
import 'package:frontend/network/signal_service.dart';
import 'package:uuid/uuid.dart';
import 'dart:ui';
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
  void initState()  {
    super.initState();
    _initServices();
  }
  void _initServices() async {
    signalService = await SignalService.create(peerId);
    webrtc = WebRTCService(signalService);
    discovery = PeerDiscoveryService(webrtc,signalService,peerId);

    discovery.onPeerFound.listen((peer) {
      if (!_availablePeers.containsKey(peer.id)) {
        setState(() {
          _availablePeers[peer.id] =
              PeerInfo(id: peer.id, address: peer.ip, port: peer.port);
        });
      }
    });
    discovery.onOfferReceived.listen((peerId) {
      recieverId = peerId;
    });
    _connSub = webrtc.onConnectionEstablished.listen((_) {
      if (_navigated) return;
      _navigated = true;

      _timeoutTimer?.cancel();

      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      if (recieverId != null) {
        print("not null");
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ChannelScreen(
              webrtc: webrtc,
              peerId: recieverId!)),
        );
      }

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
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
      ),
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: const Text('🔒 AirCipher'),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Discovery Button
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _started ? Colors.deepPurpleAccent : Colors.purpleAccent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    elevation: 8,
                    shadowColor: Colors.black54,
                  ),
                  onPressed: _startDiscovery,
                  child: Text(
                    _started ? '🔴 Stop Discovery' : '🟣 Start Discovery',
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Header
              Row(
                children: const [
                  Icon(Icons.wifi_tethering_rounded, color: Color(0xFFE26EE5)),
                  SizedBox(width: 10),
                  Text(
                    'Discovered Peers',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFE0E0E0),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Peer List
              Expanded(
                child: _availablePeers.isEmpty
                    ? Center(
                  child: Text(
                    _started
                        ? '🔍 Scanning nearby peers…'
                        : 'Press “Start Discovery” to begin.',
                    style: const TextStyle(color: Color(0xFF9A9A9A), fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                )
                    : ListView.builder(
                  itemCount: _availablePeers.length,
                  itemBuilder: (ctx, i) {
                    final peer = _availablePeers.values.elementAt(i);
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1F1B2E), Color(0xFF181625)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black54,
                            blurRadius: 6,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        onTap: () => _connectToPeer(peer),
                        leading: const Icon(Icons.person_pin_circle_rounded,
                            color: Color(0xFFE26EE5), size: 34),
                        title: Text(
                          'Peer ID: ${peer.id}',
                          style: const TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          '${peer.address}:${peer.port}',
                          style: const TextStyle(color: Color(0xFF9A9A9A)),
                        ),
                        trailing: const Icon(Icons.chevron_right, color: Colors.white70),
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