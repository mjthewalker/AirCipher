import 'dart:convert';
import 'dart:io';
import 'package:frontend/core/enums/message_type.dart';

class UdpSignalMessage {
  String id;
  MessagesType type;
  String? jsonPayload;
  String? sdp;
  String? candidate;
  String? sdpMid;
  Map<String, dynamic>? bundle;
  int? sdpMLineIndex;
  InternetAddress? ip;
  int? port;

  UdpSignalMessage({
    required this.id,
    required this.type,
    this.jsonPayload,
    this.sdp,
    this.candidate,
    this.sdpMid,
    this.sdpMLineIndex,
    this.bundle,
    this.ip,
    this.port,
  });

  factory UdpSignalMessage.fromJson(String jsonStr) {
    final json = jsonDecode(jsonStr);
    return UdpSignalMessage(
      id: json['id'],
      type: MessagesType.values
          .firstWhere((e) => e.toString().split('.').last == json['type']),
      sdp: json['sdp'],
      candidate: json['candidate'],
      jsonPayload: json['jsonPayload'],
      sdpMid: json['sdpMid'],
      bundle: json['bundle'],
      sdpMLineIndex: json['sdpMLineIndex'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.toString().split('.').last,
        if (sdp != null) 'sdp': sdp,
        if (candidate != null) 'candidate': candidate,
        if (jsonPayload != null) 'jsonPayload': jsonPayload,
        if (sdpMid != null) 'sdpMid': sdpMid,
        if (bundle != null) 'bundle': bundle,
        if (sdpMLineIndex != null) 'sdpMLineIndex': sdpMLineIndex,
      };
}
