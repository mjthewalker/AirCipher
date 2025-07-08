import 'dart:math';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'dart:async';
import 'package:frontend/network/signal_service.dart';

class WebRTCService {
  RTCPeerConnection? _peerConnection;
  RTCDataChannel? _dataChannel;
  MediaStream? _localStream;
  MediaStream? _remoteStream;
  final SignalService signalService;
  String? remotePeerId;

  WebRTCService(this.signalService);

  final _config = <String, dynamic>{
    'iceServers': [],
    'iceTransportPolicy': 'all',
    'sdpSemantics': 'unified-plan',
  };

  final _iceController = StreamController<RTCIceCandidate>.broadcast();

  Stream<RTCIceCandidate> get onIceCandidate => _iceController.stream;

  final _connectionEstablishedController = StreamController<void>.broadcast();

  Stream<void> get onConnectionEstablished =>
      _connectionEstablishedController.stream;

  final _callController = StreamController<void>.broadcast();

  Stream<void> get onCallRequested => _callController.stream;

  final _msgController = StreamController<String>.broadcast();

  Stream<String> get onMessageReceived => _msgController.stream;

  Future<void> initConnection({bool isCaller = false}) async {
    if (_peerConnection != null) return;
    _peerConnection = await createPeerConnection(_config);

    _peerConnection!.onIceCandidate = (candidate) {
      if (candidate.candidate != null) {
        _iceController.add(candidate);
      }
    };
    _peerConnection!.onIceConnectionState = (state) {
      if (state == RTCIceConnectionState.RTCIceConnectionStateConnected ||
          state == RTCIceConnectionState.RTCIceConnectionStateCompleted) {
        _connectionEstablishedController.add(null);
      }
    };
    _peerConnection!.onTrack = (event) {
      if (event.track.kind == 'audio' && event.streams.isNotEmpty) {
        _remoteStream = event.streams.first;
        print('🔊 Remote audio track added');
      }
    };
    if (!isCaller) {
      _peerConnection!.onDataChannel = (channel) {
        _dataChannel = channel;
        _setupDataChannel();
      };
    }
  }

  //────────────────────────────────────────────────────────────────
  // CHAT (data channel)
  //────────────────────────────────────────────────────────────────

  Future<String> createChatOffer() async {
    if (_peerConnection == null) {
      await initConnection(isCaller: true);
    }
    if (_dataChannel == null) {
      _dataChannel = await _peerConnection!
          .createDataChannel('chat', RTCDataChannelInit());
      _setupDataChannel();
    }

    final offer = await _peerConnection!.createOffer();
    await _peerConnection!.setLocalDescription(offer);
    return offer.sdp!;
  }

  Future<String> createChatAnswer(String remoteSdp, String senderPeerId) async {
    remotePeerId = senderPeerId;
    print("remote peer ID : $remotePeerId");
    await initConnection(isCaller: false);
    await _peerConnection!
        .setRemoteDescription(RTCSessionDescription(remoteSdp, 'offer'));
    final answer = await _peerConnection!.createAnswer();
    await _peerConnection!.setLocalDescription(answer);
    return answer.sdp!;
  }

  Future<void> setChatAnswer(String sdp, String senderPeerId) async {
    remotePeerId = senderPeerId;
    print("remote peer ID chat : $remotePeerId");
    await _peerConnection!
        .setRemoteDescription(RTCSessionDescription(sdp, 'answer'));
  }

  Future<void> sendMessage(String text, String peerId) async {
    if (_dataChannel == null ||
        _dataChannel!.state != RTCDataChannelState.RTCDataChannelOpen) {
      print('Data channel not ready!');
      return;
    }

    final encrypted = await signalService.encrypt(text, remotePeerId!);
    final encryptedBytes = Uint8List.fromList(utf8.encode(encrypted));
    _dataChannel?.send(RTCDataChannelMessage.fromBinary(encryptedBytes));
  }

