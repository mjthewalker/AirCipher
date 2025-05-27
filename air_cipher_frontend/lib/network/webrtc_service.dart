import 'package:flutter_webrtc/flutter_webrtc.dart';
class WebRTCService {
  RTCPeerConnection? _peerConnection;
  RTCDataChannel? _dataChannel;
  final config = {
    'iceServers': []
  };
  Future<void> initConnection({bool isCaller = false}) async {
    _peerConnection = await createPeerConnection(config);
    if (!isCaller) {
      _peerConnection?.onDataChannel = (RTCDataChannel channel) {
        _dataChannel = channel;
        _setupDataChannel();
      };
    }
  }
  Future<String> createOffer() async{
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
    await _peerConnection!.setRemoteDescription(
      RTCSessionDescription(remoteSdp, 'offer'),
    );
    final answer = await _peerConnection!.createAnswer();
    await _peerConnection!.setLocalDescription(answer);
    return answer.sdp!;
  }
  Future<void> setRemoteAnswer(String sdp) async {
    await _peerConnection!.setRemoteDescription(
      RTCSessionDescription(sdp, 'answer'),
    );
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