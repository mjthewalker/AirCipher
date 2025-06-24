import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'dart:async';

class WebRTCService {
  RTCPeerConnection? _peerConnection;
  RTCDataChannel? _dataChannel;

  final config = {
    'iceServers': [],
    'iceTransportPolicy': 'all',
    'sdpSemantics': 'unified-plan',
  };

  final StreamController<void> _connectionEstablishedController = StreamController<void>.broadcast();
  final StreamController<RTCIceCandidate> _iceCandidateController = StreamController<RTCIceCandidate>.broadcast();

  Stream<void> get onConnectionEstablished => _connectionEstablishedController.stream;
  Stream<RTCIceCandidate> get onIceCandidate => _iceCandidateController.stream;

  Future<void> initConnection({bool isCaller = false}) async {
    _peerConnection = await createPeerConnection(config);

    _peerConnection?.onConnectionState = (RTCPeerConnectionState state) {
      print("peer connection state: $state");
    };

    _peerConnection?.onIceConnectionState = (RTCIceConnectionState state) {
      print("🌐 ICE connection state: $state");
      if (state == RTCIceConnectionState.RTCIceConnectionStateConnected ||
          state == RTCIceConnectionState.RTCIceConnectionStateCompleted) {
        _connectionEstablishedController.add(null);
      }
    };

    _peerConnection?.onIceCandidate = (RTCIceCandidate candidate) {
      print("✨ ICE candidate: ${candidate.candidate}");
      _iceCandidateController.add(candidate);
    };

    if (!isCaller) {
      _peerConnection?.onDataChannel = (RTCDataChannel channel) {
        _dataChannel = channel;
        _setupDataChannel();
      };
    }
  }

  Future<String> createOffer() async {
    await initConnection(isCaller: true);
    final dataChannelDict = RTCDataChannelInit();
    _dataChannel = await _peerConnection!.createDataChannel("data", dataChannelDict);
    _setupDataChannel();
    final offer = await _peerConnection!.createOffer();
    await _peerConnection!.setLocalDescription(offer);
    return offer.sdp!;
  }

  Future<String> createAnswer(String remoteSdp) async {
    await initConnection();
    await _peerConnection!.setRemoteDescription(RTCSessionDescription(remoteSdp, 'offer'));
    final answer = await _peerConnection!.createAnswer();
    await _peerConnection!.setLocalDescription(answer);
    return answer.sdp!;
  }

  Future<void> setRemoteAnswer(String sdp) async {
    await _peerConnection!.setRemoteDescription(RTCSessionDescription(sdp, 'answer'));
  }

  Future<void> addIceCandidate(RTCIceCandidate candidate) async {
    await _peerConnection?.addCandidate(candidate);
  }

  void _setupDataChannel() {
    _dataChannel?.onMessage = (message) {
      print("💬 Received: ${message.text}");
    };
    _dataChannel?.onDataChannelState = (state) {
      print("🔌 Data channel state: $state");
    };
  }

  void sendMessage(String message) {
    _dataChannel?.send(RTCDataChannelMessage(message));
  }
}