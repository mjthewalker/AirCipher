import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:uuid/uuid.dart';

class PeerDiscovery {
  final int port = 45678;
  final String id = const Uuid().v4();
  RawDatagramSocket? _socket;
  final StreamController<String> _peerStreamController = StreamController.broadcast();
  Stream<String> get onPeerFound => _peerStreamController.stream;

  Future<void> start() async{
    _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4,port);
    _socket?.broadcastEnabled = true;
    _socket?.listen((event){
      if (event == RawSocketEvent.read){
        final datagram = _socket?.receive();
        if (datagram == null) return;
        final msg = utf8.decode(datagram.data);
        final peer = jsonDecode(msg);
        if (peer['id'] != id) {
          _peerStreamController.add(peer['id']);
        }
      }
    });
    Timer.periodic(const Duration(seconds: 3),(_){
      final data = jsonEncode({'id': id});
      _socket?.send(
        utf8.encode(data),
        InternetAddress('255.255.255.255'),
        port,
      );
    });
    print("Peer discovery started on port $port with ID $id");
  }
  void stop() {
    _socket?.close();
    _peerStreamController.close();
  }

}