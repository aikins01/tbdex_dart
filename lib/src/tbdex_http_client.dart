import 'dart:convert';
import 'package:http/http.dart' as http;
import 'message.dart';
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

  static Future<void> createExchange(RFQ rfq) async {
    if (!await rfq.verify()) {
      throw Exception('RFQ signature is invalid');
    }

    final endpoint = await _getPFIServiceEndpoint(rfq.metadata.to);
    final response = await http.post(
      Uri.parse('$endpoint/exchanges'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'rfq': rfq}),
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

  static Future<void> submitOrder(Order order) async {
    if (order.signature == null) {
      throw Exception('Order must be signed before submission');
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

  static Map<String, dynamic> _serializeOrder(Order order) {
    return {
      'metadata': {
        'id': order.metadata.id,
        'kind': order.metadata.kind.toString().split('.').last,
        'from': order.metadata.from,
        'to': order.metadata.to,
        'exchangeId': order.metadata.exchangeId,
        'createdAt': order.metadata.createdAt.toIso8601String(),
        'protocol': order.metadata.protocol,
      },
      'data': {}, // OrderData is empty
      'signature': order.signature,
    };
  }

  static Future<String> _getPFIServiceEndpoint(String pfiDIDURI) async {
    // TODO: Implement DID resolution
    // For now, we'll return a placeholder
    return 'https://api.example.com/v1';
  }
}
