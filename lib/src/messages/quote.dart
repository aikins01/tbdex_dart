import 'package:typeid/typeid.dart';
import 'message.dart';

class QuoteData implements MessageData {
  final DateTime expiresAt;
  final String payoutUnitsPerPayinUnit;
  final QuoteDetails payin;
  final QuoteDetails payout;

  QuoteData({
    required this.expiresAt,
    required this.payoutUnitsPerPayinUnit,
    required this.payin,
    required this.payout,
  });

  @override
  MessageKind kind() => MessageKind.quote;

  @override
  Map<String, dynamic> toJson() => {
        'expiresAt': expiresAt.toIso8601String(),
        'payoutUnitsPerPayinUnit': payoutUnitsPerPayinUnit,
        'payin': payin.toJson(),
        'payout': payout.toJson(),
      };
}

class QuoteDetails {
  final String currencyCode;
  final String subtotal;
  final String? fee;
  final String total;

  QuoteDetails({
    required this.currencyCode,
    required this.subtotal,
    this.fee,
    required this.total,
  });

  Map<String, dynamic> toJson() => {
        'currencyCode': currencyCode,
        'subtotal': subtotal,
        if (fee != null) 'fee': fee,
        'total': total,
      };
}

typedef Quote = Message<QuoteData>;

extension QuoteExtension on Quote {
  static Quote create({
    required String from,
    required String to,
    required String exchangeId,
    required QuoteData data,
    String protocol = "1.0",
  }) {
    final id = TypeId.generate('quote');
    final metadata = MessageMetadata(
      id: id,
      kind: MessageKind.quote,
      from: from,
      to: to,
      exchangeId: exchangeId,
      createdAt: DateTime.now(),
      protocol: protocol,
    );

    return Quote(metadata: metadata, data: data);
  }
}
