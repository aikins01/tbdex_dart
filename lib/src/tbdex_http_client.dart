import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ed25519_edwards/ed25519_edwards.dart' as ed;
import 'message.dart';
import 'order_status.dart';
import 'rfq.dart';
import 'quote.dart';
import 'order.dart';

// ignore: camel_case_types
class tbDEXHttpClient {
  static Future<List<dynamic>> getOfferings(String pfiDIDURI) async {
    final endpoint = await _getPFIServiceEndpoint(pfiDIDURI);
    final response = await http.get(Uri.parse('$endpoint/offerings'));

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      return jsonResponse['data'];
    } else {
      throw Exception('Failed to load offerings');
    }
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

  static Future<String> _getPFIServiceEndpoint(String pfiDIDURI) async {
    // TODO: Implement DID resolution
    // For now, we'll return a placeholder
    return 'https://api.example.com/v1';
  }
}
