import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';

import '../../theme/app_colors.dart';
import '../../models/models.dart';
import '../../utils/formatters.dart';
import '../../providers/portfolio_provider.dart';
import '../../sheets/log_price_sheet.dart';
import '../../sheets/add_transaction_sheet.dart';
import '../../sheets/chart_full_view_sheet.dart';

class StockDetailScreen extends StatelessWidget {
  final String code;
  const StockDetailScreen({super.key, required this.code});

  @override
  Widget build(BuildContext context) {
    final c = colors(context);

    return Consumer<PortfolioProvider>(
      builder: (context, provider, _) {
        final s = provider.stocks[code];
        if (s == null) {
          return Scaffold(
            backgroundColor: c.bg,
            appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
            body: Center(child: Text('Stock not found', style: TextStyle(color: c.textSecondary))),
          );
        }
        final isUp = s.unrealised >= 0;

        return Scaffold(
          backgroundColor: c.bg,
          body: DefaultTabController(
            length: 3,
            child: NestedScrollView(
              headerSliverBuilder: (context, innerBoxScrolled) => [
                SliverAppBar(
                  backgroundColor: c.bg,
                  elevation: 0,
                  pinned: true,
                  leading: IconButton(icon: Icon(LucideIcons.arrowLeft, size: 20, color: c.textPrimary), onPressed: () => Navigator.pop(context)),
                  title: Text(s.code.replaceAll('.N0000', ''), style: GoogleFonts.jetBrainsMono(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: c.textPrimary)),
                  actions: [
                    IconButton(
                      icon: provider.isLoading
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(AppColors.em)))
                          : Icon(LucideIcons.refreshCw, size: 18, color: c.textSecondary),
                      onPressed: () => provider.refreshPrices(),
                    ),
                  ],
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.name, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.3, color: c.textPrimary)),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('LKR ${s.todayPrice.toStringAsFixed(2)}', style: GoogleFonts.jetBrainsMono(fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -1, color: c.textPrimary)),
                            const SizedBox(width: 12),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(color: isUp ? const Color(0x1A00FFA3) : const Color(0x1AFF4D6A), borderRadius: BorderRadius.circular(20)),
                                child: Text(Formatters.percentage(s.pnlPercent), style: GoogleFonts.jetBrainsMono(fontSize: 13, fontWeight: FontWeight.w700, color: isUp ? AppColors.em : AppColors.red)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(child: _actionBtn(context, 'Buy', LucideIcons.trendingUp, AppColors.em, () {
                              showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (_) => AddTransactionSheet(code: code, type: 'buy'));
                            })),
                            const SizedBox(width: 8),
                            Expanded(child: _actionBtn(context, 'Sell', LucideIcons.trendingDown, AppColors.red, () {
                              showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (_) => AddTransactionSheet(code: code, type: 'sell'));
                            })),
                            const SizedBox(width: 8),
                            Expanded(child: _actionBtn(context, 'Log Price', LucideIcons.clock, AppColors.blue, () {
                              showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (_) => LogPriceSheet(code: code));
                            })),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _TabBarDelegate(
                    TabBar(
                      labelColor: AppColors.em,
                      unselectedLabelColor: c.textTertiary,
                      indicatorColor: AppColors.em,
                      indicatorSize: TabBarIndicatorSize.label,
                      labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                      unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      tabs: const [Tab(text: 'Overview'), Tab(text: 'Transactions'), Tab(text: 'Price Log')],
                    ),
                    c.bg,
                  ),
                ),
              ],
              body: TabBarView(children: [_OverviewTab(stock: s), _TransactionsTab(stock: s), _PriceLogTab(stock: s)]),
            ),
          ),
        );
      },
    );
  }

  Widget _actionBtn(BuildContext context, String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
          ],
        ),
      ),
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final Color bgColor;
  _TabBarDelegate(this.tabBar, this.bgColor);

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;
  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) => Container(color: bgColor, child: tabBar);
  @override
  bool shouldRebuild(covariant _TabBarDelegate oldDelegate) => oldDelegate.bgColor != bgColor;
}

// ─── Overview Tab ────────────────────────────────────────────

class _OverviewTab extends StatelessWidget {
  final Stock stock;
  const _OverviewTab({required this.stock});

