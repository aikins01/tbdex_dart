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

  static Future<void> submitOrder(Order order) async {
    if (!await order.verify()) {
      throw Exception('Order signature is invalid');
    }

    final endpoint = await _getPFIServiceEndpoint(order.metadata.to);
    final response = await http.put(
      Uri.parse('$endpoint/exchanges/${order.metadata.exchangeId}'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(order),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to submit order: ${response.body}');
    }
  }

  static Future<String> _getPFIServiceEndpoint(String pfiDIDURI) async {
    // TODO: Implement DID resolution
    // For now, we'll return a placeholder
    return 'https://api.example.com/v1';
  }
}