  bool _sessionReadyFor(String? peerId) {
    return peerId != null && signalService.hasSession(peerId);
  }

  void _setupDataChannel() {
    _dataChannel!.onMessage = (msg) async {
      try {
        if (msg.isBinary) {
          final raw = msg.binary;
          print("🛠 RAW RECEIVED: ${raw.length} bytes ‑ first 10 bytes: "
              "${raw.sublist(0, min(raw.length, 10)).map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}");
          if (!_sessionReadyFor(remotePeerId)) {
            print(
                "⚠️ Session not yet ready for $remotePeerId, skipping decrypt");
            return;
          }

          final decrypted = await signalService.decrypt(raw, remotePeerId!);
          _msgController.add(decrypted);
        } else {
          final text = msg.text;
          if (text == '__CALL__') {
            _callController.add(null);
          } else if (text.startsWith('OFFER:')) {
            final remoteSdp = text.substring(6);
            final answer = await handleVoiceOffer(remoteSdp);
            _dataChannel!.send(RTCDataChannelMessage('ANSWER:$answer'));
          } else if (text.startsWith('ANSWER:')) {
            final remoteSdp = text.substring(7);
            await handleVoiceAnswer(remoteSdp);
          } else {
            print("📩 Unencrypted text message received: $text");
          }
        }
      } catch (e, stack) {
        print("❌ Error handling message: $e\n$stack");
      }
    };
  }

  //────────────────────────────────────────────────────────────────
  // VOICE CALL
  //────────────────────────────────────────────────────────────────

  Future<void> initiateCall() async {
    _dataChannel?.send(RTCDataChannelMessage('__CALL__'));
    final offer = await startVoiceCall(isCaller: true);
    _dataChannel?.send(RTCDataChannelMessage('OFFER:$offer'));
  }

  Future<String> startVoiceCall({required bool isCaller}) async {
    _localStream = await navigator.mediaDevices
        .getUserMedia({'audio': true, 'video': false});
    if (_peerConnection == null) await initConnection(isCaller: isCaller);
    _localStream!
        .getAudioTracks()
        .forEach((t) => _peerConnection!.addTrack(t, _localStream!));
    if (isCaller) {
      final offer = await _peerConnection!.createOffer();
      await _peerConnection!.setLocalDescription(offer);
      return offer.sdp!;
    }
    return '';
  }

  Future<String> handleVoiceOffer(String remoteSdp) async {
    if (_peerConnection == null) await initConnection(isCaller: false);
    await _peerConnection!
        .setRemoteDescription(RTCSessionDescription(remoteSdp, 'offer'));
    _localStream = await navigator.mediaDevices
        .getUserMedia({'audio': true, 'video': false});
    _localStream!
        .getAudioTracks()
        .forEach((t) => _peerConnection!.addTrack(t, _localStream!));
    final answer = await _peerConnection!.createAnswer();
    await _peerConnection!.setLocalDescription(answer);
    return answer.sdp!;
  }

  Future<void> stopVoiceCall() async {
    _localStream?.getTracks().forEach((t) => t.stop());
    _localStream = null;
    _remoteStream = null;
  }

  Future<void> handleVoiceAnswer(String remoteSdp) async {
    await _peerConnection!
        .setRemoteDescription(RTCSessionDescription(remoteSdp, 'answer'));
  }

  //────────────────────────────────────────────────────────────────
  // ICE
  //────────────────────────────────────────────────────────────────

  Future<void> addIceCandidate(RTCIceCandidate candidate) async {
    await _peerConnection?.addCandidate(candidate);
  }

  //────────────────────────────────────────────────────────────────
  // CLEANUP
  //────────────────────────────────────────────────────────────────

  void dispose() {
    _msgController.close();
    _callController.close();
    _iceController.close();
    _connectionEstablishedController.close();
    _peerConnection?.close();
    _localStream?.dispose();
  }
}
