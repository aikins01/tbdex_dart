import 'package:typeid/typeid.dart';
import 'resource.dart';

class BalanceData implements ResourceData {
  final String currencyCode;
  final String available;

  BalanceData({
    required this.currencyCode,
    required this.available,
  });

  @override
  ResourceKind kind() => ResourceKind.balance;

  @override
  Map<String, dynamic> toJson() => {
        'currencyCode': currencyCode,
        'available': available,
      };
}

typedef Balance = Resource<BalanceData>;

extension BalanceExtension on Balance {
  static Balance create({
    required String from,
    required BalanceData data,
    String protocol = "1.0",
  }) {
    final id = TypeId.generate('balance');
    final now = DateTime.now();
    final metadata = ResourceMetadata(
      id: id,
      kind: ResourceKind.balance,
      from: from,
      createdAt: now,
      updatedAt: now,
      protocol: protocol,
    );

    return Balance(metadata: metadata, data: data);
  }
}
