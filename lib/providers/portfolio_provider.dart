import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/cse_service.dart';

class PortfolioProvider extends ChangeNotifier {
  final _cseService = CseService();
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  final Map<String, Stock> _stocks = {
    'AAIC.N0000': Stock(
      code: 'AAIC.N0000',
      name: 'Softlogic Life',
      todayPrice: 93.80,
      transactions: [
        Transaction(
          id: '1',
          type: 'buy',
          qty: 510,
          price: 97.90,
          dt: DateTime.parse('2026-05-06T09:30:00'),
        ),
      ],
      priceLog: [
        PriceLog(id: '101', price: 97.90, dt: DateTime.parse('2026-05-06T09:30:00'), note: 'Buy entry'),
        PriceLog(id: '102', price: 96.50, dt: DateTime.parse('2026-05-07T09:15:00'), note: 'Morning'),
        PriceLog(id: '103', price: 95.20, dt: DateTime.parse('2026-05-08T14:00:00'), note: 'Afternoon'),
        PriceLog(id: '104', price: 94.10, dt: DateTime.parse('2026-05-09T09:00:00'), note: 'Opening'),
        PriceLog(id: '105', price: 93.80, dt: DateTime.parse('2026-05-13T09:00:00'), note: 'Today open'),
      ],
    )
  };

  Map<String, Stock> get stocks => _stocks;

  double get totalInvested => _stocks.values.fold(0, (sum, s) => sum + s.holdingsCost);
  double get totalValue => _stocks.values.fold(0, (sum, s) => sum + s.holdingsValue);
  double get totalRealised => _stocks.values.fold(0, (sum, s) => sum + s.realised);
  double get totalUnrealised => totalValue - totalInvested;
  double get totalPnlPercent => totalInvested > 0 ? (totalUnrealised / totalInvested) * 100 : 0;

  void addStock(String code, String name, String type, double qty, double price, DateTime dt, double today, {double commission = 0.0}) {
    if (!_stocks.containsKey(code)) {
      _stocks[code] = Stock(
        code: code,
        name: name,
        todayPrice: today > 0 ? today : price,
        transactions: [],
        priceLog: [],
      );
    }
    _stocks[code]!.name = name;
    if (today > 0) _stocks[code]!.todayPrice = today;
    
    _stocks[code]!.transactions.insert(
      0,
      Transaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: type,
        qty: qty,
        price: price,
        dt: dt,
        commission: commission,
      ),
    );
    
    if (today > 0) {
      _stocks[code]!.priceLog.insert(
        0,
        PriceLog(
          id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
          price: today,
          dt: dt,
          note: 'Entry',
        ),
      );
    }
    notifyListeners();
  }

  void logPrice(String code, double price, DateTime dt, String note) {
    _stocks[code]?.priceLog.insert(
      0,
      PriceLog(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        price: price,
        dt: dt,
        note: note.isNotEmpty ? note : null,
      ),
    );
    _stocks[code]?.todayPrice = price;
    notifyListeners();
  }

  void updateTodayPrice(String code, double price) {
    if (price > 0) {
      _stocks[code]?.todayPrice = price;
      notifyListeners();
    }
  }

  void addTransaction(String code, String type, double qty, double price, DateTime dt, {double commission = 0.0}) {
    _stocks[code]?.transactions.insert(
      0,
      Transaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: type,
        qty: qty,
        price: price,
        dt: dt,
        commission: commission,
      ),
    );
    notifyListeners();
  }

  void deleteTransaction(String code, String id) {
    _stocks[code]?.transactions.removeWhere((t) => t.id == id);
    notifyListeners();
  }

  void deletePriceLog(String code, String id) {
    _stocks[code]?.priceLog.removeWhere((p) => p.id == id);
    notifyListeners();
  }

  Future<void> refreshPrices() async {
    if (_stocks.isEmpty) return;
    _isLoading = true;
    notifyListeners();

    try {
      final prices = await _cseService.getTodaySharePrices();
      for (var item in prices) {
        final symbol = item['symbol']?.toString();
        final lastPrice = double.tryParse(item['lastTradedPrice']?.toString() ?? '0');
        
        if (symbol != null && lastPrice != null && _stocks.containsKey(symbol)) {
          _stocks[symbol]!.todayPrice = lastPrice;
        }
      }
    } catch (e) {
      debugPrint('Error refreshing prices: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateStockFromLive(String symbol) async {
    try {
      final info = await _cseService.getCompanyInfo(symbol);
      final reqInfo = info['reqSymbolInfo'];
      if (reqInfo != null && _stocks.containsKey(symbol)) {
        final name = reqInfo['name']?.toString();
        final lastPrice = double.tryParse(reqInfo['lastTradedPrice']?.toString() ?? '0');
        
        if (name != null) _stocks[symbol]!.name = name;
        if (lastPrice != null && lastPrice > 0) _stocks[symbol]!.todayPrice = lastPrice;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating stock $symbol: $e');
    }
  }
}
