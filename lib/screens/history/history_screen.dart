import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';
import '../../providers/portfolio_provider.dart';
import '../../models/models.dart';
import '../../utils/formatters.dart';

class _TxItem {
  final Transaction t;
  final String code, name;
  final double todayPrice, avgBuy;
  _TxItem(this.t, this.code, this.name, this.todayPrice, this.avgBuy);
  double get total => t.qty * t.price;
  double get pnl => t.type == 'buy'
      ? (todayPrice - t.price) * t.qty - t.commission
      : (t.price - avgBuy) * t.qty - t.commission;
}

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  int _dateIdx = 0;
  final _dateLabels = ['All', 'Today', 'Week', 'Month', 'Year'];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _tabCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  List<_TxItem> _buildAll(PortfolioProvider p) {
    final List<_TxItem> all = [];
    for (final s in p.stocks.values) {
      for (final t in s.transactions) {
        all.add(_TxItem(t, s.code, s.name, s.todayPrice, s.avgBuyPrice));
      }
    }
    all.sort((a, b) => b.t.dt.compareTo(a.t.dt));
    return all;
  }

  List<_TxItem> _applyDateFilter(List<_TxItem> items) {
    final now = DateTime.now();
    switch (_dateIdx) {
      case 1: return items.where((i) => Formatters.isSameDay(i.t.dt, now)).toList();
      case 2: return items.where((i) => i.t.dt.isAfter(now.subtract(const Duration(days: 7)))).toList();
      case 3: return items.where((i) => i.t.dt.year == now.year && i.t.dt.month == now.month).toList();
      case 4: return items.where((i) => i.t.dt.year == now.year).toList();
      default: return items;
    }
  }

  List<_TxItem> _forTab(List<_TxItem> items, int tab) {
    if (tab == 1) return items.where((i) => i.pnl >= 0).toList();
    if (tab == 2) return items.where((i) => i.pnl < 0).toList();
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final c = colors(context);

    return Consumer<PortfolioProvider>(
      builder: (context, provider, _) {
        final allItems = _buildAll(provider);
        final dated = _applyDateFilter(allItems);
        final gainCount = _forTab(dated, 1).length;
        final lossCount = _forTab(dated, 2).length;

        return Column(
          children: [
            // ── Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('History', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5, color: c.textPrimary)),
                        const SizedBox(height: 3),
                        Text('${dated.length} transaction${dated.length != 1 ? 's' : ''} • ${_dateLabels[_dateIdx]}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: c.textSecondary)),
                      ],
                    ),
                  ),
                  if (_dateIdx != 0)
                    GestureDetector(
                      onTap: () => setState(() => _dateIdx = 0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(color: c.chipBg, borderRadius: BorderRadius.circular(10), border: Border.all(color: c.border)),
                        child: Text('Reset', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: c.textSecondary)),
                      ),
                    ),
                ],
              ),
            ),

            // ── Date Filters
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 14, 0, 2),
              child: SizedBox(
                height: 34,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: _dateLabels.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 6),
                  itemBuilder: (_, i) {
                    final isOn = _dateIdx == i;
                    return GestureDetector(
                      onTap: () => setState(() => _dateIdx = i),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: isOn ? AppColors.blue.withValues(alpha: 0.15) : c.chipBg,
                          border: Border.all(color: isOn ? AppColors.blue.withValues(alpha: 0.4) : c.border),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        alignment: Alignment.center,
                        child: Text(_dateLabels[i], style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isOn ? AppColors.blue : c.textSecondary)),
                      ),
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 8),

            // ── Tabs: All / Gains / Losses
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: c.chipBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: c.border),
              ),
              child: TabBar(
                controller: _tabCtrl,
                labelColor: Colors.white,
                unselectedLabelColor: c.textSecondary,
                labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                indicator: BoxDecoration(
                  color: _tabCtrl.index == 2 ? AppColors.red : AppColors.em,
                  borderRadius: BorderRadius.circular(12),
                ),
                indicatorPadding: const EdgeInsets.all(3),
                tabs: [
                  Tab(child: _tabLabel('All', '${dated.length}', null)),
                  Tab(child: _tabLabel('Gains', '$gainCount', AppColors.em)),
                  Tab(child: _tabLabel('Losses', '$lossCount', AppColors.red)),
                ],
              ),
            ),

            const SizedBox(height: 4),

            // ── Summary for active tab
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: _summaryRow(c),
            ),

            // ── Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabCtrl,
                children: [
                  _buildList(_applyDateFilter(allItems), c),
                  _buildList(_forTab(dated, 1), c),
                  _buildList(_forTab(dated, 2), c),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _tabLabel(String label, String count, Color? accentColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label),
        const SizedBox(width: 5),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(count, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }

  Widget _summaryRow(AC c) {
    return Consumer<PortfolioProvider>(
      builder: (context, provider, _) {
        final all = _buildAll(provider);
        final dated = _applyDateFilter(all);
        final tabItems = _forTab(dated, _tabCtrl.index);
        final totalPnl = tabItems.fold<double>(0, (s, i) => s + i.pnl);
        final totalInvested = tabItems.fold<double>(0, (s, i) => s + i.total);
        final isUp = totalPnl >= 0;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isUp ? AppColors.em.withValues(alpha: 0.06) : AppColors.red.withValues(alpha: 0.06),
            border: Border.all(color: isUp ? AppColors.em.withValues(alpha: 0.15) : AppColors.red.withValues(alpha: 0.15)),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Value', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: c.textTertiary)),
                    const SizedBox(height: 2),
                    Text('LKR ${Formatters.compactCurrency(totalInvested)}', style: GoogleFonts.jetBrainsMono(fontSize: 16, fontWeight: FontWeight.w700, color: c.textPrimary)),
                  ],
                ),
              ),
              Container(width: 1, height: 30, color: c.border),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Net P&L', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: c.textTertiary)),
                      const SizedBox(height: 2),
                      Text(
                        '${isUp ? '+' : ''}LKR ${Formatters.compactCurrency(totalPnl)}',
                        style: GoogleFonts.jetBrainsMono(fontSize: 16, fontWeight: FontWeight.w700, color: isUp ? AppColors.em : AppColors.red),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildList(List<_TxItem> items, AC c) {
    if (items.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(LucideIcons.clock, size: 44, color: c.textFaint),
          const SizedBox(height: 14),
          Text('No transactions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: c.textPrimary)),
          const SizedBox(height: 6),
          Text('Adjust date filter or add trades.', style: TextStyle(fontSize: 13, color: c.textSecondary)),
        ]),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      itemCount: items.length,
      itemBuilder: (_, i) => _txCard(items[i], c),
    );
  }

  Widget _txCard(_TxItem item, AC c) {
    final t = item.t;
    final isBuy = t.type == 'buy';
    final isUp = item.pnl >= 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: c.card, border: Border.all(color: c.border), borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          // Icon
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: isBuy ? const Color(0x1400FFA3) : const Color(0x14FF4D6A), borderRadius: BorderRadius.circular(12)),
            child: Icon(isBuy ? LucideIcons.trendingUp : LucideIcons.trendingDown, size: 18, color: isBuy ? AppColors.em : AppColors.red),
          ),
          const SizedBox(width: 12),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(item.name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isUp ? AppColors.em.withValues(alpha: 0.12) : AppColors.red.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${isUp ? '+' : ''}${Formatters.compactCurrency(item.pnl)}',
                        style: GoogleFonts.jetBrainsMono(fontSize: 11, fontWeight: FontWeight.w700, color: isUp ? AppColors.em : AppColors.red),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(color: isBuy ? const Color(0x1400FFA3) : const Color(0x14FF4D6A), borderRadius: BorderRadius.circular(4)),
                      child: Text(t.type.toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: isBuy ? AppColors.em : AppColors.red)),
                    ),
                    const SizedBox(width: 6),
                    Text('${Formatters.compactCurrency(t.qty)} × ${t.price.toStringAsFixed(2)}', style: TextStyle(fontSize: 11, color: c.textTertiary)),
                    const Spacer(),
                    Text(Formatters.formatDate(t.dt), style: GoogleFonts.jetBrainsMono(fontSize: 10, color: c.textTertiary)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
