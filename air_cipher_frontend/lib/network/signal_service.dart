import 'dart:convert';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';

class SignalService {
  final String id;
  final SimpleKeyPair _keyPair;
  final SimplePublicKey _publicKey;
  final Map<String, SecretKey> _sharedSecrets = {};

  SignalService._(this.id, this._keyPair, this._publicKey);

  /// Creates and initializes the service (X25519 key pair)
  static Future<SignalService> create(String id) async {
    final keyPair = await X25519().newKeyPair();
    final publicKey = await keyPair.extractPublicKey();
    return SignalService._(id, keyPair, publicKey);
  }

  /// (Optional) call after `create()` to log readiness.
  Future<void> init() async {
    print("🔐 SignalService ready for $id");
  }

  /// Returns this peer’s public key for JSON transport.
  Future<Map<String, dynamic>> getPreKeyBundle() async {
    final pubBytes = _publicKey.bytes;;
    return {
      'senderId': id,
      'publicKey': base64Encode(pubBytes),
    };
  }

  /// Process peer's PreKey bundle and derive shared session key.
  Future<void> processRemoteBundle(Map<String, dynamic> bundle) async {
    final peerId = bundle['senderId'];
    final peerKeyBytes = base64Decode(bundle['publicKey']);
    final peerPubKey = SimplePublicKey(peerKeyBytes, type: KeyPairType.x25519);

    final secretKey = await X25519().sharedSecretKey(
      keyPair: _keyPair,
      remotePublicKey: peerPubKey,
    );

    _sharedSecrets[peerId] = secretKey;
    print("🔑 Session established with $peerId");
  }

  /// Returns true if a session exists for [peerId].
  bool hasSession(String peerId) => _sharedSecrets.containsKey(peerId);

  /// Encrypt plaintext for [peerId], returns JSON string.
  Future<String> encrypt(String plaintext, String peerId) async {
    final secretKey = _sharedSecrets[peerId];
    if (secretKey == null) {
      throw Exception("No session with $peerId");
    }

    final algorithm = AesGcm.with256bits();
    final nonce = await algorithm.newNonce();
    final secretBox = await algorithm.encrypt(
      utf8.encode(plaintext),
      secretKey: secretKey,
      nonce: nonce,
    );

    return jsonEncode({
      'nonce': base64Encode(secretBox.nonce),
      'cipherText': base64Encode(secretBox.cipherText),
      'mac': base64Encode(secretBox.mac.bytes),
    });
  }

  /// Decrypt raw JSON string from [peerId] into UTF-8 string.
  Future<String> decrypt(Uint8List encryptedBytes, String peerId) async {
    final secretKey = _sharedSecrets[peerId];
    if (secretKey == null) {
      throw Exception("No session with $peerId");
    }

    final encryptedStr = utf8.decode(encryptedBytes);
    final data = jsonDecode(encryptedStr);

    final algorithm = AesGcm.with256bits();
    final secretBox = SecretBox(
      base64Decode(data['cipherText']),
      nonce: base64Decode(data['nonce']),
      mac: Mac(base64Decode(data['mac'])),
    );

    final clearText = await algorithm.decrypt(secretBox, secretKey: secretKey);
    return utf8.decode(clearText);
  }
}
