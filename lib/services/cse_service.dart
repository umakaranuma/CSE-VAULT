import 'dart:convert';
import 'package:http/http.dart' as http;

class CseService {
  // Updated to your computer's local IP for physical device testing
  static const String baseUrl = 'http://192.168.8.192:8000/api/cse';

  /// Gets the full trade summary — 289 stocks with name + symbol + price.
  /// This is the best endpoint for the stock search/autocomplete.
  Future<List<dynamic>> getTradeSummary() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/trade-summary'))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // The API returns { "reqTradeSummery": [ ...stocks ] }
        if (data is Map && data.containsKey('reqTradeSummery')) {
          return data['reqTradeSummery'] as List<dynamic>;
        }
        if (data is List) return data;
        return [];
      }
      throw Exception('Server returned ${response.statusCode}');
    } catch (e) {
      debugPrintThrottled('Error fetching trade summary: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getCompanyInfo(String symbol) async {
    final response = await http.post(
      Uri.parse('$baseUrl/company-info'),
      body: {'symbol': symbol},
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Failed to load company info');
  }

  Future<List<dynamic>> getTodaySharePrices() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/today-prices'))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      throw Exception('Server returned ${response.statusCode}');
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getMarketStatus() async {
    final response = await http.get(Uri.parse('$baseUrl/market-status'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Failed to load market status');
  }

  Future<Map<String, dynamic>> getChartData(String symbol) async {
    final response = await http.post(
      Uri.parse('$baseUrl/chart-data'),
      body: {'symbol': symbol},
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Failed to load chart data');
  }

  Future<List<dynamic>> getTopGainers() async {
    final response = await http.get(Uri.parse('$baseUrl/top-gainers'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Failed to load top gainers');
  }

  Future<List<dynamic>> getTopLosers() async {
    final response = await http.get(Uri.parse('$baseUrl/top-losers'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Failed to load top losers');
  }

  Future<Map<String, dynamic>> getAspiData() async {
    final response = await http.get(Uri.parse('$baseUrl/aspi-data'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Failed to load ASPI data');
  }
}

void debugPrintThrottled(String message) {
  assert(() {
    // ignore: avoid_print
    print(message);
    return true;
  }());
}
