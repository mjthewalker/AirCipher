// lib/network/webrtc_service.dart
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

  // ICE candidates
  final _iceController = StreamController<RTCIceCandidate>.broadcast();
  Stream<RTCIceCandidate> get onIceCandidate => _iceController.stream;

  // Connection established (ICE connected)
  final _connectionEstablishedController = StreamController<void>.broadcast();
  Stream<void> get onConnectionEstablished => _connectionEstablishedController.stream;

  // Incoming call requests
  final _callController = StreamController<void>.broadcast();
  Stream<void> get onCallRequested => _callController.stream;

  // Text chat messages
  final _msgController = StreamController<String>.broadcast();
  Stream<String> get onMessageReceived => _msgController.stream;

  /// Initialize peer connection and handlers
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

  /// Caller: create chat channel + offer
  Future<String> createChatOffer() async {
    if (_peerConnection == null) {
      await initConnection(isCaller: true);
    }
    if (_dataChannel == null) {
      _dataChannel = await _peerConnection!.createDataChannel('chat', RTCDataChannelInit());
      _setupDataChannel();
    }

    final offer = await _peerConnection!.createOffer();
    await _peerConnection!.setLocalDescription(offer);
    return offer.sdp!;
  }

  /// Callee: answer chat
  Future<String> createChatAnswer(String remoteSdp,String senderPeerId) async {
    remotePeerId = senderPeerId;
    print("remote peer ID : $remotePeerId");
    await initConnection(isCaller: false);
    await _peerConnection!.setRemoteDescription(RTCSessionDescription(remoteSdp, 'offer'));
    final answer = await _peerConnection!.createAnswer();
    await _peerConnection!.setLocalDescription(answer);
    return answer.sdp!;
  }

  /// Caller: set remote chat answer
  Future<void> setChatAnswer(String sdp,String senderPeerId) async {
    remotePeerId = senderPeerId;
    print("remote peer ID chat : $remotePeerId");
    await _peerConnection!.setRemoteDescription(RTCSessionDescription(sdp, 'answer'));
  }

  /// Send a text message
  void sendMessage(String text,String peerId) async {
    if (_dataChannel == null || _dataChannel!.state != RTCDataChannelState.RTCDataChannelOpen) {
      print('Data channel not ready!');
      return;
    }
    final encrypted = await signalService.encrypt(text, remotePeerId!);
    _dataChannel?.send(RTCDataChannelMessage.fromBinary(encrypted));
  }

  void _setupDataChannel() {
    _dataChannel!.onMessage = (msg) async {
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
        if (remotePeerId != null) {
          final decrypted = await signalService.decrypt(msg.binary, remotePeerId!);
          _msgController.add(decrypted);
        } else {
          print("⚠️ Warning: remotePeerId is null, can't decrypt.");
        }
      }
    };
  }

  //────────────────────────────────────────────────────────────────
  // VOICE CALL
  //────────────────────────────────────────────────────────────────

  /// Caller: initiate a voice call
  Future<void> initiateCall() async {
    _dataChannel?.send(RTCDataChannelMessage('__CALL__'));
    final offer = await startVoiceCall(isCaller: true);
    _dataChannel?.send(RTCDataChannelMessage('OFFER:$offer'));
  }

  /// Grab mic, add tracks, and (if caller) create & return offer
  Future<String> startVoiceCall({required bool isCaller}) async {
    _localStream = await navigator.mediaDevices.getUserMedia({'audio': true, 'video': false});
    if (_peerConnection == null) await initConnection(isCaller: isCaller);
    _localStream!.getAudioTracks().forEach((t) => _peerConnection!.addTrack(t, _localStream!));
    if (isCaller) {
      final offer = await _peerConnection!.createOffer();
      await _peerConnection!.setLocalDescription(offer);
      return offer.sdp!;
    }
    return '';
  }

  /// Callee: handle incoming voice offer, return answer
  Future<String> handleVoiceOffer(String remoteSdp) async {
    if (_peerConnection == null) await initConnection(isCaller: false);
    await _peerConnection!.setRemoteDescription(RTCSessionDescription(remoteSdp, 'offer'));
    _localStream = await navigator.mediaDevices.getUserMedia({'audio': true, 'video': false});
    _localStream!.getAudioTracks().forEach((t) => _peerConnection!.addTrack(t, _localStream!));
    final answer = await _peerConnection!.createAnswer();
    await _peerConnection!.setLocalDescription(answer);
    return answer.sdp!;
  }
  Future<void> stopVoiceCall() async {
    _localStream?.getTracks().forEach((t) => t.stop());
    _localStream = null;
    _remoteStream = null;

    // Optionally remove audio senders from the peer connection
    // (not strictly necessary unless you're renegotiating)
  }


  /// Caller: handle callee’s answer
  Future<void> handleVoiceAnswer(String remoteSdp) async {
    await _peerConnection!.setRemoteDescription(RTCSessionDescription(remoteSdp, 'answer'));
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
