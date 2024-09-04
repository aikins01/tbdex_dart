import 'package:typeid/typeid.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'message.dart';

class RFQData implements MessageData {
  final String offeringId;
  final SelectedPayinMethod payin;
  final SelectedPayoutMethod payout;
  final String? claimsHash;

  RFQData({
    required this.offeringId,
    required this.payin,
    required this.payout,
    this.claimsHash,
  });

  @override
  MessageKind kind() => MessageKind.rfq;
}

class SelectedPayinMethod {
  final String amount;
  final String kind;
  final String? paymentDetailsHash;

  SelectedPayinMethod({
    required this.amount,
    required this.kind,
    this.paymentDetailsHash,
  });
}

class SelectedPayoutMethod {
  final String kind;
  final String? paymentDetailsHash;

  SelectedPayoutMethod({
    required this.kind,
    this.paymentDetailsHash,
  });
}

class RFQPrivateData {
  final String salt;
  final PrivatePaymentDetails? payin;
  final PrivatePaymentDetails? payout;
  final List<String>? claims;

  RFQPrivateData({
    required this.salt,
    this.payin,
    this.payout,
    this.claims,
  });
}

class PrivatePaymentDetails {
  final Map<String, dynamic>? paymentDetails;

  PrivatePaymentDetails({this.paymentDetails});
}

typedef RFQ = Message<RFQData>;

extension RFQExtension on RFQ {
  static Future<RFQ> create({
    required String to,
    required String from,
    required CreateRFQData data,
    String? externalId,
    String protocol = "1.0",
  }) async {
    final hashedData = await _hashPrivateData(data);

    final id = TypeId.generate('rfq');
    final metadata = MessageMetadata(
      id: id,
      kind: MessageKind.rfq,
      from: from,
      to: to,
      exchangeId: id.toString(),
      createdAt: DateTime.now(),
      externalId: externalId,
      protocol: protocol,
    );

    return RFQ(metadata: metadata, data: hashedData['data'] as RFQData);
  }

  static Future<Map<String, dynamic>> _hashPrivateData(
      CreateRFQData data) async {
    final salt = _generateSalt();

    final payinHash = await _hashField(salt, data.payin.paymentDetails);
    final payoutHash = await _hashField(salt, data.payout.paymentDetails);
    final claimsHash =
        data.claims != null ? await _hashField(salt, data.claims) : null;

    final rfqData = RFQData(
      offeringId: data.offeringId,
      payin: SelectedPayinMethod(
        amount: data.payin.amount,
        kind: data.payin.kind,
        paymentDetailsHash: payinHash,
      ),
      payout: SelectedPayoutMethod(
        kind: data.payout.kind,
        paymentDetailsHash: payoutHash,
      ),
      claimsHash: claimsHash,
    );

    final privateData = RFQPrivateData(
      salt: salt,
      payin: PrivatePaymentDetails(paymentDetails: data.payin.paymentDetails),
      payout: PrivatePaymentDetails(paymentDetails: data.payout.paymentDetails),
      claims: data.claims,
    );

    return {
      'data': rfqData,
      'privateData': privateData,
    };
  }

  static String _generateSalt() {
    final random = List<int>.generate(
        16, (_) => DateTime.now().millisecondsSinceEpoch % 256);
    return base64Url.encode(random);
  }

  static Future<String> _hashField(String salt, dynamic value) async {
    final jsonEncoded = json.encode([salt, value]);
    final bytes = utf8.encode(jsonEncoded);
    final digest = sha256.convert(bytes);
    return base64Url.encode(digest.bytes);
  }
}

class CreateRFQData {
  final String offeringId;
  final CreateRFQPayinMethod payin;
  final CreateRFQPayoutMethod payout;
  final List<String>? claims;

  CreateRFQData({
    required this.offeringId,
    required this.payin,
    required this.payout,
    this.claims,
  });
}

class CreateRFQPayinMethod {
  final String amount;
  final String kind;
  final Map<String, dynamic>? paymentDetails;

  CreateRFQPayinMethod({
    required this.amount,
    required this.kind,
    this.paymentDetails,
  });
}

class CreateRFQPayoutMethod {
  final String kind;
  final Map<String, dynamic>? paymentDetails;

  CreateRFQPayoutMethod({
    required this.kind,
    this.paymentDetails,
  });
}
