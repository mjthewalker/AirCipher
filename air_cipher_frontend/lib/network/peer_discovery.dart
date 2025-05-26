import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:uuid/uuid.dart';

import '../core/entities/peer_entity.dart';
import '../core/entities/udp_entity.dart';
import '../core/enums/message_type.dart';


class PeerDiscovery {
  final int port = 45678;
  final String id = const Uuid().v4();
  bool _started = false;
  RawDatagramSocket? _socket;
  final StreamController<
      UdpSignalMessage> _peerStreamController = StreamController.broadcast();

  Stream<UdpSignalMessage> get onPeerFound => _peerStreamController.stream;

  Future<void> start() async {
    if (_started) return;
    _started = true;
    _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, port);
    _socket?.broadcastEnabled = true;
    _socket?.listen((event) {
      if (event == RawSocketEvent.read) {
        final datagram = _socket?.receive();
        if (datagram == null) return;
        final msgStr = utf8.decode(datagram.data);
        final msg = UdpSignalMessage.fromJson(msgStr);
        if (msg != null && msg.id != id) {
          _peerStreamController.add(msg);
        }
      }
    });
    Timer.periodic(const Duration(seconds: 3), (_) {
      final msg = UdpSignalMessage(id: id, type: MessageType.discovery,address: InternetAddress("'255.255.255.255'") );
      _broadcast(msg);
      print("Peer discovery started on port $port with ID $id");
    });

  }
  void _broadcast(UdpSignalMessage msg) {
    final data = utf8.encode(jsonEncode(msg.toJson()));
    _socket?.send(data, InternetAddress('255.255.255.255'), port);
  }
  void sendOffer(String sdp) {
    final msg = UdpSignalMessage(id: id, type: MessageType.offer, sdp: sdp,address: InternetAddress("'255.255.255.255'"));
    _broadcast(msg);
  }

  void sendAnswer(String sdp) {
    final msg = UdpSignalMessage(id: id, type: MessageType.answer, sdp: sdp,address: InternetAddress("'255.255.255.255'"));
    _broadcast(msg);
  }

  void sendToPeer(String peerId, UdpSignalMessage message, Map<String, PeerInfo> _peers) {
    final peer = _peers[peerId];
    if (peer == null) return;
    final data = utf8.encode(jsonEncode(message.toJson()));
    _socket?.send(data, peer.address, port);
  }


  void stop() {
    _socket?.close();
    _peerStreamController.close();
  }
}