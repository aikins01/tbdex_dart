import 'dart:convert';
import 'dart:typed_data';
import 'package:fast_base58/fast_base58.dart';
import 'did.dart';
import 'did_document.dart';
import 'did_resolution_result.dart';
import 'did_resolver.dart';

class DIDKeyResolver implements DIDResolver {
  @override
  String get methodName => 'key';

  @override
  Future<DIDResolutionResult> resolve(String didURI) async {
    try {
      final did = DID.parse(didURI);
      if (did.methodName != methodName) {
        return DIDResolutionResult.error(DIDResolutionError.methodNotSupported);
      }

      final publicKeyBytes = Base58Decode(did.identifier.substring(1));
      final publicKeyMultibase = 'z${Base58Encode(publicKeyBytes)}';

      final verificationMethod = VerificationMethod(
        id: '${did.uri}#${did.identifier}',
        type: 'Ed25519VerificationKey2020',
        controller: did.uri,
        publicKeyMultibase: publicKeyMultibase,
      );

      final didDocument = DIDDocument(
        id: did.uri,
        verificationMethod: [verificationMethod],
        authentication: [verificationMethod.id],
        assertionMethod: [verificationMethod.id],
        capabilityInvocation: [verificationMethod.id],
        capabilityDelegation: [verificationMethod.id],
      );

      return DIDResolutionResult(
        didResolutionMetadata: {'contentType': 'application/did+ld+json'},
        didDocument: didDocument,
        didDocumentMetadata: {},
      );
    } catch (e) {
      return DIDResolutionResult.error(DIDResolutionError.invalidDID);
    }
  }
}
