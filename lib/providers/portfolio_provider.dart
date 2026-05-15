import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/models.dart';
import '../services/cse_service.dart';

class PortfolioProvider extends ChangeNotifier {
  final _cseService = CseService();
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  final Map<String, Stock> _stocks = {};
  Map<String, Stock> get stocks => _stocks;

  Box<Stock> get _box => Hive.box<Stock>('stocks');

  // ─── Computed portfolio totals ────────────────────────────────

  double get totalInvested => _stocks.values.fold(0, (sum, s) => sum + s.holdingsCost);
  double get totalValue => _stocks.values.fold(0, (sum, s) => sum + s.holdingsValue);
  double get totalRealised => _stocks.values.fold(0, (sum, s) => sum + s.realised);
  double get totalUnrealised => totalValue - totalInvested;
  double get totalPnlPercent => totalInvested > 0 ? (totalUnrealised / totalInvested) * 100 : 0;

  // ─── Load from Hive on startup ────────────────────────────────

  void loadFromHive() {
    _stocks.clear();
    for (final key in _box.keys) {
      final stock = _box.get(key);
      if (stock != null) {
        _stocks[stock.code] = stock;
      }
    }

    notifyListeners();
  }

  // ─── Hive persistence helpers ─────────────────────────────────

  void _saveStock(Stock stock) {
    _box.put(stock.code, stock);
  }

  void _deleteStockFromBox(String code) {
    _box.delete(code);
  }

  // ─── CRUD Operations ─────────────────────────────────────────

  void addStock(String code, String name, String type, double qty, double price, DateTime dt, double today, {double commission = 0.0}) {
    if (!_stocks.containsKey(code)) {
      _stocks[code] = Stock(
        code: code,
        name: name,
        todayPrice: today > 0 ? today : price,
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
    _saveStock(_stocks[code]!);
    notifyListeners();
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
    if (_stocks[code] != null) _saveStock(_stocks[code]!);
    notifyListeners();
  }

  void deleteTransaction(String code, String id) {
    _stocks[code]?.transactions.removeWhere((t) => t.id == id);
    if (_stocks[code] != null) _saveStock(_stocks[code]!);
    notifyListeners();
  }

  void updateTransaction(String code, String id, String type, double qty, double price, {double commission = 0.0}) {
    final stock = _stocks[code];
    if (stock == null) return;
    final idx = stock.transactions.indexWhere((t) => t.id == id);
    if (idx == -1) return;
    final old = stock.transactions[idx];
    stock.transactions[idx] = Transaction(
      id: id,
      type: type,
      qty: qty,
      price: price,
      dt: old.dt,
      commission: commission,
    );
    _saveStock(stock);
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
    if (_stocks[code] != null) _saveStock(_stocks[code]!);
    notifyListeners();
  }

  void deletePriceLog(String code, String id) {
    _stocks[code]?.priceLog.removeWhere((p) => p.id == id);
    if (_stocks[code] != null) _saveStock(_stocks[code]!);
    notifyListeners();
  }

  void updateTodayPrice(String code, double price) {
    if (price > 0) {
      _stocks[code]?.todayPrice = price;
      if (_stocks[code] != null) _saveStock(_stocks[code]!);
      notifyListeners();
    }
  }

  void deleteStock(String code) {
    _stocks.remove(code);
    _deleteStockFromBox(code);
    notifyListeners();
  }

  // ─── Live price refresh from CSE API ──────────────────────────

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
          _saveStock(_stocks[symbol]!);
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
        _saveStock(_stocks[symbol]!);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating stock $symbol: $e');
    }
  }
}
