class Transaction {
  final String id;
  final String type; // 'buy' or 'sell'
  final double qty;
  final double price;
  final DateTime dt;

  Transaction({
    required this.id,
    required this.type,
    required this.qty,
    required this.price,
    required this.dt,
  });
}

class PriceLog {
  final String id;
  final double price;
  final DateTime dt;
  final String? note;

  PriceLog({
    required this.id,
    required this.price,
    required this.dt,
    this.note,
  });
}

class Stock {
  final String code;
  String name;
  double todayPrice;
  List<Transaction> transactions;
  List<PriceLog> priceLog;

  Stock({
    required this.code,
    required this.name,
    required this.todayPrice,
    this.transactions = const [],
    this.priceLog = const [],
  });

  double get totalBoughtQty =>
      transactions.where((t) => t.type == 'buy').fold(0, (sum, t) => sum + t.qty);
  double get totalBoughtAmount =>
      transactions.where((t) => t.type == 'buy').fold(0, (sum, t) => sum + (t.qty * t.price));
  double get totalSoldQty =>
      transactions.where((t) => t.type == 'sell').fold(0, (sum, t) => sum + t.qty);
  double get totalSoldAmount =>
      transactions.where((t) => t.type == 'sell').fold(0, (sum, t) => sum + (t.qty * t.price));

  double get holdingsQty => totalBoughtQty - totalSoldQty;
  double get avgBuyPrice => totalBoughtQty > 0 ? totalBoughtAmount / totalBoughtQty : 0;
  double get holdingsValue => holdingsQty * todayPrice;
  double get holdingsCost => holdingsQty * avgBuyPrice;

  double get unrealised => holdingsValue - holdingsCost;
  double get realised => totalSoldAmount - (totalSoldQty * avgBuyPrice);
  double get pnlPercent => holdingsCost > 0 ? (unrealised / holdingsCost) * 100 : 0;
}
