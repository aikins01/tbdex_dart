import 'package:typeid/typeid.dart';
import 'resource.dart';

class OfferingData implements ResourceData {
  final String description;
  final String payoutUnitsPerPayinUnit;
  final PayinDetails payin;
  final PayoutDetails payout;
  final dynamic
      requiredClaims; // this should be a PresentationDefinitionV2, but we'll use dynamic for now
  final CancellationDetails cancellation;

  OfferingData({
    required this.description,
    required this.payoutUnitsPerPayinUnit,
    required this.payin,
    required this.payout,
    this.requiredClaims,
    required this.cancellation,
  });

  @override
  ResourceKind kind() => ResourceKind.offering;

  @override
  Map<String, dynamic> toJson() => {
        'description': description,
        'payoutUnitsPerPayinUnit': payoutUnitsPerPayinUnit,
        'payin': payin.toJson(),
        'payout': payout.toJson(),
        if (requiredClaims != null) 'requiredClaims': requiredClaims,
        'cancellation': cancellation.toJson(),
      };
}

class PayinDetails {
  final String currencyCode;
  final String? min;
  final String? max;
  final List<PaymentMethod> methods;

  PayinDetails({
    required this.currencyCode,
    this.min,
    this.max,
    required this.methods,
  });

  Map<String, dynamic> toJson() => {
        'currencyCode': currencyCode,
        if (min != null) 'min': min,
        if (max != null) 'max': max,
        'methods': methods.map((m) => m.toJson()).toList(),
      };
}

class PayoutDetails {
  final String currencyCode;
  final String? min;
  final String? max;
  final List<PaymentMethod> methods;

  PayoutDetails({
    required this.currencyCode,
    this.min,
    this.max,
    required this.methods,
  });

  Map<String, dynamic> toJson() => {
        'currencyCode': currencyCode,
        if (min != null) 'min': min,
        if (max != null) 'max': max,
        'methods': methods.map((m) => m.toJson()).toList(),
      };
}

class PaymentMethod {
  final String kind;
  final String? name;
  final String? description;
  final String? group;
  final dynamic
      requiredPaymentDetails; // this should be a JSONSchema, but we'll use dynamic for now
  final String? fee;
  final String? min;
  final String? max;

  PaymentMethod({
    required this.kind,
    this.name,
    this.description,
    this.group,
    this.requiredPaymentDetails,
    this.fee,
    this.min,
    this.max,
  });

  Map<String, dynamic> toJson() => {
        'kind': kind,
        if (name != null) 'name': name,
        if (description != null) 'description': description,
        if (group != null) 'group': group,
        if (requiredPaymentDetails != null)
          'requiredPaymentDetails': requiredPaymentDetails,
        if (fee != null) 'fee': fee,
        if (min != null) 'min': min,
        if (max != null) 'max': max,
      };
}

class CancellationDetails {
  final bool enabled;
  final Uri? termsUrl;
  final String? terms;

  CancellationDetails({
    required this.enabled,
    this.termsUrl,
    this.terms,
  });

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        if (termsUrl != null) 'termsUrl': termsUrl.toString(),
        if (terms != null) 'terms': terms,
      };
}

typedef Offering = Resource<OfferingData>;

extension OfferingExtension on Offering {
  static Offering create({
    required String from,
    required OfferingData data,
    String protocol = "1.0",
  }) {
    final id = TypeId.generate('offering');
    final now = DateTime.now();
    final metadata = ResourceMetadata(
      id: id,
      kind: ResourceKind.offering,
      from: from,
      createdAt: now,
      updatedAt: now,
      protocol: protocol,
    );

    return Offering(metadata: metadata, data: data);
  }
}
