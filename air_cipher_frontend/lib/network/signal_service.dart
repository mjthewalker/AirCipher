import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';
import 'dart:async';

class PreKeyBundleJson {
  final int registrationId;
  final int deviceId;
  final int? preKeyId;
  final Uint8List? preKeyPublic;
  final int signedPreKeyId;
  final Uint8List signedPreKeyPublic;
  final Uint8List signedPreKeySignature;
  final Uint8List identityKey;

  PreKeyBundleJson({
    required this.registrationId,
    required this.deviceId,
    required this.preKeyId,
    required this.preKeyPublic,
    required this.signedPreKeyId,
    required this.signedPreKeyPublic,
    required this.signedPreKeySignature,
    required this.identityKey,
  });

  Map<String, dynamic> toJson() {
    return {
      'registrationId': registrationId,
      'deviceId': deviceId,
      'preKeyId': preKeyId,
      'preKeyPublic': preKeyPublic != null ? base64Encode(preKeyPublic!) : null,
      'signedPreKeyId': signedPreKeyId,
      'signedPreKeyPublic': base64Encode(signedPreKeyPublic),
      'signedPreKeySignature': base64Encode(signedPreKeySignature),
      'identityKey': base64Encode(identityKey),
    };
  }

  factory PreKeyBundleJson.fromJson(Map<String, dynamic> json) {
    return PreKeyBundleJson(
      registrationId: json['registrationId'],
      deviceId: json['deviceId'],
      preKeyId: json['preKeyId'],
      preKeyPublic: json['preKeyPublic'] != null
          ? base64Decode(json['preKeyPublic'])
          : null,
      signedPreKeyId: json['signedPreKeyId'],
      signedPreKeyPublic: base64Decode(json['signedPreKeyPublic']),
      signedPreKeySignature: base64Decode(json['signedPreKeySignature']),
      identityKey: base64Decode(json['identityKey']),
    );
  }
}

class SignalService {
  final String id;
  late final InMemorySignalProtocolStore _store;
  late int _signedPreKeyId;
  final Map<String, SessionCipher> _sessionCiphers = {};

  SignalService(this.id) {
    _initialize();
  }

  Future<void> _initialize() async {
    final random = Random.secure();
    final registrationId = generateRegistrationId(
        false);
    final identityKeyPair = generateIdentityKeyPair();
    _store = InMemorySignalProtocolStore(identityKeyPair, registrationId);

    final preKeys = generatePreKeys(0, 5);
    for (var preKey in preKeys) {
      await _store.storePreKey(preKey.id, preKey);
    }

    _signedPreKeyId = random.nextInt(0xffffff);
    final signedPreKey = generateSignedPreKey(identityKeyPair, _signedPreKeyId);
    await _store.storeSignedPreKey(_signedPreKeyId, signedPreKey);
  }

  Future<void> init() async {
    print("🔐 SignalService initialized for $id");
  }

  Future<Map<String, dynamic>> getPreKeyBundle() async {
    final identityKeyPair = await _store.getIdentityKeyPair();
    final identityKey = identityKeyPair.getPublicKey().serialize();



    final preKey = await _store.loadPreKey(1);
    final signedPreKey = await _store.loadSignedPreKey(_signedPreKeyId);
    final regId = await _store.getLocalRegistrationId();
    return PreKeyBundleJson(
      registrationId: regId,
      deviceId: 1,
      preKeyId: preKey.id,
      preKeyPublic: preKey
          .getKeyPair()
          .publicKey
          .serialize(),

      signedPreKeyId: signedPreKey.id,
      signedPreKeyPublic: signedPreKey
          .getKeyPair()
          .publicKey
          .serialize(),

      signedPreKeySignature: signedPreKey.signature,
      identityKey: identityKey,
    ).toJson();
  }

  Future<void> processRemoteBundle(String peerId, String bundleJson) async {
    print("🔑 Processing PreKeyBundle for $peerId");
    final bundleMap = jsonDecode(bundleJson);
    final bundle = PreKeyBundleJson.fromJson(bundleMap);

    ECPublicKey? preKeyPublic;
    if (bundle.preKeyPublic != null) {
      preKeyPublic = Curve.decodePoint(bundle.preKeyPublic!, 0);
    }
    final signedPreKeyPublic = Curve.decodePoint(bundle.signedPreKeyPublic, 0);
    final identityKey = IdentityKey(
        Curve.decodePoint(bundle.identityKey, 0));

    final preKeyBundle = PreKeyBundle(
      bundle.registrationId,
      bundle.deviceId,
      bundle.preKeyId,
      preKeyPublic,
      bundle.signedPreKeyId,
      signedPreKeyPublic,
      bundle.signedPreKeySignature,
      identityKey,
    );

    final remoteAddress = SignalProtocolAddress(peerId, bundle.deviceId);

    final sessionBuilder = SessionBuilder.fromSignalStore(
        _store, remoteAddress);
    await sessionBuilder.processPreKeyBundle(preKeyBundle);

    _sessionCiphers[peerId] = SessionCipher.fromStore(_store, remoteAddress);
  }

  Future<String> encrypt(String plaintext, String peerId) async {
    final cipher = _sessionCiphers[peerId]!;
    final ciphertext = await cipher.encrypt(
        Uint8List.fromList(utf8.encode(plaintext)));
    return base64Encode(ciphertext.serialize());
  }

  Future<String> decrypt(String encrypted, String peerId) async {
    final cipher = _sessionCiphers[peerId];
    if (cipher == null) {
      throw Exception("No cipher for peer $peerId");
    }

    final bytes = base64Decode(encrypted);
    final completer = Completer<Uint8List>();

    if (bytes[0] == 3) {

      final preKeyMessage = PreKeySignalMessage(bytes);
      await cipher.decryptWithCallback(preKeyMessage, (plaintext) {
        completer.complete(plaintext);
      });
    } else {

      final signalMessage = SignalMessage.fromSerialized(bytes);
      await cipher.decryptFromSignalWithCallback(signalMessage, (plaintext) {
        completer.complete(plaintext);
      });
    }

    final plaintextBytes = await completer.future;
    return utf8.decode(plaintextBytes);
  }



}