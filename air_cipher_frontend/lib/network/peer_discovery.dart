//Imports
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:frontend/network/webrtc_service.dart';
import 'package:uuid/uuid.dart';
import 'package:frontend/core/entities/peer_entity.dart';
import 'package:frontend/core/entities/udp_entity.dart';
import 'package:frontend/core/enums/message_type.dart';


class PeerDiscoveryService {

  final int port = 45678;
  final String id = const Uuid().v4();
  bool _started = false;
  RawDatagramSocket? _socket;
  final WebRTCService webRTCService;
  PeerDiscoveryService(this.webRTCService);
  final StreamController<UdpSignalMessage> _peerStreamController =
      StreamController.broadcast();
  Stream<UdpSignalMessage> get onPeerFound => _peerStreamController.stream;


  Future<void> start() async {
    if (_started) return;
    _started = true;
    _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, port);
    _socket?.broadcastEnabled = true;
    _socket?.listen((event) async {
      if (event == RawSocketEvent.read) {
        final datagram = _socket?.receive();
        if (datagram == null) return;
        final msgStr = utf8.decode(datagram.data);
        final msg = UdpSignalMessage.fromJson(msgStr);
        msg?.ip = datagram.address;
        msg?.port = datagram.port;
        if (msg != null && msg.id != id ) {
          switch (msg.type) {
            case MessageType.discovery:
              _peerStreamController.add(msg);
              break;
            case MessageType.offer:
              final answer = await webRTCService.createAnswer(msg.sdp!);
              sendAnswer(answer,PeerInfo(id: id,address: msg.ip,port: msg.port));
              break;
            case MessageType.answer:
              await webRTCService.setRemoteAnswer(msg.sdp!);
              break;
          }
        }

      }
    });

    final msg = UdpSignalMessage(id: id, type: MessageType.discovery);
      _broadcast(msg);
      print("Peer discovery started on port $port with ID $id");

  }

  void _broadcast(UdpSignalMessage msg) {
    final data = utf8.encode(jsonEncode(msg.toJson()));
    final msgStatus = _socket?.send(data, InternetAddress('255.255.255.255'), port);
    print("$msgStatus bytes sent");
  }

  void sendOffer(String sdp,PeerInfo peer) {
    final msg = UdpSignalMessage(
        id: id,
        type: MessageType.offer,
        sdp: sdp,);
    final data = utf8.encode(jsonEncode(msg.toJson()));
    _socket?.send(data,peer.address!,peer.port!);
  }

  void sendAnswer(String sdp,PeerInfo peer) {
    final msg = UdpSignalMessage(
        id: id,
        type: MessageType.answer,
        sdp: sdp,
    );
    final data = utf8.encode(jsonEncode(msg.toJson()));
    _socket?.send(data,peer.address!,peer.port!);
  }
  void stop() {
    _socket?.close();
    _peerStreamController.close();
  }
}
