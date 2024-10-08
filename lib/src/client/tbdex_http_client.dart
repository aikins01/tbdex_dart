import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ed25519_edwards/ed25519_edwards.dart' as ed;
import '../messages/cancel.dart';
import '../messages/close.dart';
import '../messages/message.dart';
import '../messages/order_instructions.dart';
import '../messages/order_status.dart';
import '../messages/rfq.dart';
import '../messages/quote.dart';
import '../messages/order.dart';
import '../resources/balance.dart';
import '../resources/offering.dart';
import '../resources/resource.dart';
import '../utils/logger.dart';
import '../utils/tbdex_error.dart';

// ignore: camel_case_types
class tbDEXHttpClient {
  static Future<String> _getPFIServiceEndpoint(String pfiDIDURI) async {
    // TODO: Implement DID resolution
    Logger.debug('Resolving DID: $pfiDIDURI');
    // For now, we'll return a placeholder
    return 'https://api.example.com/v1';
  }

  static Future<void> createExchange(RFQ rfq, ed.PublicKey publicKey) async {
    if (!rfq.verify(publicKey)) {
      throw Exception('RFQ signature is invalid');
    }

    final endpoint = await _getPFIServiceEndpoint(rfq.metadata.to);
    final response = await http.post(
      Uri.parse('$endpoint/exchanges'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'rfq': _serializeRFQ(rfq)}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to create exchange: ${response.body}');
    }
  }

