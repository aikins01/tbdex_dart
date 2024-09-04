import 'dart:typed_data';
import 'package:fast_base58/fast_base58.dart';
import '../crypto/crypto.dart';

class DIDKey {
  static String create(String algorithm) {
    final privateKey = Crypto.generatePrivateKey(algorithm);
    final publicKey = Crypto.computePublicKey(privateKey, algorithm);
    return _publicKeyToDIDKey(publicKey, algorithm);
  }

  static String _publicKeyToDIDKey(Uint8List publicKey, String algorithm) {
    final multicodecPrefix = _getMulticodecPrefix(algorithm);
    final multicodecKey = Uint8List.fromList(multicodecPrefix + publicKey);
    return 'did:key:z${Base58Encode(multicodecKey)}';
  }

  static Uint8List _getMulticodecPrefix(String algorithm) {
    switch (algorithm) {
      case 'Ed25519':
        return Uint8List.fromList([0xed, 0x01]);
      case 'secp256k1':
        return Uint8List.fromList([0xe7, 0x01]);
      default:
        throw UnsupportedError('Unsupported algorithm: $algorithm');
    }
  }

  static bool verify(String didKey, Uint8List message, Uint8List signature) {
    final (publicKey, algorithm) = _extractPublicKeyFromDIDKey(didKey);
    return Crypto.verify(message, signature, publicKey, algorithm);
  }

  static (Uint8List, String) _extractPublicKeyFromDIDKey(String didKey) {
    if (!didKey.startsWith('did:key:z')) {
      throw const FormatException('Invalid did:key format');
    }

    final multicodecKey = Uint8List.fromList(Base58Decode(didKey.substring(9)));
    final prefix = multicodecKey.sublist(0, 2);
    final publicKey = multicodecKey.sublist(2);

    String algorithm;
    if (prefix[0] == 0xed && prefix[1] == 0x01) {
      algorithm = 'Ed25519';
    } else if (prefix[0] == 0xe7 && prefix[1] == 0x01) {
      algorithm = 'secp256k1';
    } else {
      throw UnsupportedError('Unsupported key type in did:key');
    }

    return (publicKey, algorithm);
  }
}
