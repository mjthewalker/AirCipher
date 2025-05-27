import 'package:flutter/material.dart';
import 'package:frontend/network/peer_discovery.dart';
import 'package:frontend/core/entities/peer_entity.dart';
import 'package:frontend/network/webrtc_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final WebRTCService webrtc = WebRTCService();
  late final PeerDiscoveryService discovery = PeerDiscoveryService(webrtc);
  final Map<String, PeerInfo> _availablePeers = {};

  @override
  void initState() {
    super.initState();
    discovery.onPeerFound.listen((peer) async {
      if (!_availablePeers.containsKey(peer.id)) {
        setState(() {
          _availablePeers[peer.id] =
              PeerInfo(id: peer.id, address: peer.ip, port: peer.port);
        });
      }
    });
  }

  bool _started = false;

  void _startDiscovery() {
    if (!_started) {
      discovery.start();
      _started = true;
    }
  }

  @override
  void dispose() {
    discovery.stop();
    super.dispose();
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
              onPressed: _startDiscovery,
              child: const Text("Start Peer Discovery"),
            ),
            const SizedBox(height: 16),
            const Text("Discovered Peers:",
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(
              child: _availablePeers.isEmpty
                  ? const Center(child: Text('Searching for peers...'))
                  : ListView.builder(
                      itemCount: _availablePeers.length,
                      itemBuilder: (context, index) {
                        final keys = _availablePeers.keys.toList();
                        final peerId = keys[index];
                        final peerInfo = _availablePeers[peerId]!;
                        return InkWell(
                          onTap: () async {
                              if (peerInfo.address!=null && peerInfo.port!=null) {
                                 final sdp = await webrtc.createOffer();
                                discovery.sendOffer(sdp,peerInfo);
                              }
                          },
                          child: Card(
                            elevation: 4,
                            child: ListTile(
                              leading: const Icon(Icons.wifi_tethering),
                              title: Text('Peer ID: $peerId'),
                              subtitle: Text("Click to connect with"),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