  static Future<Quote> getQuote(String pfiDIDURI, String exchangeId) async {
    final endpoint = await _getPFIServiceEndpoint(pfiDIDURI);
    final response =
        await http.get(Uri.parse('$endpoint/exchanges/$exchangeId'));

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      // assuming the last message in the exchange is the Quote
      final quoteJson = jsonResponse['data'].last;
      return _parseQuote(quoteJson);
    } else {
      throw Exception('Failed to get quote: ${response.body}');
    }
  }

  static Quote _parseQuote(Map<String, dynamic> quoteJson) {
    final metadata = MessageMetadata(
      id: quoteJson['metadata']['id'],
      kind: MessageKind.quote,
      from: quoteJson['metadata']['from'],
      to: quoteJson['metadata']['to'],
      exchangeId: quoteJson['metadata']['exchangeId'],
      createdAt: DateTime.parse(quoteJson['metadata']['createdAt']),
      protocol: quoteJson['metadata']['protocol'],
    );

    final data = QuoteData(
      expiresAt: DateTime.parse(quoteJson['data']['expiresAt']),
      payoutUnitsPerPayinUnit: quoteJson['data']['payoutUnitsPerPayinUnit'],
      payin: QuoteDetails(
        currencyCode: quoteJson['data']['payin']['currencyCode'],
        subtotal: quoteJson['data']['payin']['subtotal'],
        fee: quoteJson['data']['payin']['fee'],
        total: quoteJson['data']['payin']['total'],
      ),
      payout: QuoteDetails(
        currencyCode: quoteJson['data']['payout']['currencyCode'],
        subtotal: quoteJson['data']['payout']['subtotal'],
        fee: quoteJson['data']['payout']['fee'],
        total: quoteJson['data']['payout']['total'],
      ),
    );

    return Quote(metadata: metadata, data: data);
  }

  static Future<void> submitOrder(Order order, ed.PublicKey publicKey) async {
    if (!order.verify(publicKey)) {
      throw Exception('Order signature is invalid');
    }

    final endpoint = await _getPFIServiceEndpoint(order.metadata.to);
    final response = await http.put(
      Uri.parse('$endpoint/exchanges/${order.metadata.exchangeId}'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(_serializeOrder(order)),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to submit order: ${response.body}');
    }
  }

  static Future<List<Offering>> getOfferings(String pfiDIDURI) async {
    try {
      Logger.info('Fetching offerings from PFI: $pfiDIDURI');
      final endpoint = await _getPFIServiceEndpoint(pfiDIDURI);
      final response = await http.get(Uri.parse('$endpoint/offerings'));

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        final offeringsJson = jsonResponse['data'] as List<dynamic>;
        Logger.debug('Received ${offeringsJson.length} offerings');
        return offeringsJson.map((json) => _parseOffering(json)).toList();
      } else {
        throw TbdexError(
          'Failed to fetch offerings',
          code: 'FETCH_OFFERINGS_FAILED',
          details: {'statusCode': response.statusCode, 'body': response.body},
        );
      }
    } catch (e) {
      Logger.error('Error fetching offerings: $e');
      rethrow;
    }
  }

  static Future<void> submitOffering(
      Offering offering, ed.PrivateKey privateKey) async {
    try {
      Logger.info('Submitting offering: ${offering.metadata.id}');
      offering.sign(privateKey);
      if (!offering.verify(ed.public(privateKey))) {
        throw TbdexError('Offering signature is invalid',
            code: 'INVALID_SIGNATURE');
      }

      final endpoint = await _getPFIServiceEndpoint(offering.metadata.from);
      final response = await http.post(
        Uri.parse('$endpoint/offerings'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(_serializeResource(offering)),
      );

      if (response.statusCode != 201) {
        throw TbdexError(
          'Failed to submit offering',
          code: 'SUBMIT_OFFERING_FAILED',
          details: {'statusCode': response.statusCode, 'body': response.body},
        );
      }
      Logger.info('Offering submitted successfully');
    } catch (e) {
      Logger.error('Error submitting offering: $e');
      rethrow;
    }
  }

  static Future<List<Balance>> getBalances(
      String pfiDIDURI, String userDID) async {
    try {
      Logger.info('Fetching balances for user: $userDID from PFI: $pfiDIDURI');
      final endpoint = await _getPFIServiceEndpoint(pfiDIDURI);
      final response = await http.get(
        Uri.parse('$endpoint/balances'),
        headers: {
          'Authorization': 'Bearer $userDID'
        }, // simplified auth,we would replace with proper auth mechanism
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        final balancesJson = jsonResponse['data'] as List<dynamic>;
        Logger.debug('Received ${balancesJson.length} balances');
        return balancesJson.map((json) => _parseBalance(json)).toList();
      } else {
        throw TbdexError(
          'Failed to fetch balances',
          code: 'FETCH_BALANCES_FAILED',
          details: {'statusCode': response.statusCode, 'body': response.body},
        );
      }
    } catch (e) {
      Logger.error('Error fetching balances: $e');
      rethrow;
    }
  }

  static Offering _parseOffering(Map<String, dynamic> json) {
    try {
      final metadata = ResourceMetadata(
        id: json['metadata']['id'],
        kind: ResourceKind.offering,
        from: json['metadata']['from'],
        createdAt: DateTime.parse(json['metadata']['createdAt']),
        updatedAt: json['metadata']['updatedAt'] != null
            ? DateTime.parse(json['metadata']['updatedAt'])
            : null,
        protocol: json['metadata']['protocol'],
      );

      final data = OfferingData(
        description: json['data']['description'],
        payoutUnitsPerPayinUnit: json['data']['payoutUnitsPerPayinUnit'],
        payin: PayinDetails(
          currencyCode: json['data']['payin']['currencyCode'],
          min: json['data']['payin']['min'],
          max: json['data']['payin']['max'],
          methods: (json['data']['payin']['methods'] as List<dynamic>)
              .map((m) => PaymentMethod(
                    kind: m['kind'],
                    name: m['name'],
                    description: m['description'],
                    group: m['group'],
                    requiredPaymentDetails: m['requiredPaymentDetails'],
                    fee: m['fee'],
                    min: m['min'],
                    max: m['max'],
                  ))
              .toList(),
        ),
        payout: PayoutDetails(
          currencyCode: json['data']['payout']['currencyCode'],
          min: json['data']['payout']['min'],
          max: json['data']['payout']['max'],
          methods: (json['data']['payout']['methods'] as List<dynamic>)
              .map((m) => PaymentMethod(
                    kind: m['kind'],
                    name: m['name'],
                    description: m['description'],
                    group: m['group'],
                    requiredPaymentDetails: m['requiredPaymentDetails'],
                    fee: m['fee'],
                    min: m['min'],
                    max: m['max'],
                  ))
              .toList(),
        ),
        requiredClaims: json['data']['requiredClaims'],
        cancellation: CancellationDetails(
          enabled: json['data']['cancellation']['enabled'],
          termsUrl: json['data']['cancellation']['termsUrl'] != null
              ? Uri.parse(json['data']['cancellation']['termsUrl'])
              : null,
          terms: json['data']['cancellation']['terms'],
        ),
      );

      return Offering(
        metadata: metadata,
        data: data,
        signature: json['signature'],
      );
    } catch (e) {
      Logger.error('Error parsing offering: $e');
      throw TbdexError('Failed to parse offering',
          code: 'PARSE_OFFERING_FAILED', details: e);
    }
  }

  static Balance _parseBalance(Map<String, dynamic> json) {
    try {
      final metadata = ResourceMetadata(
        id: json['metadata']['id'],
        kind: ResourceKind.balance,
        from: json['metadata']['from'],
        createdAt: DateTime.parse(json['metadata']['createdAt']),
        updatedAt: json['metadata']['updatedAt'] != null
            ? DateTime.parse(json['metadata']['updatedAt'])
            : null,
        protocol: json['metadata']['protocol'],
      );

      final data = BalanceData(
        currencyCode: json['data']['currencyCode'],
        available: json['data']['available'],
      );

      return Balance(
        metadata: metadata,
        data: data,
        signature: json['signature'],
      );
    } catch (e) {
      Logger.error('Error parsing balance: $e');
      throw TbdexError('Failed to parse balance',
          code: 'PARSE_BALANCE_FAILED', details: e);
    }
  }

  static Map<String, dynamic> _serializeResource<D extends ResourceData>(
      Resource<D> resource) {
    try {
      return {
        'metadata': resource.metadata.toJson(),
        'data': resource.data.toJson(),
        'signature': resource.signature,
      };
    } catch (e) {
      Logger.error('Error serializing resource: $e');
      throw TbdexError('Failed to serialize resource',
          code: 'SERIALIZE_RESOURCE_FAILED', details: e);
    }
  }

  static Future<OrderStatus> getLatestOrderStatus(
      String pfiDIDURI, String exchangeId) async {
    final endpoint = await _getPFIServiceEndpoint(pfiDIDURI);
    final response =
        await http.get(Uri.parse('$endpoint/exchanges/$exchangeId'));

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      final messages = jsonResponse['data'] as List<dynamic>;

      // find the latest OrderStatus message
      final latestOrderStatus = messages.reversed.firstWhere(
        (message) => message['metadata']['kind'] == 'orderstatus',
        orElse: () => throw Exception('No OrderStatus found for this exchange'),
      );

      return _parseOrderStatus(latestOrderStatus);
    } else {
      throw Exception('Failed to get order status: ${response.body}');
    }
  }

  static OrderStatus _parseOrderStatus(Map<String, dynamic> orderStatusJson) {
    final metadata = MessageMetadata(
      id: orderStatusJson['metadata']['id'],
      kind: MessageKind.orderStatus,
      from: orderStatusJson['metadata']['from'],
      to: orderStatusJson['metadata']['to'],
      exchangeId: orderStatusJson['metadata']['exchangeId'],
      createdAt: DateTime.parse(orderStatusJson['metadata']['createdAt']),
      protocol: orderStatusJson['metadata']['protocol'],
    );

    final data = OrderStatusData(
      status: Status.values.firstWhere(
        (s) =>
            s.toString().split('.').last == orderStatusJson['data']['status'],
      ),
      details: orderStatusJson['data']['details'],
    );

    return OrderStatus(
      metadata: metadata,
      data: data,
      signature: orderStatusJson['signature'],
    );
  }

  static Map<String, dynamic> _serializeRFQ(RFQ rfq) {
    return {
      'metadata': rfq.metadata.toJson(),
      'data': rfq.data.toJson(),
      'signature': rfq.signature,
    };
  }

  static Map<String, dynamic> _serializeOrder(Order order) {
    return {
      'metadata': order.metadata.toJson(),
      'data': order.data.toJson(),
      'signature': order.signature,
    };
  }

  static Future<void> submitCancel(
      Cancel cancel, ed.PublicKey publicKey) async {
    if (!cancel.verify(publicKey)) {
      throw Exception('Cancel signature is invalid');
    }

    final endpoint = await _getPFIServiceEndpoint(cancel.metadata.to);
    final response = await http.put(
      Uri.parse('$endpoint/exchanges/${cancel.metadata.exchangeId}'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(_serializeMessage(cancel)),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to submit cancel: ${response.body}');
    }
  }

  static Future<void> submitClose(Close close, ed.PublicKey publicKey) async {
    if (!close.verify(publicKey)) {
      throw Exception('Close signature is invalid');
    }

    final endpoint = await _getPFIServiceEndpoint(close.metadata.to);
    final response = await http.put(
      Uri.parse('$endpoint/exchanges/${close.metadata.exchangeId}'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(_serializeMessage(close)),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to submit close: ${response.body}');
    }
  }

  static Future<OrderInstructions> getLatestOrderInstructions(
      String pfiDIDURI, String exchangeId) async {
    final endpoint = await _getPFIServiceEndpoint(pfiDIDURI);
    final response =
        await http.get(Uri.parse('$endpoint/exchanges/$exchangeId'));

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      final messages = jsonResponse['data'] as List<dynamic>;

      // Find the latest OrderInstructions message
      final latestOrderInstructions = messages.reversed.firstWhere(
        (message) => message['metadata']['kind'] == 'orderinstructions',
        orElse: () =>
            throw Exception('No OrderInstructions found for this exchange'),
      );

      return _parseOrderInstructions(latestOrderInstructions);
    } else {
      throw Exception('Failed to get order instructions: ${response.body}');
    }
  }

  static OrderInstructions _parseOrderInstructions(
      Map<String, dynamic> orderInstructionsJson) {
    final metadata = MessageMetadata(
      id: orderInstructionsJson['metadata']['id'],
      kind: MessageKind.orderInstructions,
      from: orderInstructionsJson['metadata']['from'],
      to: orderInstructionsJson['metadata']['to'],
      exchangeId: orderInstructionsJson['metadata']['exchangeId'],
      createdAt: DateTime.parse(orderInstructionsJson['metadata']['createdAt']),
      protocol: orderInstructionsJson['metadata']['protocol'],
    );

    final data = OrderInstructionsData(
      payin: PaymentInstruction(
        link: orderInstructionsJson['data']['payin']['link'],
        instruction: orderInstructionsJson['data']['payin']['instruction'],
      ),
      payout: PaymentInstruction(
        link: orderInstructionsJson['data']['payout']['link'],
        instruction: orderInstructionsJson['data']['payout']['instruction'],
      ),
    );

    return OrderInstructions(
      metadata: metadata,
      data: data,
      signature: orderInstructionsJson['signature'],
    );
  }

  static Map<String, dynamic> _serializeMessage<T extends MessageData>(
      Message<T> message) {
    return {
      'metadata': message.metadata.toJson(),
      'data': message.data.toJson(),
      'signature': message.signature,
    };
  }
}
