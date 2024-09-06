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
    final regex = RegExp(
        r'^did:([a-z0-9]+):([a-zA-Z0-9._-]+)((?:;[a-zA-Z0-9_.:%-]+=[a-zA-Z0-9_.:%-]*)*)(\/[^?#]*)?\??([^#]*)?(#.*)?$');
    final match = regex.firstMatch(didURI);

    if (match == null) {
      throw const FormatException('Invalid DID URI');
    }

    final methodName = match.group(1)!;
    final identifier = match.group(2)!;
    final paramsString = match.group(3);
    final path = match.group(4);
    final query = match.group(5);
    final fragment = match.group(6);

    Map<String, String>? params;
    if (paramsString != null && paramsString.isNotEmpty) {
      params = {};
      final paramPairs = paramsString.substring(1).split(';');
      for (final pair in paramPairs) {
        final keyValue = pair.split('=');
        if (keyValue.length == 2) {
          params[keyValue[0]] = keyValue[1];
        }
      }
    }

    return DID(
      uri: didURI,
      methodName: methodName,
      identifier: identifier,
      params: params,
      path: path,
      query: query,
      fragment: fragment?.substring(1),
    );
  }

  @override
  String toString() => uri;
}
