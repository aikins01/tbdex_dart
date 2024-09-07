import 'dart:typed_data';
import '../crypto/crypto.dart';
import 'jwk.dart';

abstract class KeyManager {
  Future<String> generatePrivateKey(String algorithm);
  Future<Uint8List> getPublicKey(String keyAlias);
  Future<Uint8List> sign(String keyAlias, Uint8List payload);
  Future<String> getDeterministicAlias(Jwk key);
}

class InMemoryKeyManager implements KeyManager {
  final Map<String, Uint8List> _privateKeys = {};
  final Map<String, Uint8List> _publicKeys = {};
  final Map<String, String> _algorithms = {};

  @override
  Future<String> generatePrivateKey(String algorithm) async {
    final privateKey = Crypto.generatePrivateKey(algorithm);
    final publicKey = Crypto.computePublicKey(privateKey, algorithm);
    final jwk = Jwk.fromPublicKey(publicKey, algorithm);
    final alias = await getDeterministicAlias(jwk);

    _privateKeys[alias] = privateKey;
    _publicKeys[alias] = publicKey;
    _algorithms[alias] = algorithm;

    return alias;
  }

  @override
  Future<Uint8List> getPublicKey(String keyAlias) async {
    final publicKey = _publicKeys[keyAlias];
    if (publicKey == null) {
      throw KeyNotFoundException('No public key found for alias: $keyAlias');
    }
    return publicKey;
  }

  @override
  Future<Uint8List> sign(String keyAlias, Uint8List payload) async {
    final privateKey = _privateKeys[keyAlias];
    final algorithm = _algorithms[keyAlias];
    if (privateKey == null || algorithm == null) {
      throw KeyNotFoundException(
          'No private key or algorithm found for alias: $keyAlias');
    }
    return Crypto.sign(payload, privateKey, algorithm);
  }

  @override
  Future<String> getDeterministicAlias(Jwk key) async {
    return key.thumbprint();
  }
}

class KeyNotFoundException implements Exception {
  final String message;
  KeyNotFoundException(this.message);

  @override
  String toString() => 'KeyNotFoundException: $message';
}
