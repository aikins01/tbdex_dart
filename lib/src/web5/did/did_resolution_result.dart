import 'did_document.dart';

class DIDResolutionResult {
  final Map<String, dynamic> didResolutionMetadata;
  final DIDDocument? didDocument;
  final Map<String, dynamic> didDocumentMetadata;

  DIDResolutionResult({
    required this.didResolutionMetadata,
    this.didDocument,
    required this.didDocumentMetadata,
  });

  factory DIDResolutionResult.error(DIDResolutionError error) {
    return DIDResolutionResult(
      didResolutionMetadata: {'error': error.toString().split('.').last},
      didDocumentMetadata: {},
    );
  }
}

enum DIDResolutionError {
  invalidDID,
  notFound,
  methodNotSupported,
  internalError
}
