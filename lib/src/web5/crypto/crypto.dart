import 'dart:typed_data';
import 'package:pointycastle/export.dart';

class Crypto {
  static final _secureRandom = FortunaRandom();

  static void _initSecureRandom() {
    _secureRandom.seed(KeyParameter(Uint8List.fromList(
        DateTime.now().millisecondsSinceEpoch.toRadixString(16).codeUnits)));
  }

  static Uint8List generatePrivateKey(String algorithm) {
    _initSecureRandom();
    switch (algorithm) {
      case 'Ed25519':
        final params = ECKeyGeneratorParameters(ECDomainParameters('ed25519'));
        final keyGenerator = ECKeyGenerator();
        keyGenerator.init(ParametersWithRandom(params, _secureRandom));
        final keypair = keyGenerator.generateKeyPair();
        return (keypair.privateKey as ECPrivateKey).d!.toBytes();
      case 'secp256k1':
        final params =
            ECKeyGeneratorParameters(ECDomainParameters('secp256k1'));
        final keyGenerator = ECKeyGenerator();
        keyGenerator.init(ParametersWithRandom(params, _secureRandom));
        final keypair = keyGenerator.generateKeyPair();
        return (keypair.privateKey as ECPrivateKey).d!.toBytes();
      default:
        throw UnsupportedError('Unsupported algorithm: $algorithm');
    }
  }

  static Uint8List computePublicKey(Uint8List privateKey, String algorithm) {
    switch (algorithm) {
      case 'Ed25519':
        final curve = ECDomainParameters('ed25519');
        final q = curve.G * BigInt.parse(privateKey.toString());
        return q!.getEncoded(false);
      case 'secp256k1':
        final curve = ECDomainParameters('secp256k1');
        final q = curve.G * BigInt.parse(privateKey.toString());
        return q!.getEncoded(false);
      default:
        throw UnsupportedError('Unsupported algorithm: $algorithm');
    }
  }

  static Uint8List sign(
      Uint8List payload, Uint8List privateKey, String algorithm) {
    switch (algorithm) {
      case 'Ed25519':
        final signer = Signer('Ed25519');
        final params = PrivateKeyParameter(ECPrivateKey(
            BigInt.parse(privateKey.toString()),
            ECDomainParameters('ed25519')));
        signer.init(true, params);
        final signature = signer.generateSignature(payload) as ECSignature;
        return Uint8List.fromList(
            signature.r!.toBytes() + signature.s!.toBytes());
      case 'secp256k1':
        final signer = Signer('SHA-256/ECDSA');
        final params = PrivateKeyParameter(ECPrivateKey(
            BigInt.parse(privateKey.toString()),
            ECDomainParameters('secp256k1')));
        signer.init(true, params);
        final signature = signer.generateSignature(payload) as ECSignature;
        return Uint8List.fromList(
            signature.r!.toBytes() + signature.s!.toBytes());
      default:
        throw UnsupportedError('Unsupported algorithm: $algorithm');
    }
  }

  static bool verify(Uint8List payload, Uint8List signature,
      Uint8List publicKey, String algorithm) {
    switch (algorithm) {
      case 'Ed25519':
        final verifier = Signer('Ed25519');
        final curve = ECDomainParameters('ed25519');
        final params = PublicKeyParameter(
            ECPublicKey(curve.curve.decodePoint(publicKey), curve));
        verifier.init(false, params);
        final ecSignature = ECSignature(
          BigInt.parse(signature.sublist(0, 32).toString()),
          BigInt.parse(signature.sublist(32).toString()),
        );
        return verifier.verifySignature(payload, ecSignature);
      case 'secp256k1':
        final verifier = Signer('SHA-256/ECDSA');
        final curve = ECDomainParameters('secp256k1');
        final params = PublicKeyParameter(
            ECPublicKey(curve.curve.decodePoint(publicKey), curve));
        verifier.init(false, params);
        final ecSignature = ECSignature(
          BigInt.parse(signature.sublist(0, 32).toString()),
          BigInt.parse(signature.sublist(32).toString()),
        );
        return verifier.verifySignature(payload, ecSignature);
      default:
        throw UnsupportedError('Unsupported algorithm: $algorithm');
    }
  }
}

extension BigIntExtension on BigInt {
  Uint8List toBytes() {
    var hex = toRadixString(16);
    if (hex.length % 2 != 0) hex = '0$hex';
    return Uint8List.fromList(
        hex.split('').map((e) => int.parse(e, radix: 16)).toList());
  }
}
