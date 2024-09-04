enum ResourceKind {
  offering,
  balance,
}

abstract class ResourceData {
  ResourceKind kind();
}

class ResourceMetadata {
  final String id;
  final ResourceKind kind;
  final String from;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String protocol;

  ResourceMetadata({
    required this.id,
    required this.kind,
    required this.from,
    required this.createdAt,
    this.updatedAt,
    required this.protocol,
  });
}

class Resource<D extends ResourceData> {
  final ResourceMetadata metadata;
  final D data;
  String? signature;

  Resource({
    required this.metadata,
    required this.data,
    this.signature,
  });

  Future<bool> verify() async {
    // TODO: Implement verification logic
    throw UnimplementedError();
  }

  Future<void> sign() async {
    // TODO: Implement signing logic
    throw UnimplementedError();
  }
}
