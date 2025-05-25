import 'package:flutter/material.dart';
import '../../../../network/peer_discovery.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final PeerDiscovery discovery = PeerDiscovery();
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
                TextButton(
                    onPressed: (){
                      discovery.start();
                    },
                    child: Text("Connect")),
                StreamBuilder(
                    stream: discovery.onPeerFound,
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return ListTile(
                          title: Text('Found peer: ${snapshot.data}'),
                        );
                      }
                      return Center(child: Text('Searching for peers...'));
                    },)
              ],
            ),
          )
        ],
      ),
    );
  }
}
