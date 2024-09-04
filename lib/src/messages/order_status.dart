import 'package:typeid/typeid.dart';
import 'message.dart';

class OrderStatusData implements MessageData {
  final Status status;
  final String? details;

  OrderStatusData({
    required this.status,
    this.details,
  });

  @override
  MessageKind kind() => MessageKind.orderStatus;

  @override
  Map<String, dynamic> toJson() => {
        'status': status.toString().split('.').last,
        if (details != null) 'details': details,
      };
}

enum Status {
  payinPending,
  payinInitiated,
  payinSettled,
  payinFailed,
  payinExpired,
  payoutPending,
  payoutInitiated,
  payoutSettled,
  payoutFailed,
  refundPending,
  refundInitiated,
  refundFailed,
  refundSettled,
}

typedef OrderStatus = Message<OrderStatusData>;

extension OrderStatusExtension on OrderStatus {
  static OrderStatus create({
    required String from,
    required String to,
    required String exchangeId,
    required Status status,
    String? details,
    String protocol = "1.0",
  }) {
    final id = TypeId.generate('orderstatus');
    final metadata = MessageMetadata(
      id: id,
      kind: MessageKind.orderStatus,
      from: from,
      to: to,
      exchangeId: exchangeId,
      createdAt: DateTime.now(),
      protocol: protocol,
    );

    final data = OrderStatusData(status: status, details: details);

    return OrderStatus(metadata: metadata, data: data);
  }
}
