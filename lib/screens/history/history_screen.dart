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

class _HistoryScreenState extends State<HistoryScreen> {
  int _dateIdx = 0; // 0=All, 1=Today, 2=Week, 3=Month, 4=Year
  int _typeIdx = 0; // 0=All, 1=Gains, 2=Losses

  final _dateLabels = ['All', 'Today', 'Week', 'Month', 'Year'];
  final _typeLabels = ['All', 'Gains', 'Losses'];

  List<_TxItem> _build(PortfolioProvider p) {
    final List<_TxItem> all = [];
    for (final s in p.stocks.values) {
      for (final t in s.transactions) {
        all.add(_TxItem(t, s.code, s.name, s.todayPrice, s.avgBuyPrice));
      }
    }
    all.sort((a, b) => b.t.dt.compareTo(a.t.dt));
    return all;
  }

  List<_TxItem> _filter(List<_TxItem> items) {
    var f = items.toList();
    final now = DateTime.now();
    switch (_dateIdx) {
      case 1: f = f.where((i) => i.t.dt.year == now.year && i.t.dt.month == now.month && i.t.dt.day == now.day).toList(); break;
      case 2: f = f.where((i) => i.t.dt.isAfter(now.subtract(const Duration(days: 7)))).toList(); break;
      case 3: f = f.where((i) => i.t.dt.year == now.year && i.t.dt.month == now.month).toList(); break;
      case 4: f = f.where((i) => i.t.dt.year == now.year).toList(); break;
    }
    if (_typeIdx == 1) f = f.where((i) => i.pnl >= 0).toList();
    if (_typeIdx == 2) f = f.where((i) => i.pnl < 0).toList();
    return f;
  }

  @override
  Widget build(BuildContext context) {
    final c = colors(context);

    return Consumer<PortfolioProvider>(
      builder: (context, provider, _) {
        final all = _build(provider);
        final filtered = _filter(all);
        final totalPnl = filtered.fold<double>(0, (s, i) => s + i.pnl);
        final isUp = totalPnl >= 0;
        final hasFilters = _dateIdx != 0 || _typeIdx != 0;

        return CustomScrollView(
          slivers: [
            // ── Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('History', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5, color: c.textPrimary)),
                          const SizedBox(height: 3),
                          Text('${filtered.length} transaction${filtered.length != 1 ? 's' : ''}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: c.textSecondary)),
                        ],
                      ),
                    ),
                    if (hasFilters)
                      GestureDetector(
                        onTap: () => setState(() { _dateIdx = 0; _typeIdx = 0; }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(color: c.chipBg, borderRadius: BorderRadius.circular(10), border: Border.all(color: c.border)),
                          child: Text('Reset', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: c.textSecondary)),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // ── Summary Card
            if (filtered.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: c.card,
                      border: Border.all(color: isUp ? AppColors.em.withValues(alpha: 0.2) : AppColors.red.withValues(alpha: 0.2)),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        Icon(isUp ? LucideIcons.trendingUp : LucideIcons.trendingDown, size: 20, color: isUp ? AppColors.em : AppColors.red),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Net P&L', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: c.textSecondary)),
                            const SizedBox(height: 2),
                            Text(
                              '${isUp ? '+' : ''}LKR ${Formatters.compactCurrency(totalPnl)}',
                              style: GoogleFonts.jetBrainsMono(fontSize: 22, fontWeight: FontWeight.w800, color: isUp ? AppColors.em : AppColors.red),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // ── Filter: Date chips (horizontal scroll)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 14, 0, 0),
                child: SizedBox(
                  height: 36,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: _dateLabels.length + _typeLabels.length + 1, // +1 for divider
                    separatorBuilder: (_, __) => const SizedBox(width: 6),
                    itemBuilder: (context, index) {
                      // Date chips
                      if (index < _dateLabels.length) {
                        final isOn = _dateIdx == index;
                        return _chip(_dateLabels[index], isOn, AppColors.blue, c, () => setState(() => _dateIdx = index));
                      }
                      // Divider
                      if (index == _dateLabels.length) {
                        return Container(width: 1, margin: const EdgeInsets.symmetric(vertical: 8), color: c.border);
                      }
                      // Type chips
                      final tIdx = index - _dateLabels.length - 1;
                      final isOn = _typeIdx == tIdx;
                      final chipColor = tIdx == 1 ? AppColors.em : tIdx == 2 ? AppColors.red : AppColors.blue;
                      return _chip(_typeLabels[tIdx], isOn, chipColor, c, () => setState(() => _typeIdx = tIdx));
                    },
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // ── Transaction List
            if (filtered.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 24),
                  child: Column(
                    children: [
                      Icon(LucideIcons.clock, size: 44, color: c.textFaint),
                      const SizedBox(height: 14),
                      Text('No transactions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: c.textPrimary)),
                      const SizedBox(height: 6),
                      Text(
                        hasFilters ? 'Try different filters.' : 'Add stocks and trade to see history.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: c.textSecondary, height: 1.5),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                sliver: SliverList(delegate: SliverChildBuilderDelegate(
                  (ctx, i) => _txCard(filtered[i], c),
                  childCount: filtered.length,
                )),
              ),
          ],
        );
      },
    );
  }

  Widget _chip(String label, bool isOn, Color color, AC c, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: isOn ? color.withValues(alpha: 0.15) : c.chipBg,
          border: Border.all(color: isOn ? color.withValues(alpha: 0.4) : c.border),
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.center,
        child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isOn ? color : c.textSecondary)),
      ),
    );
  }

  Widget _txCard(_TxItem item, AC c) {
    final t = item.t;
    final isBuy = t.type == 'buy';
    final isUp = item.pnl >= 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.card,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: isBuy ? const Color(0x1400FFA3) : const Color(0x14FF4D6A),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(isBuy ? LucideIcons.trendingUp : LucideIcons.trendingDown, size: 18, color: isBuy ? AppColors.em : AppColors.red),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(item.code.replaceAll('.N0000', ''), style: GoogleFonts.jetBrainsMono(fontSize: 10, color: c.textTertiary)),
                    const SizedBox(width: 6),
                    Text(Formatters.formatDateLong(t.dt), style: TextStyle(fontSize: 10, color: c.textTertiary)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isBuy ? '+' : '-'}LKR ${Formatters.compactCurrency(item.total)}',
                style: GoogleFonts.jetBrainsMono(fontSize: 14, fontWeight: FontWeight.w700, color: c.textPrimary),
              ),
              const SizedBox(height: 3),
              Text(
                '${isUp ? '+' : ''}${Formatters.compactCurrency(item.pnl)}',
                style: GoogleFonts.jetBrainsMono(fontSize: 11, fontWeight: FontWeight.w600, color: isUp ? AppColors.em : AppColors.red),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
