import 'did.dart';
import 'did_resolution_result.dart';
import 'did_key_resolver.dart';
import 'did_web_resolver.dart';

abstract class DIDResolver {
  String get methodName;
  Future<DIDResolutionResult> resolve(String didURI);
}

class DIDUniversalResolver {
  static final Map<String, DIDResolver> _resolvers = {
    'key': DIDKeyResolver(),
    'web': DIDWebResolver(),
  };

  static void register(DIDResolver resolver) {
    _resolvers[resolver.methodName] = resolver;
  }

  static Future<DIDResolutionResult> resolve(String didURI) async {
    try {
      final did = DID.parse(didURI);
      final resolver = _resolvers[did.methodName];
      if (resolver == null) {
        return DIDResolutionResult.error(DIDResolutionError.methodNotSupported);
      }
      return await resolver.resolve(didURI);
    } catch (e) {
      return DIDResolutionResult.error(DIDResolutionError.invalidDID);
    }
  }
}
