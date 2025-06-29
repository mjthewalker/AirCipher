import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:uuid/uuid.dart';
import 'package:frontend/network/webrtc_service.dart';
import 'package:frontend/core/entities/peer_entity.dart';
import 'package:frontend/core/entities/udp_entity.dart';
import 'package:frontend/core/enums/message_type.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
class PeerDiscoveryService {
  final int port = 45678;
  final String id = const Uuid().v4();
  RawDatagramSocket? _socket;
  bool _started = false;

  final WebRTCService webRTCService;
  PeerInfo? _currentPeer;

  final _peerFoundController = StreamController<UdpSignalMessage>.broadcast();
  Stream<UdpSignalMessage> get onPeerFound => _peerFoundController.stream;

  PeerDiscoveryService(this.webRTCService) {
    webRTCService.onIceCandidate.listen((candidate) {
      if (_currentPeer != null) {
        sendCandidate(candidate, _currentPeer!);
      }
    });
  }

  Future<void> start() async {
    if (_started) return;
    _started = true;

    _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, port);
    _socket!.broadcastEnabled = true;
    _socket!.listen(_handleSocketEvent);

    final discoveryMsg = UdpSignalMessage(id: id, type: MessagesType.discovery);
    await _broadcast(discoveryMsg);

    print("🔍 Peer discovery started (ID: $id, port: $port)");
  }

  void _handleSocketEvent(RawSocketEvent event) async {
    if (event != RawSocketEvent.read) return;
    final datagram = _socket!.receive();
    if (datagram == null) return;

    final msgStr = utf8.decode(datagram.data);
    print("📥 Received UDP: $msgStr from ${datagram.address.address}:${datagram.port}");

    final msg = UdpSignalMessage.fromJson(msgStr);
    msg.ip = datagram.address;
    msg.port = datagram.port;

    if (msg.id == id) {
      print("🛑 Ignored self-message (ID: $id)");
      return;
    }

    // Update _currentPeer on any direct incoming message
    _currentPeer = PeerInfo(id: msg.id, address: msg.ip, port: msg.port);

    switch (msg.type) {
      case MessagesType.discovery:
        print("👀 Peer discovery received from ${msg.ip}");
        _peerFoundController.add(msg);
        break;

      case MessagesType.offer:
        print("📡 Received chat offer from ${msg.ip}");
        final answer = await webRTCService.createChatAnswer(msg.sdp!);
        sendAnswer(answer, _currentPeer!);
        break;

      case MessagesType.answer:
        print("✅ Received chat answer from ${msg.ip}");
        await webRTCService.setChatAnswer(msg.sdp!);
        break;

      case MessagesType.candidate:
        print("❄️ Received ICE candidate from ${msg.ip}");
        await webRTCService.addIceCandidate(
          RTCIceCandidate(msg.candidate!, msg.sdpMid!, msg.sdpMLineIndex!),
        );
        break;

      case MessagesType.voiceOffer:
        print("📞 Received voice offer from ${msg.ip}");
        final answerSdp = await webRTCService.handleVoiceOffer(msg.sdp!);
        sendVoiceAnswer(answerSdp, _currentPeer!);
        break;


      case MessagesType.voiceAnswer:
        print("✅ Received voice answer from ${msg.ip}");
        await webRTCService.handleVoiceAnswer(msg.sdp!);
        break;

      default:
        print("⚠️ Unknown message type: ${msg.type}");
    }
  }

  Future<InternetAddress> _getBroadcastAddress() async {
    final info = NetworkInfo();
    final ip = await info.getWifiIP();
    final mask = await info.getWifiSubmask();
    if (ip == null || mask == null) return InternetAddress('255.255.255.255');

    final ipParts = ip.split('.').map(int.parse).toList();
    final maskParts = mask.split('.').map(int.parse).toList();
    final bcastParts = List<int>.generate(4, (i) {
      return ipParts[i] | (maskParts[i] ^ 0xFF);
    });
    return InternetAddress(bcastParts.join('.'));
  }

  Future<void> _broadcast(UdpSignalMessage msg) async {
    final data = utf8.encode(jsonEncode(msg.toJson()));
    final bcast = await _getBroadcastAddress();
    _socket!.send(data, bcast, port);
  }

  void sendOffer(String sdp, PeerInfo peer) {
    _currentPeer = peer;
    final msg = UdpSignalMessage(id: id, type: MessagesType.offer, sdp: sdp);
    final data = utf8.encode(jsonEncode(msg.toJson()));
    _socket!.send(data, peer.address!, peer.port!);
  }

  void sendAnswer(String sdp, PeerInfo peer) {
    final msg = UdpSignalMessage(id: id, type: MessagesType.answer, sdp: sdp);
    final data = utf8.encode(jsonEncode(msg.toJson()));
    _socket!.send(data, peer.address!, peer.port!);
  }

  void sendCandidate(RTCIceCandidate candidate, PeerInfo peer) {
    final msg = UdpSignalMessage(
      id: id,
      type: MessagesType.candidate,
      candidate: candidate.candidate,
      sdpMid: candidate.sdpMid,
      sdpMLineIndex: candidate.sdpMLineIndex,
    );
    final data = utf8.encode(jsonEncode(msg.toJson()));
    _socket!.send(data, peer.address!, peer.port!);
  }

  void sendVoiceOffer(String sdp, PeerInfo peer) {
    _currentPeer = peer;
    final msg = UdpSignalMessage(id: id, type: MessagesType.voiceOffer, sdp: sdp);
    final data = utf8.encode(jsonEncode(msg.toJson()));
    _socket!.send(data, peer.address!, peer.port!);
  }

  void sendVoiceAnswer(String sdp, PeerInfo peer) {
    final msg = UdpSignalMessage(id: id, type: MessagesType.voiceAnswer, sdp: sdp);
    final data = utf8.encode(jsonEncode(msg.toJson()));
    _socket!.send(data, peer.address!, peer.port!);
  }

  void stop() {
    _socket?.close();
    _peerFoundController.close();
  }
}