import 'dart:convert';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import 'package:crypto/crypto.dart';

class SignalService {
  final String id;
  final SimpleKeyPair _x25519KeyPair;
  final SimplePublicKey _x25519PublicKey;
  final KeyPair _ed25519KeyPair;
  final SimplePublicKey _ed25519PublicKey;
  final Map<String, SecretKey> _sharedSecrets = {};

  SignalService._(
      this.id,
      this._x25519KeyPair,
      this._x25519PublicKey,
      this._ed25519KeyPair,
      this._ed25519PublicKey,
      );

  /// Create with both X25519 and Ed25519 keys.
  static Future<SignalService> create(String id) async {
    final xKeyPair = await X25519().newKeyPair();
    final xPubKey = await xKeyPair.extractPublicKey();

    final edKeyPair = await Ed25519().newKeyPair();
    final edPubKey = await edKeyPair.extractPublicKey();

    return SignalService._(id, xKeyPair, xPubKey, edKeyPair, edPubKey);
  }

  Future<void> init() async {
    print("🔐 SignalService ready for $id");
  }

  /// Returns this peer’s public bundle, signed for authenticity.
  Future<Map<String, dynamic>> getPreKeyBundle() async {
    final message = utf8.encode(id) + _x25519PublicKey.bytes;
    final signature = await Ed25519().sign(message, keyPair: _ed25519KeyPair);

    return {
      'senderId': id,
      'x25519Key': base64Encode(_x25519PublicKey.bytes),
      'ed25519Key': base64Encode(_ed25519PublicKey.bytes),
      'signature': base64Encode(signature.bytes),
    };
  }

  /// Validates and processes a remote pre-key bundle.
  Future<void> processRemoteBundle(Map<String, dynamic> bundle) async {
    final peerId = bundle['senderId'];
    final x25519Bytes = base64Decode(bundle['x25519Key']);
    final ed25519Bytes = base64Decode(bundle['ed25519Key']);
    final signatureBytes = base64Decode(bundle['signature']);

    final edPubKey = SimplePublicKey(ed25519Bytes, type: KeyPairType.ed25519);
    final message = utf8.encode(peerId) + x25519Bytes;

    final isValid = await Ed25519().verify(
      message,
      signature: Signature(signatureBytes, publicKey: edPubKey),
    );

    if (!isValid) {
      throw Exception("Signature verification failed for $peerId");
    }

    final xPubKey = SimplePublicKey(x25519Bytes, type: KeyPairType.x25519);
    final secretKey = await X25519().sharedSecretKey(
      keyPair: _x25519KeyPair,
      remotePublicKey: xPubKey,
    );

    _sharedSecrets[peerId] = secretKey;
    print("✅ Verified & established session with $peerId");
  }

  bool hasSession(String peerId) => _sharedSecrets.containsKey(peerId);

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

  /// Optional: Identity fingerprint for human verification
  String getFingerprint() {
    final digest = sha256.convert(_ed25519PublicKey.bytes);
    return digest.toString().substring(0, 12); // Short fingerprint
  }
}
