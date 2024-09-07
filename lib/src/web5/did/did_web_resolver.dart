import 'dart:convert';
import 'package:http/http.dart' as http;
import 'did.dart';
import 'did_document.dart';
import 'did_resolution_result.dart';
import 'did_resolver.dart';

class DIDWebResolver implements DIDResolver {
  @override
  String get methodName => 'web';

  @override
  Future<DIDResolutionResult> resolve(String didURI) async {
    try {
      final did = DID.parse(didURI);
      if (did.methodName != methodName) {
        return DIDResolutionResult.error(DIDResolutionError.methodNotSupported);
      }

      final url = _constructUrl(did);
      final response = await http.get(Uri.parse(url));

      if (response.statusCode != 200) {
        return DIDResolutionResult.error(DIDResolutionError.notFound);
      }

      final didDocument = DIDDocument.fromJson(json.decode(response.body));

      return DIDResolutionResult(
        didResolutionMetadata: {'contentType': 'application/did+ld+json'},
        didDocument: didDocument,
        didDocumentMetadata: {},
      );
    } catch (e) {
      return DIDResolutionResult.error(DIDResolutionError.invalidDID);
    }
  }

  String _constructUrl(DID did) {
    final domain = did.identifier.replaceAll(':', '/');
    return 'https://$domain/.well-known/did.json';
  }
}
