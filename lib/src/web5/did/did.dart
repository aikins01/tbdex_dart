class DID {
  final String uri;
  final String methodName;
  final String identifier;
  final Map<String, String>? params;
  final String? path;
  final String? query;
  final String? fragment;

  DID({
    required this.uri,
    required this.methodName,
    required this.identifier,
    this.params,
    this.path,
    this.query,
    this.fragment,
  });

  String get uriWithoutFragment => uri.split('#').first;

  String get uriWithoutQueryAndFragment => uriWithoutFragment.split('?').first;

  factory DID.parse(String didURI) {
    // Implement DID parsing logic here
    // This should handle the various components of a DID URI
    // For now, we'll just return a basic DID object
    return DID(
      uri: didURI,
      methodName: 'example',
      identifier: 'identifier',
    );
  }
}
