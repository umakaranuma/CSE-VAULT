import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';
import '../../providers/portfolio_provider.dart';
import '../../models/models.dart';
import '../../utils/formatters.dart';

class HistoryItem {
  final Transaction t;
  final String sc;
  final String sn;
  final double todayPrice;
  final double avgBuyPrice;

  HistoryItem(this.t, this.sc, this.sn, this.todayPrice, this.avgBuyPrice);

  double get totalAmount => t.qty * t.price;
  double get pnl {
    if (t.type == 'buy') {
      return (todayPrice - t.price) * t.qty - t.commission;
    } else {
      return (t.price - avgBuyPrice) * t.qty - t.commission;
    }
  }
}

enum DateFilter { all, today, week, month, year }
enum PnlFilter { all, gain, loss }

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _stockFilter = 'all';
  DateFilter _dateFilter = DateFilter.all;
  PnlFilter _pnlFilter = PnlFilter.all;

  List<HistoryItem> _buildItems(PortfolioProvider provider) {
    final List<HistoryItem> all = [];
    for (final s in provider.stocks.values) {
      for (final t in s.transactions) {
        all.add(HistoryItem(t, s.code, s.name, s.todayPrice, s.avgBuyPrice));
      }
    }
    all.sort((a, b) => b.t.dt.compareTo(a.t.dt));
    return all;
  }

  List<HistoryItem> _applyFilters(List<HistoryItem> items) {
    var filtered = items.toList();

    // Stock filter
    if (_stockFilter != 'all') {
      filtered = filtered.where((i) => i.sc == _stockFilter).toList();
    }

    // Date filter
    final now = DateTime.now();
    switch (_dateFilter) {
      case DateFilter.today:
        filtered = filtered.where((i) =>
            i.t.dt.year == now.year && i.t.dt.month == now.month && i.t.dt.day == now.day).toList();
        break;
      case DateFilter.week:
        final weekAgo = now.subtract(const Duration(days: 7));
        filtered = filtered.where((i) => i.t.dt.isAfter(weekAgo)).toList();
        break;
      case DateFilter.month:
        filtered = filtered.where((i) =>
            i.t.dt.year == now.year && i.t.dt.month == now.month).toList();
        break;
      case DateFilter.year:
        filtered = filtered.where((i) => i.t.dt.year == now.year).toList();
        break;
      case DateFilter.all:
        break;
    }

    // P&L filter
    if (_pnlFilter == PnlFilter.gain) {
      filtered = filtered.where((i) => i.pnl >= 0).toList();
    } else if (_pnlFilter == PnlFilter.loss) {
      filtered = filtered.where((i) => i.pnl < 0).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PortfolioProvider>(
      builder: (context, provider, child) {
        final allItems = _buildItems(provider);
        final filtered = _applyFilters(allItems);

        // Summary stats from filtered items
        final totalBuy = filtered.where((i) => i.t.type == 'buy').fold<double>(0, (s, i) => s + i.totalAmount);
        final totalSell = filtered.where((i) => i.t.type == 'sell').fold<double>(0, (s, i) => s + i.totalAmount);
        final totalPnl = filtered.fold<double>(0, (s, i) => s + i.pnl);
        final buyCount = filtered.where((i) => i.t.type == 'buy').length;
        final sellCount = filtered.where((i) => i.t.type == 'sell').length;

        // Stock codes for filter
        final codes = <String>{'all'};
        for (final i in allItems) {
          codes.add(i.sc);
        }

        // Per-stock P&L breakdown
        final stockPnl = <String, double>{};
        final stockNames = <String, String>{};
        for (final i in filtered) {
          stockPnl[i.sc] = (stockPnl[i.sc] ?? 0) + i.pnl;
          stockNames[i.sc] = i.sn;
        }
        final sortedStockPnl = stockPnl.entries.toList()
          ..sort((a, b) => b.value.abs().compareTo(a.value.abs()));

        return CustomScrollView(
          slivers: [
            // ── Title
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 6),
                child: Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('History', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                          SizedBox(height: 3),
                          Text('Investment summary & transactions', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.t2)),
                        ],
                      ),
                    ),
                    // Reset filters
                    if (_stockFilter != 'all' || _dateFilter != DateFilter.all || _pnlFilter != PnlFilter.all)
                      GestureDetector(
                        onTap: () => setState(() {
                          _stockFilter = 'all';
                          _dateFilter = DateFilter.all;
                          _pnlFilter = PnlFilter.all;
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0x1AFF4D6A),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0x33FF4D6A)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(LucideIcons.x, size: 12, color: AppColors.red),
                              SizedBox(width: 4),
                              Text('Reset', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.red)),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // ── Summary Cards
            SliverToBoxAdapter(child: _buildSummaryCards(totalBuy, totalSell, totalPnl, buyCount, sellCount, filtered.length)),

            // ── Date Filter Row
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: DateFilter.values.map((f) {
                    final label = f == DateFilter.all ? 'All Time' : f == DateFilter.today ? 'Today' : f == DateFilter.week ? 'Week' : f == DateFilter.month ? 'Month' : 'Year';
                    final isOn = _dateFilter == f;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _dateFilter = f),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: isOn ? const Color(0x1A00FFA3) : AppColors.glass,
                            border: Border.all(color: isOn ? const Color(0x4000FFA3) : AppColors.border),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isOn ? AppColors.em : AppColors.t2)),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            // ── P&L Filter + Stock Filter Row
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: Row(
                  children: [
                    // Gain/Loss pills
                    ...PnlFilter.values.map((f) {
                      final label = f == PnlFilter.all ? 'All' : f == PnlFilter.gain ? '📈 Gains' : '📉 Losses';
                      final isOn = _pnlFilter == f;
                      final color = f == PnlFilter.gain ? AppColors.em : f == PnlFilter.loss ? AppColors.red : AppColors.blue;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: GestureDetector(
                          onTap: () => setState(() => _pnlFilter = f),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                              color: isOn ? color.withValues(alpha: 0.15) : AppColors.glass,
                              border: Border.all(color: isOn ? color.withValues(alpha: 0.4) : AppColors.border),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isOn ? color : AppColors.t2)),
                          ),
                        ),
                      );
                    }),
                    const Spacer(),
                    // Stock dropdown
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: AppColors.glass,
                        border: Border.all(color: _stockFilter != 'all' ? const Color(0x4000FFA3) : AppColors.border),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _stockFilter,
                          isDense: true,
                          dropdownColor: AppColors.s3,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                          icon: const Icon(LucideIcons.chevronDown, size: 14, color: AppColors.t2),
                          items: codes.map((c) => DropdownMenuItem(
                            value: c,
                            child: Text(c == 'all' ? 'All Stocks' : c.replaceAll('.N0000', ''), style: TextStyle(color: _stockFilter == c ? AppColors.em : AppColors.t2)),
                          )).toList(),
                          onChanged: (v) => setState(() => _stockFilter = v ?? 'all'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Stock P&L Breakdown (collapsible)
            if (sortedStockPnl.length > 1)
              SliverToBoxAdapter(child: _buildStockBreakdown(sortedStockPnl, stockNames)),

            const SliverToBoxAdapter(child: SizedBox(height: 10)),

            // ── Transaction List
            if (filtered.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 24),
                  child: Column(
                    children: [
                      const Text('🕐', style: TextStyle(fontSize: 48)),
                      const SizedBox(height: 16),
                      const Text('No transactions', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, letterSpacing: -0.2)),
                      const SizedBox(height: 8),
                      Text(
                        _stockFilter != 'all' || _dateFilter != DateFilter.all || _pnlFilter != PnlFilter.all
                            ? 'Try adjusting your filters.'
                            : 'Your buy and sell history will appear here.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 13, color: AppColors.t2, height: 1.6),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildTransactionCard(filtered[index]),
                    childCount: filtered.length,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  // ─── Summary Cards ────────────────────────────────────────────

  Widget _buildSummaryCards(double totalBuy, double totalSell, double totalPnl, int buyCount, int sellCount, int totalCount) {
    final isUp = totalPnl >= 0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Column(
        children: [
          // Main P&L Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isUp
                    ? [const Color(0x1A00FFA3), const Color(0x0A00FFA3)]
                    : [const Color(0x1AFF4D6A), const Color(0x0AFF4D6A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: isUp ? const Color(0x3300FFA3) : const Color(0x33FF4D6A)),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(isUp ? LucideIcons.trendingUp : LucideIcons.trendingDown, size: 16, color: isUp ? AppColors.em : AppColors.red),
                    const SizedBox(width: 8),
                    Text('NET P&L', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: isUp ? AppColors.em : AppColors.red, letterSpacing: 1.2)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0x20FFFFFF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('$totalCount txns', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.t2)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '${isUp ? '+' : ''}LKR ${Formatters.compactCurrency(totalPnl)}',
                  style: GoogleFonts.jetBrainsMono(fontSize: 28, fontWeight: FontWeight.w800, color: isUp ? AppColors.em : AppColors.red, letterSpacing: -0.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Buy / Sell summary row
          Row(
            children: [
              Expanded(child: _buildMiniStat('BOUGHT', totalBuy, buyCount, AppColors.em)),
              const SizedBox(width: 8),
              Expanded(child: _buildMiniStat('SOLD', totalSell, sellCount, AppColors.gold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, double amount, int count, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.glass,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color, letterSpacing: 0.8)),
              const Spacer(),
              Text('$count', style: const TextStyle(fontSize: 10, color: AppColors.t3)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'LKR ${Formatters.compactCurrency(amount)}',
            style: GoogleFonts.jetBrainsMono(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: -0.3),
          ),
        ],
      ),
    );
  }

  // ─── Stock P&L Breakdown ──────────────────────────────────────

  Widget _buildStockBreakdown(List<MapEntry<String, double>> stockPnl, Map<String, String> stockNames) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.glass,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(14, 12, 14, 0),
              child: Row(
                children: [
                  Icon(LucideIcons.pieChart, size: 14, color: AppColors.t2),
                  SizedBox(width: 8),
                  Text('P&L BY STOCK', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.t2, letterSpacing: 1.0)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            ...stockPnl.take(5).map((entry) {
              final isUp = entry.value >= 0;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                child: Row(
                  children: [
                    Container(
                      width: 28, height: 28,
                      decoration: BoxDecoration(
                        color: isUp ? const Color(0x1400FFA3) : const Color(0x14FF4D6A),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(entry.key.substring(0, 2), style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: isUp ? AppColors.em : AppColors.red)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(entry.key.replaceAll('.N0000', ''), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                          Text(stockNames[entry.key] ?? '', style: const TextStyle(fontSize: 10, color: AppColors.t3), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    Text(
                      '${isUp ? '+' : ''}LKR ${Formatters.compactCurrency(entry.value)}',
                      style: GoogleFonts.jetBrainsMono(fontSize: 13, fontWeight: FontWeight.w700, color: isUp ? AppColors.em : AppColors.red),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  // ─── Transaction Card ─────────────────────────────────────────

  Widget _buildTransactionCard(HistoryItem item) {
    final t = item.t;
    final isBuy = t.type == 'buy';
    final isUp = item.pnl >= 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.glass,
        border: Border.all(color: AppColors.border2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  color: isBuy ? const Color(0x1400FFA3) : const Color(0x14FF4D6A),
                  border: Border.all(color: isBuy ? const Color(0x2600FFA3) : const Color(0x26FF4D6A)),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(isBuy ? LucideIcons.trendingUp : LucideIcons.trendingDown, size: 18, color: isBuy ? AppColors.em : AppColors.red),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(item.sn, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: -0.1), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${isBuy ? '+' : '-'} LKR ${Formatters.compactCurrency(item.totalAmount)}',
                          style: GoogleFonts.jetBrainsMono(fontSize: 15, fontWeight: FontWeight.w800, color: isBuy ? AppColors.em : AppColors.red, letterSpacing: -0.3),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(Formatters.formatDateLong(t.dt), style: GoogleFonts.jetBrainsMono(fontSize: 10, color: AppColors.t3)),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: isBuy ? const Color(0x1A00FFA3) : const Color(0x1AFF4D6A),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(t.type.toUpperCase(), style: GoogleFonts.jetBrainsMono(fontSize: 9, fontWeight: FontWeight.w800, color: isBuy ? AppColors.em : AppColors.red, letterSpacing: 0.7)),
                            ),
                            const SizedBox(width: 4),
                            Text('${Formatters.compactCurrency(t.qty)} × LKR ${t.price.toStringAsFixed(2)}', style: const TextStyle(fontSize: 10, color: AppColors.t2)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          // P&L row
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isUp ? const Color(0x0A00FFA3) : const Color(0x0AFF4D6A),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isUp ? const Color(0x1A00FFA3) : const Color(0x1AFF4D6A)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(isUp ? LucideIcons.arrowUpRight : LucideIcons.arrowDownRight, size: 12, color: isUp ? AppColors.em : AppColors.red),
                    const SizedBox(width: 6),
                    Text('P&L', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: isUp ? AppColors.em : AppColors.red, letterSpacing: 0.5)),
                  ],
                ),
                Text(
                  '${isUp ? '+' : ''}LKR ${Formatters.compactCurrency(item.pnl)}',
                  style: GoogleFonts.jetBrainsMono(fontSize: 12, fontWeight: FontWeight.w700, color: isUp ? AppColors.em : AppColors.red),
                ),
                if (t.commission > 0)
                  Text('Fee: ${t.commission.toStringAsFixed(0)}', style: const TextStyle(fontSize: 9, color: AppColors.t3)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
