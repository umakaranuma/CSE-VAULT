import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';
import '../../providers/portfolio_provider.dart';
import '../../models/models.dart';
import '../../utils/formatters.dart';
import '../../widgets/stock_card.dart';
import '../../sheets/add_stock_sheet.dart';

enum StockSort { name, pnl, value, holdings }

class StocksScreen extends StatefulWidget {
  const StocksScreen({super.key});

  @override
  State<StocksScreen> createState() => _StocksScreenState();
}

class _StocksScreenState extends State<StocksScreen> {
  String _filter = 'all'; // all, gain, loss
  StockSort _sort = StockSort.name;

  List<Stock> _applyFilters(List<Stock> stocks) {
    var list = stocks.toList();

    if (_filter == 'gain') {
      list = list.where((s) => s.unrealised >= 0).toList();
    } else if (_filter == 'loss') {
      list = list.where((s) => s.unrealised < 0).toList();
    }

    switch (_sort) {
      case StockSort.name:
        list.sort((a, b) => a.name.compareTo(b.name));
        break;
      case StockSort.pnl:
        list.sort((a, b) => b.unrealised.compareTo(a.unrealised));
        break;
      case StockSort.value:
        list.sort((a, b) => b.holdingsValue.compareTo(a.holdingsValue));
        break;
      case StockSort.holdings:
        list.sort((a, b) => b.holdingsQty.compareTo(a.holdingsQty));
        break;
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // ── Header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('My Stocks', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5, height: 1.2)),
                    const SizedBox(height: 3),
                    Consumer<PortfolioProvider>(
                      builder: (context, provider, _) {
                        final count = provider.stocks.length;
                        return Text('$count stock${count != 1 ? 's' : ''} tracked', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.t2));
                      },
                    ),
                  ],
                ),
                Row(
                  children: [
                    Consumer<PortfolioProvider>(
                      builder: (context, provider, _) {
                        return GestureDetector(
                          onTap: provider.isLoading ? null : () => provider.refreshPrices(),
                          child: Container(
                            width: 42, height: 42,
                            decoration: BoxDecoration(color: AppColors.glass2, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border2)),
                            child: provider.isLoading
                                ? const Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(AppColors.em))))
                                : const Icon(LucideIcons.refreshCw, color: AppColors.t2, size: 18),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (context) => const AddStockSheet());
                      },
                      child: Container(
                        width: 42, height: 42,
                        decoration: BoxDecoration(color: AppColors.glass2, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border2)),
                        child: const Icon(LucideIcons.plus, color: AppColors.t2, size: 18),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // ── Filter + Sort Row
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
            child: Row(
              children: [
                _buildChip('All', 'all', _filter == 'all', AppColors.blue),
                const SizedBox(width: 6),
                _buildChip('📈 Gains', 'gain', _filter == 'gain', AppColors.em),
                const SizedBox(width: 6),
                _buildChip('📉 Losses', 'loss', _filter == 'loss', AppColors.red),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: AppColors.glass,
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<StockSort>(
                      value: _sort,
                      isDense: true,
                      dropdownColor: AppColors.s3,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                      icon: const Icon(LucideIcons.arrowUpDown, size: 12, color: AppColors.t2),
                      items: const [
                        DropdownMenuItem(value: StockSort.name, child: Text('Name', style: TextStyle(fontSize: 11, color: AppColors.t2))),
                        DropdownMenuItem(value: StockSort.pnl, child: Text('P&L', style: TextStyle(fontSize: 11, color: AppColors.t2))),
                        DropdownMenuItem(value: StockSort.value, child: Text('Value', style: TextStyle(fontSize: 11, color: AppColors.t2))),
                        DropdownMenuItem(value: StockSort.holdings, child: Text('Qty', style: TextStyle(fontSize: 11, color: AppColors.t2))),
                      ],
                      onChanged: (v) => setState(() => _sort = v ?? StockSort.name),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Stock Summary Bar
        Consumer<PortfolioProvider>(
          builder: (context, provider, _) {
            final stocks = _applyFilters(provider.stocks.values.toList());
            final totalVal = stocks.fold<double>(0, (s, st) => s + st.holdingsValue);
            final totalPnl = stocks.fold<double>(0, (s, st) => s + st.unrealised);
            final isUp = totalPnl >= 0;

            if (stocks.isEmpty) {
              return SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
                  child: Column(
                    children: [
                      const Text('📊', style: TextStyle(fontSize: 48)),
                      const SizedBox(height: 16),
                      Text(
                        _filter != 'all' ? 'No ${_filter == "gain" ? "gaining" : "losing"} stocks' : 'No stocks added',
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, letterSpacing: -0.2),
                      ),
                      const SizedBox(height: 8),
                      const Text('Add stocks to track your holdings, buy/sell history, and P&L.', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: AppColors.t2, height: 1.6)),
                    ],
                  ),
                ),
              );
            }

            return SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isUp ? const Color(0x0A00FFA3) : const Color(0x0AFF4D6A),
                    border: Border.all(color: isUp ? const Color(0x2000FFA3) : const Color(0x20FF4D6A)),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${stocks.length} stock${stocks.length != 1 ? 's' : ''} shown', style: const TextStyle(fontSize: 10, color: AppColors.t2, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text('LKR ${Formatters.compactCurrency(totalVal)}', style: GoogleFonts.jetBrainsMono(fontSize: 16, fontWeight: FontWeight.w700)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('Unrealised P&L', style: TextStyle(fontSize: 10, color: AppColors.t2, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text(
                            '${isUp ? '+' : ''}LKR ${Formatters.compactCurrency(totalPnl)}',
                            style: GoogleFonts.jetBrainsMono(fontSize: 16, fontWeight: FontWeight.w700, color: isUp ? AppColors.em : AppColors.red),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),

        // ── Stock Cards
        Consumer<PortfolioProvider>(
          builder: (context, provider, child) {
            final stocks = _applyFilters(provider.stocks.values.toList());
            if (stocks.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());

            return SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => StockCard(stock: stocks[index]),
                  childCount: stocks.length,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildChip(String label, String value, bool isOn, Color color) {
    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isOn ? color.withValues(alpha: 0.15) : AppColors.glass,
          border: Border.all(color: isOn ? color.withValues(alpha: 0.4) : AppColors.border),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isOn ? color : AppColors.t2)),
      ),
    );
  }
}
