import 'dart:convert';
import 'dart:io';
import 'package:frontend/core/enums/message_type.dart';

class UdpSignalMessage {
  final String id;
  final MessagesType type;
  final String? sdp;
   InternetAddress? ip;
   int? port;
   String? candidate;
   String? sdpMid;
   int? sdpMLineIndex;

  UdpSignalMessage({required this.id, required this.type, this.sdp,this.ip,this.port,this.candidate,this.sdpMid,this.sdpMLineIndex});

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    if (sdp != null) 'sdp': sdp,
  };

  static UdpSignalMessage? fromJson(String jsonStr) {
    try {
      final data = jsonDecode(jsonStr);
      return UdpSignalMessage(
        id: data['id'],
        type: MessagesType.values.firstWhere((e) => e.name == data['type']),
        sdp: data['sdp'],
      );
    } catch (_) {
      return null;
    }
  }
}