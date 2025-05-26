import 'package:flutter/material.dart';
import 'package:frontend/network/peer_discovery.dart';
import 'package:frontend/core/entities/udp_entity.dart';

import '../../../../core/entities/peer_entity.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final PeerDiscovery discovery = PeerDiscovery();
  final List<UdpSignalMessage> _peers = [];
  final Map<String, PeerInfo> _peersinfo = {};


  @override
  void initState() {
    super.initState();
    discovery.onPeerFound.listen((peer) async {
      if (!_peers.contains(peer)) {
        setState(() {
          _peersinfo[peer.id] = PeerInfo(id: peer.id, address: peer.address);
          _peers.add(peer);
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
            const Text("Discovered Peers:", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(
              child: _peers.isEmpty
                  ? const Center(child: Text('Searching for peers...'))
                  : ListView.builder(
                itemCount: _peers.length,
                itemBuilder: (context, index) {
                  return InkWell(
                    onTap: (){

                    },
                    child: ListTile(
                      leading: const Icon(Icons.wifi_tethering),
                      title: Text('Peer ID: ${_peers[index]}'),
                      subtitle: Text("Click to connect with"),
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
