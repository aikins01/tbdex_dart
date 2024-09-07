import 'dart:typed_data';
import '../key_manager/key_manager.dart';
import '../key_manager/jwk.dart';
import '../crypto/crypto.dart';
import 'did.dart';
import 'did_document.dart';
import 'package:fast_base58/fast_base58.dart';

class BearerDID {
  final DID did;
  final DIDDocument document;
  final KeyManager keyManager;
  final Map<String, dynamic>? metadata;

  BearerDID({
    required this.did,
    required this.document,
    required this.keyManager,
    this.metadata,
  });

  Future<Uint8List> sign(Uint8List payload,
      {String? verificationMethodId}) async {
    final methodId =
        verificationMethodId ?? document.verificationMethod?.first.id;
    if (methodId == null) {
      throw Exception('No verification method available for signing');
    }

    final keyAlias = methodId.split('#').last;
    return await keyManager.sign(keyAlias, payload);
  }

  Future<bool> verify(Uint8List payload, Uint8List signature,
      {String? verificationMethodId}) async {
    final methodId =
        verificationMethodId ?? document.verificationMethod?.first.id;
    if (methodId == null) {
      throw Exception('No verification method available for verification');
    }

    final method =
        document.verificationMethod?.firstWhere((vm) => vm.id == methodId);
    if (method == null) {
      throw Exception('Verification method not found');
    }

    final publicKey = await keyManager.getPublicKey(methodId.split('#').last);
    final algorithm = _getAlgorithmFromVerificationMethod(method);

    return Crypto.verify(payload, signature, publicKey, algorithm);
  }

  String _getAlgorithmFromVerificationMethod(VerificationMethod method) {
    switch (method.type) {
      case 'Ed25519VerificationKey2018':
      case 'Ed25519VerificationKey2020':
        return 'Ed25519';
      case 'EcdsaSecp256k1VerificationKey2019':
        return 'secp256k1';
      default:
        throw Exception('Unsupported verification method type: ${method.type}');
    }
  }

  static Future<BearerDID> create(KeyManager keyManager,
      {String algorithm = 'Ed25519'}) async {
    final keyAlias = await keyManager.generatePrivateKey(algorithm);
    final publicKey = await keyManager.getPublicKey(keyAlias);

    final jwk = Jwk.fromPublicKey(publicKey, algorithm);
    final did = DID(
      uri: 'did:key:z${Base58Encode(publicKey)}',
      methodName: 'key',
      identifier: 'z${Base58Encode(publicKey)}',
    );

    final verificationMethod = VerificationMethod(
      id: '${did.uri}#$keyAlias',
      type: algorithm == 'Ed25519'
          ? 'Ed25519VerificationKey2020'
          : 'EcdsaSecp256k1VerificationKey2019',
      controller: did.uri,
      publicKeyJwk: jwk.toJson(),
    );

    final document = DIDDocument(
      id: did.uri,
      verificationMethod: [verificationMethod],
      authentication: [verificationMethod.id],
      assertionMethod: [verificationMethod.id],
      capabilityInvocation: [verificationMethod.id],
      capabilityDelegation: [verificationMethod.id],
    );

    return BearerDID(
      did: did,
      document: document,
      keyManager: keyManager,
    );
  }
}