  @override
  Widget build(BuildContext context) {
    final c = colors(context);
    final s = stock;
    final isUp = s.unrealised >= 0;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      children: [
        _buildMetricsGrid(s, isUp, c),
        const SizedBox(height: 16),
        _buildChart(context, s, c),
        const SizedBox(height: 16),
        _buildTodayTile(context, s, c),
      ],
    );
  }

  Widget _buildMetricsGrid(Stock s, bool isUp, AC c) {
    return GridView.count(
      crossAxisCount: 3, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 2.2,
      children: [
        _metricBox('AVG BUY', s.avgBuyPrice > 0 ? s.avgBuyPrice.toStringAsFixed(2) : '—', c.textPrimary, c),
        _metricBox('UNREALISED', Formatters.compactCurrency(s.unrealised), isUp ? AppColors.em : AppColors.red, c),
        _metricBox('REALISED', Formatters.compactCurrency(s.realised), s.realised >= 0 ? AppColors.em : AppColors.red, c),
        _metricBox('BOUGHT', Formatters.compactCurrency(s.totalBoughtQty), AppColors.em, c),
        _metricBox('SOLD', Formatters.compactCurrency(s.totalSoldQty), AppColors.gold, c),
        _metricBox('HOLDING', Formatters.compactCurrency(s.holdingsQty), AppColors.blue, c),
      ],
    );
  }

  Widget _metricBox(String label, String value, Color vColor, AC c) {
    return Container(
      decoration: BoxDecoration(color: c.card, border: Border.all(color: c.border), borderRadius: BorderRadius.circular(12)),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: c.textFaint, letterSpacing: 0.8)),
          const SizedBox(height: 4),
          Text(value, style: GoogleFonts.jetBrainsMono(fontSize: 13, fontWeight: FontWeight.w700, color: vColor)),
        ],
      ),
    );
  }

  Widget _buildChart(BuildContext context, Stock s, AC c) {
    final log = s.priceLog.toList()..sort((a, b) => a.dt.compareTo(b.dt));
    if (log.length < 2) {
      return Container(
        height: 160,
        decoration: BoxDecoration(color: c.card, border: Border.all(color: c.border), borderRadius: BorderRadius.circular(14)),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.trendingUp, color: c.textFaint, size: 28),
            const SizedBox(height: 5),
            Text('Log 2+ prices to see chart', style: TextStyle(fontSize: 11, color: c.textFaint)),
          ],
        ),
      );
    }

    final baseTime = log.first.dt.millisecondsSinceEpoch.toDouble();
    final spots = log.map((l) => FlSpot((l.dt.millisecondsSinceEpoch.toDouble() - baseTime) / 60000, l.price)).toList();
    final prices = log.map((l) => l.price).toList();
    final minP = prices.reduce((a, b) => a < b ? a : b);
    final maxP = prices.reduce((a, b) => a > b ? a : b);
    final range = maxP - minP;
    final pad = range > 0 ? range * 0.15 : maxP * 0.02;
    final isUp = log.last.price >= s.avgBuyPrice;
    final cMain = isUp ? AppColors.em : AppColors.red;
    final showAvg = s.avgBuyPrice >= (minP - pad) && s.avgBuyPrice <= (maxP + pad) && s.avgBuyPrice > 0;

    return Stack(children: [
      Container(
        height: 180, width: double.infinity,
        decoration: BoxDecoration(color: c.card, border: Border.all(color: c.border), borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.only(top: 8, right: 8),
        child: LineChart(LineChartData(
          minY: minP - pad, maxY: maxP + pad,
          lineBarsData: [
            LineChartBarData(
              spots: spots, isCurved: true, curveSmoothness: 0.25, color: cMain, barWidth: 2.5, isStrokeCapRound: true,
              dotData: FlDotData(show: true, getDotPainter: (s, p, b, i) => FlDotCirclePainter(radius: 3, color: cMain, strokeWidth: 1.5, strokeColor: c.bg)),
              belowBarData: BarAreaData(show: true, gradient: LinearGradient(colors: [cMain.withValues(alpha: 0.2), Colors.transparent], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
            ),
            if (showAvg)
              LineChartBarData(spots: [FlSpot(spots.first.x, s.avgBuyPrice), FlSpot(spots.last.x, s.avgBuyPrice)], isCurved: false, color: AppColors.blue.withValues(alpha: 0.5), barWidth: 1.5, dashArray: [4, 4], dotData: const FlDotData(show: false)),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              fitInsideHorizontally: true, fitInsideVertically: true,
              getTooltipColor: (_) => c.cardElevated,
              getTooltipItems: (ts) => ts.map((spot) {
                if (spot.barIndex > 0) return null;
                final idx = spot.spotIndex;
                final entry = idx < log.length ? log[idx] : null;
                final t = entry != null ? Formatters.formatTime(entry.dt) : '';
                final d = entry != null ? Formatters.formatDateWithDay(entry.dt) : '';
                final n = entry?.note ?? '';
                return LineTooltipItem('$t  $d\n', TextStyle(fontSize: 10, color: c.textSecondary, height: 1.4), children: [
                  TextSpan(text: 'LKR ${spot.y.toStringAsFixed(2)}', style: GoogleFonts.jetBrainsMono(fontSize: 13, fontWeight: FontWeight.w800, color: cMain)),
                  if (n.isNotEmpty) TextSpan(text: '\n$n', style: TextStyle(fontSize: 9, color: c.textTertiary)),
                ]);
              }).toList(),
            ),
          ),
          titlesData: FlTitlesData(
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 46, getTitlesWidget: (val, meta) {
              if (val == meta.min || val == meta.max) return const SizedBox.shrink();
              return Padding(padding: const EdgeInsets.only(right: 6), child: Text(val.toStringAsFixed(1), style: GoogleFonts.jetBrainsMono(fontSize: 9, color: c.textTertiary)));
            })),
          ),
          gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: range > 0 ? (range / 3).ceilToDouble().clamp(0.1, 1000) : 1, getDrawingHorizontalLine: (v) => FlLine(color: c.borderLight, strokeWidth: 1)),
          borderData: FlBorderData(show: false),
        )),
      ),
      Positioned(top: 4, right: 4, child: IconButton(icon: Icon(LucideIcons.maximize2, size: 16, color: c.textSecondary), onPressed: () {
        showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (_) => ChartFullViewSheet(stock: s));
      })),
    ]);
  }

  Widget _buildTodayTile(BuildContext context, Stock s, AC c) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(color: const Color(0x0A00FFA3), border: Border.all(color: const Color(0x1F00FFA3)), borderRadius: BorderRadius.circular(14)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text("TODAY'S PRICE", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0x8000FFA3), letterSpacing: 1.0)),
            const SizedBox(height: 4),
            Text('Tap to update', style: TextStyle(fontSize: 10, color: c.textTertiary)),
          ]),
          SizedBox(
            width: 120,
            child: TextField(
              controller: TextEditingController(text: s.todayPrice.toStringAsFixed(2)),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.right,
              style: GoogleFonts.jetBrainsMono(color: AppColors.em, fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: -0.5),
              decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.zero, border: InputBorder.none),
              onSubmitted: (v) {
                final d = double.tryParse(v);
                if (d != null && d > 0) context.read<PortfolioProvider>().updateTodayPrice(s.code, d);
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Transactions Tab ────────────────────────────────────────

class _TransactionsTab extends StatelessWidget {
  final Stock stock;
  const _TransactionsTab({required this.stock});

  @override
  Widget build(BuildContext context) {
    final c = colors(context);
    final txns = stock.transactions;
    if (txns.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(LucideIcons.arrowLeftRight, size: 40, color: c.textFaint),
          const SizedBox(height: 12),
          Text('No transactions yet', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: c.textTertiary)),
          const SizedBox(height: 4),
          Text('Use Buy or Sell to add one.', style: TextStyle(fontSize: 12, color: c.textFaint)),
        ]),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
      itemCount: txns.length,
      itemBuilder: (context, index) => _buildTxCard(context, txns[index], c),
    );
  }

  Widget _buildTxCard(BuildContext context, Transaction t, AC c) {
    final isBuy = t.type == 'buy';
    final total = t.qty * t.price;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: c.card, border: Border.all(color: c.border), borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: isBuy ? const Color(0x1400FFA3) : const Color(0x14FF4D6A), borderRadius: BorderRadius.circular(12)),
            child: Icon(isBuy ? LucideIcons.trendingUp : LucideIcons.trendingDown, size: 18, color: isBuy ? AppColors.em : AppColors.red),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: isBuy ? const Color(0x1A00FFA3) : const Color(0x1AFF4D6A), borderRadius: BorderRadius.circular(6)),
                  child: Text(t.type.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: isBuy ? AppColors.em : AppColors.red, letterSpacing: 0.5)),
                ),
                const Spacer(),
                Text('LKR ${Formatters.compactCurrency(total)}', style: GoogleFonts.jetBrainsMono(fontSize: 15, fontWeight: FontWeight.w700, color: c.textPrimary)),
              ]),
              const SizedBox(height: 6),
              Row(children: [
                Text('${Formatters.compactCurrency(t.qty)} × LKR ${t.price.toStringAsFixed(2)}', style: TextStyle(fontSize: 11, color: c.textSecondary)),
                if (t.commission > 0) ...[const SizedBox(width: 8), Text('Fee: ${t.commission.toStringAsFixed(0)}', style: TextStyle(fontSize: 10, color: c.textTertiary))],
              ]),
              const SizedBox(height: 2),
              Text(Formatters.formatDateLong(t.dt), style: GoogleFonts.jetBrainsMono(fontSize: 10, color: c.textTertiary)),
            ]),
          ),
          const SizedBox(width: 8),
          Column(children: [
            GestureDetector(
              onTap: () => showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (_) => AddTransactionSheet(code: stock.code, type: t.type, editTransaction: t)),
              child: Icon(LucideIcons.pencil, size: 14, color: c.textTertiary),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => context.read<PortfolioProvider>().deleteTransaction(stock.code, t.id),
              child: Icon(LucideIcons.trash2, size: 14, color: c.textTertiary),
            ),
          ]),
        ],
      ),
    );
  }
}

