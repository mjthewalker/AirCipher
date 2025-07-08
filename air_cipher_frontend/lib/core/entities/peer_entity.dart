import 'dart:io';

class PeerInfo {
  final String id;
  final InternetAddress? address;
  final int? port;
  PeerInfo({required this.id, this.address, this.port});
}
