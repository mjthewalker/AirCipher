import 'dart:convert';
import 'dart:io';

import '../enums/message_type.dart';

class UdpSignalMessage {
  final String id;
  final MessageType type;
  final String? sdp;
  final InternetAddress address;

  UdpSignalMessage({required this.id, required this.type, this.sdp,required this.address});

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    if (sdp != null) 'sdp': sdp,
    'address' : address
  };

  static UdpSignalMessage? fromJson(String jsonStr) {
    try {
      final data = jsonDecode(jsonStr);
      return UdpSignalMessage(
        id: data['id'],
        type: MessageType.values.firstWhere((e) => e.name == data['type']),
        sdp: data['sdp'],
        address: data['address']
      );
    } catch (_) {
      return null;
    }
  }
}