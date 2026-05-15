import 'package:hive/hive.dart';

// ─── Type IDs ────────────────────────────────────────────────
// Transaction = 0, PriceLog = 1, Stock = 2

// ─── Transaction ─────────────────────────────────────────────

class Transaction extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String type; // 'buy' or 'sell'
  @HiveField(2)
  final double qty;
  @HiveField(3)
  final double price;
  @HiveField(4)
  final DateTime dt;
  @HiveField(5)
  final double commission;

  Transaction({
    required this.id,
    required this.type,
    required this.qty,
    required this.price,
    required this.dt,
    this.commission = 0.0,
  });
}

class TransactionAdapter extends TypeAdapter<Transaction> {
  @override
  final int typeId = 0;

  @override
  Transaction read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < numOfFields; i++) {
      fields[reader.readByte()] = reader.read();
    }
    return Transaction(
      id: fields[0] as String,
      type: fields[1] as String,
      qty: fields[2] as double,
      price: fields[3] as double,
      dt: fields[4] as DateTime,
      commission: (fields[5] as double?) ?? 0.0,
    );
  }

  @override
  void write(BinaryWriter writer, Transaction obj) {
    writer.writeByte(6); // number of fields
    writer.writeByte(0); writer.write(obj.id);
    writer.writeByte(1); writer.write(obj.type);
    writer.writeByte(2); writer.write(obj.qty);
    writer.writeByte(3); writer.write(obj.price);
    writer.writeByte(4); writer.write(obj.dt);
    writer.writeByte(5); writer.write(obj.commission);
  }
}

// ─── PriceLog ────────────────────────────────────────────────

class PriceLog extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final double price;
  @HiveField(2)
  final DateTime dt;
  @HiveField(3)
  final String? note;

  PriceLog({
    required this.id,
    required this.price,
    required this.dt,
    this.note,
  });
}

class PriceLogAdapter extends TypeAdapter<PriceLog> {
  @override
  final int typeId = 1;

  @override
  PriceLog read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < numOfFields; i++) {
      fields[reader.readByte()] = reader.read();
    }
    return PriceLog(
      id: fields[0] as String,
      price: fields[1] as double,
      dt: fields[2] as DateTime,
      note: fields[3] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, PriceLog obj) {
    writer.writeByte(4);
    writer.writeByte(0); writer.write(obj.id);
    writer.writeByte(1); writer.write(obj.price);
    writer.writeByte(2); writer.write(obj.dt);
    writer.writeByte(3); writer.write(obj.note);
  }
}

// ─── Stock ───────────────────────────────────────────────────

class Stock extends HiveObject {
  @HiveField(0)
  final String code;
  @HiveField(1)
  String name;
  @HiveField(2)
  double todayPrice;
  @HiveField(3)
  List<Transaction> transactions;
  @HiveField(4)
  List<PriceLog> priceLog;

  Stock({
    required this.code,
    required this.name,
    required this.todayPrice,
    List<Transaction>? transactions,
    List<PriceLog>? priceLog,
  })  : transactions = transactions ?? [],
        priceLog = priceLog ?? [];

  // ── Computed getters (same as before) ──

  double get totalBoughtQty =>
      transactions.where((t) => t.type == 'buy').fold(0, (sum, t) => sum + t.qty);
  double get totalBoughtAmount =>
      transactions.where((t) => t.type == 'buy').fold(0, (sum, t) => sum + (t.qty * t.price) + t.commission);
  double get totalSoldQty =>
      transactions.where((t) => t.type == 'sell').fold(0, (sum, t) => sum + t.qty);
  double get totalSoldAmount =>
      transactions.where((t) => t.type == 'sell').fold(0, (sum, t) => sum + (t.qty * t.price) - t.commission);

  double get holdingsQty => totalBoughtQty - totalSoldQty;
  double get avgBuyPrice => totalBoughtQty > 0 ? totalBoughtAmount / totalBoughtQty : 0;
  double get holdingsValue => holdingsQty * todayPrice;
  double get holdingsCost => holdingsQty * avgBuyPrice;

  double get unrealised => holdingsValue - holdingsCost;
  double get realised => totalSoldAmount - (totalSoldQty * avgBuyPrice);
  double get pnlPercent => holdingsCost > 0 ? (unrealised / holdingsCost) * 100 : 0;
}

class StockAdapter extends TypeAdapter<Stock> {
  @override
  final int typeId = 2;

  @override
  Stock read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < numOfFields; i++) {
      fields[reader.readByte()] = reader.read();
    }
    return Stock(
      code: fields[0] as String,
      name: fields[1] as String,
      todayPrice: fields[2] as double,
      transactions: (fields[3] as List).cast<Transaction>(),
      priceLog: (fields[4] as List).cast<PriceLog>(),
    );
  }

  @override
  void write(BinaryWriter writer, Stock obj) {
    writer.writeByte(5);
    writer.writeByte(0); writer.write(obj.code);
    writer.writeByte(1); writer.write(obj.name);
    writer.writeByte(2); writer.write(obj.todayPrice);
    writer.writeByte(3); writer.write(obj.transactions);
    writer.writeByte(4); writer.write(obj.priceLog);
  }
}
