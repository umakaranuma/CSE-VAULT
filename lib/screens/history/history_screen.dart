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

  HistoryItem(this.t, this.sc, this.sn);
}

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    return Consumer<PortfolioProvider>(
      builder: (context, provider, child) {
        final List<HistoryItem> all = [];
        for (final s in provider.stocks.values) {
          for (final t in s.transactions) {
            all.add(HistoryItem(t, s.code, s.name));
          }
        }
        all.sort((a, b) => b.t.dt.compareTo(a.t.dt));

        final Set<String> codesSet = {'all'};
        for (final item in all) {
          codesSet.add(item.sc);
        }
        final codes = codesSet.toList();

        final filtered = _filter == 'all' ? all : all.where((i) => i.sc == _filter).toList();

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'History',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        height: 1.2,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'All transactions',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.t2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 32,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: codes.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final c = codes[index];
                    final isOn = _filter == c;
                    return GestureDetector(
                      onTap: () => setState(() => _filter = c),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 7),
                        decoration: BoxDecoration(
                          color: isOn ? const Color(0x1A00FFA3) : AppColors.glass,
                          border: Border.all(color: isOn ? const Color(0x4000FFA3) : AppColors.border2),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: isOn ? const [BoxShadow(color: Color(0x1400FFA3), blurRadius: 12)] : null,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          c == 'all' ? 'All transactions' : c,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isOn ? AppColors.em : AppColors.t2,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 14)),
            if (filtered.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
                  child: Column(
                    children: const [
                      Text('🕐', style: TextStyle(fontSize: 48)),
                      SizedBox(height: 16),
                      Text(
                        'No transactions',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, letterSpacing: -0.2),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Your buy and sell history will appear here.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: AppColors.t2, height: 1.6),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 30),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = filtered[index];
                      final t = item.t;
                      final isBuy = t.type == 'buy';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.glass,
                          border: Border.all(color: AppColors.border2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
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
                                        child: Text(
                                          item.sn,
                                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: -0.1),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${isBuy ? '+' : '-'} LKR ${Formatters.compactCurrency(t.qty * t.price)}',
                                        style: GoogleFonts.jetBrainsMono(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                          color: isBuy ? AppColors.em : AppColors.red,
                                          letterSpacing: -0.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
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
                                            child: Text(
                                              t.type.toUpperCase(),
                                              style: GoogleFonts.jetBrainsMono(
                                                fontSize: 9,
                                                fontWeight: FontWeight.w800,
                                                color: isBuy ? AppColors.em : AppColors.red,
                                                letterSpacing: 0.7,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${Formatters.compactCurrency(t.qty)} × LKR ${t.price.toStringAsFixed(2)}',
                                            style: const TextStyle(fontSize: 10, color: AppColors.t2),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    childCount: filtered.length,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