// ─── Price Log Tab ───────────────────────────────────────────

class _PriceLogTab extends StatelessWidget {
  final Stock stock;
  const _PriceLogTab({required this.stock});

  @override
  Widget build(BuildContext context) {
    final c = colors(context);
    final logs = stock.priceLog;
    if (logs.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(LucideIcons.clock, size: 40, color: c.textFaint),
          const SizedBox(height: 12),
          Text('No price logs yet', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: c.textTertiary)),
          const SizedBox(height: 4),
          Text('Use Log Price to track intraday changes.', style: TextStyle(fontSize: 12, color: c.textFaint)),
        ]),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
      itemCount: logs.length,
      itemBuilder: (context, index) {
        final l = logs[index];
        final prev = index + 1 < logs.length ? logs[index + 1] : null;
        final delta = prev != null ? l.price - prev.price : null;
        final isUp = delta != null ? delta >= 0 : true;
        final isNear = l.price >= stock.todayPrice * 0.99;

        return Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(color: c.card, border: Border.all(color: c.border), borderRadius: BorderRadius.circular(14)),
          child: Row(children: [
            SizedBox(width: 62, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(Formatters.formatTime(l.dt), style: GoogleFonts.jetBrainsMono(fontSize: 12, fontWeight: FontWeight.w700, color: isNear ? AppColors.em : c.textSecondary)),
              const SizedBox(height: 2),
              Text(Formatters.formatDateWithDay(l.dt), style: TextStyle(fontSize: 9, color: c.textTertiary)),
            ])),
            const SizedBox(width: 8),
            Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: isNear ? AppColors.em : AppColors.red)),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text('LKR ${l.price.toStringAsFixed(2)}', style: GoogleFonts.jetBrainsMono(fontSize: 15, fontWeight: FontWeight.w700, color: c.textPrimary)),
                if (delta != null) ...[const SizedBox(width: 8), Text('${isUp ? '+' : ''}${delta.toStringAsFixed(2)}', style: GoogleFonts.jetBrainsMono(fontSize: 11, fontWeight: FontWeight.w600, color: isUp ? AppColors.em : AppColors.red))],
              ]),
              if (l.note != null && l.note!.isNotEmpty)
                Padding(padding: const EdgeInsets.only(top: 2), child: Text(l.note!, style: TextStyle(fontSize: 11, color: c.textSecondary))),
            ])),
            GestureDetector(
              onTap: () => context.read<PortfolioProvider>().deletePriceLog(stock.code, l.id),
              child: Icon(LucideIcons.trash2, size: 14, color: c.textTertiary),
            ),
          ]),
        );
      },
    );
  }
}
