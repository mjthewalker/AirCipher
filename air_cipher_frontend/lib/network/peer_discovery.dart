import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:uuid/uuid.dart';
import 'package:frontend/network/webrtc_service.dart';
import 'package:frontend/network/signal_service.dart';
import 'package:frontend/core/entities/peer_entity.dart';
import 'package:frontend/core/entities/udp_entity.dart';
import 'package:frontend/core/enums/message_type.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
class PeerDiscoveryService {
  final int port = 45678;
  final String  id;
  RawDatagramSocket? _socket;
  bool _started = false;

  final WebRTCService webRTCService;
  final SignalService signalService;
  PeerInfo? _currentPeer;
  final _offerReceivedController = StreamController<String>.broadcast();
  Stream<String> get onOfferReceived => _offerReceivedController.stream;
  final _peerFoundController = StreamController<UdpSignalMessage>.broadcast();
  Stream<UdpSignalMessage> get onPeerFound => _peerFoundController.stream;
  final Set<String> _bundlesSentTo = {};
  PeerDiscoveryService(this.webRTCService,this.signalService,this.id) {
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
    _currentPeer = PeerInfo(id: msg.id, address: msg.ip, port: msg.port);
    switch (msg.type) {

      case MessagesType.discovery:
        print("👀 Peer discovery received from ${msg.ip}");
        _peerFoundController.add(msg);
        final bundleJson = await signalService.getPreKeyBundle();
        sendPreKeyBundle(bundleJson, _currentPeer!);
        break;

      case MessagesType.offer:
        print("📡 Received chat offer from ${msg.ip}");
        _offerReceivedController.add(_currentPeer!.id);
        final answer = await webRTCService.createChatAnswer(msg.sdp!,_currentPeer!.id);
        sendAnswer(answer, _currentPeer!);
        break;

      case MessagesType.answer:
        print("✅ Received chat answer from ${msg.ip}");
        await webRTCService.setChatAnswer(msg.sdp!,_currentPeer!.id);
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
      case MessagesType.preKeyBundle:
        await signalService.processRemoteBundle(msg.bundle!);
        print("🔑 Signal session ready with ${msg.id}");
        if (!_bundlesSentTo.contains(msg.id)) {
          final responseBundle = await signalService.getPreKeyBundle();
          sendPreKeyBundle(responseBundle, _currentPeer!);
          _bundlesSentTo.add(msg.id);
        }
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
  void sendPreKeyBundle(Map<String,dynamic> bundleJson, PeerInfo peer) {
    final msg = UdpSignalMessage(
      id:  id,
      type: MessagesType.preKeyBundle,
      bundle: bundleJson,
    );
    _socket!.send(utf8.encode(jsonEncode(msg.toJson())),
        peer.address!, peer.port!);
  }

  void stop() {
    _socket?.close();
    _peerFoundController.close();
    _offerReceivedController.close();
  }
}