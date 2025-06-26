import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:frontend/network/signal_service.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:frontend/network/webrtc_service.dart';
import 'package:frontend/core/entities/peer_entity.dart';
import 'package:frontend/core/entities/udp_entity.dart';
import 'package:frontend/core/enums/message_type.dart';

class PeerDiscoveryService {
  final int port = 45678;
  final String id;
  final SignalService signal;
  final WebRTCService webRTCService;

  RawDatagramSocket? _socket;
  bool _started = false;
  Timer? _discoveryTimer;
  PeerInfo? _currentPeer;
  late String myBundle;

  final _peerFoundController = StreamController<UdpSignalMessage>.broadcast();
  Stream<UdpSignalMessage> get onPeerFound => _peerFoundController.stream;

  PeerDiscoveryService(this.webRTCService, this.signal) : id = signal.id {
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


    await _sendDiscovery();
    _discoveryTimer = Timer.periodic(
      const Duration(seconds: 5),
          (_) => _sendDiscovery(),
    );

    print("🔍 Peer discovery started (ID: $id, port: $port)");
  }
  Future<void> _sendDiscovery() async {
    final discoveryMsg = UdpSignalMessage(id: id, type: MessagesType.discovery);
    final data = utf8.encode(jsonEncode(discoveryMsg.toJson()));
    final bcast = await _getBroadcastAddress();
    _socket?.send(data, bcast, port);
    print("📡 Broadcast discovery ping to $bcast");
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

    switch (msg.type) {
      case MessagesType.discovery:
        print("👀 Peer discovery received from ${msg.ip}");
        _peerFoundController.add(msg);
        break;
      case MessagesType.offer:
        print("📡 Received offer from ${msg.ip}");
        _currentPeer = PeerInfo(id: msg.id, address: msg.ip, port: msg.port);
        final answer = await webRTCService.createAnswer(msg.sdp!);
        sendAnswer(answer, _currentPeer!);
        break;
      case MessagesType.answer:
        print("✅ Received answer from ${msg.ip}");
        _currentPeer = PeerInfo(id: msg.id, address: msg.ip, port: msg.port);
        await webRTCService.setRemoteAnswer(msg.sdp!);
        break;
      case MessagesType.candidate:
        print("❄️ Received ICE candidate from ${msg.ip}");
        await webRTCService.addIceCandidate(RTCIceCandidate(
          msg.candidate!, msg.sdpMid!, msg.sdpMLineIndex!,
        ));
        break;
      default:
        print("⚠️ Unknown message type: ${msg.type}");
    }
  }

  Future<InternetAddress?> _getGateway() async {
    final info = NetworkInfo();
    final gw = await info.getWifiGatewayIP();
    return gw != null ? InternetAddress(gw) : null;
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
  void stopDiscovery() {
    if (!_started) return;
    _started = false;
    _discoveryTimer?.cancel();
    print("🛑 Peer discovery stopped");
  }


}