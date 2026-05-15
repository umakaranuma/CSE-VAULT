import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/app_colors.dart';
import '../../providers/portfolio_provider.dart';
import '../../models/models.dart';

import '../../widgets/stock_card.dart';
import '../../sheets/add_stock_sheet.dart';

enum StockSort { name, pnl, value, holdings }

class StocksScreen extends StatefulWidget {
  const StocksScreen({super.key});
  @override
  State<StocksScreen> createState() => _StocksScreenState();
}

class _StocksScreenState extends State<StocksScreen> {
  int _filter = 0; // 0=all, 1=gain, 2=loss
  StockSort _sort = StockSort.name;

  final _filterLabels = ['All', 'Gains', 'Losses'];

  List<Stock> _apply(List<Stock> stocks) {
    var list = stocks.toList();
    if (_filter == 1) list = list.where((s) => s.unrealised >= 0).toList();
    if (_filter == 2) list = list.where((s) => s.unrealised < 0).toList();
    switch (_sort) {
      case StockSort.name: list.sort((a, b) => a.name.compareTo(b.name)); break;
      case StockSort.pnl: list.sort((a, b) => b.unrealised.compareTo(a.unrealised)); break;
      case StockSort.value: list.sort((a, b) => b.holdingsValue.compareTo(a.holdingsValue)); break;
      case StockSort.holdings: list.sort((a, b) => b.holdingsQty.compareTo(a.holdingsQty)); break;
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final c = colors(context);

    return CustomScrollView(
      slivers: [
        // ── Header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('My Stocks', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5, color: c.textPrimary)),
                      const SizedBox(height: 3),
                      Consumer<PortfolioProvider>(builder: (_, p, __) => Text('${p.stocks.length} tracked', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: c.textSecondary))),
                    ],
                  ),
                ),
                Row(children: [
                  Consumer<PortfolioProvider>(builder: (_, p, __) => _iconBtn(p.isLoading ? null : LucideIcons.refreshCw, c, () => p.refreshPrices(), loading: p.isLoading)),
                  const SizedBox(width: 8),
                  _iconBtn(LucideIcons.plus, c, () => showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (_) => const AddStockSheet())),
                ]),
              ],
            ),
          ),
        ),

        // ── Filter chips + sort
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Row(
              children: [
                ...List.generate(_filterLabels.length, (i) {
                  final isOn = _filter == i;
                  final chipColor = i == 1 ? AppColors.em : i == 2 ? AppColors.red : AppColors.blue;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: GestureDetector(
                      onTap: () => setState(() => _filter = i),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: isOn ? chipColor.withValues(alpha: 0.15) : c.chipBg,
                          border: Border.all(color: isOn ? chipColor.withValues(alpha: 0.4) : c.border),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(_filterLabels[i], style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isOn ? chipColor : c.textSecondary)),
                      ),
                    ),
                  );
                }),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(color: c.chipBg, border: Border.all(color: c.border), borderRadius: BorderRadius.circular(10)),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<StockSort>(
                      value: _sort, isDense: true,
                      dropdownColor: c.cardElevated,
                      icon: Icon(LucideIcons.arrowUpDown, size: 12, color: c.textSecondary),
                      items: [
                        DropdownMenuItem(value: StockSort.name, child: Text('Name', style: TextStyle(fontSize: 11, color: c.textSecondary))),
                        DropdownMenuItem(value: StockSort.pnl, child: Text('P&L', style: TextStyle(fontSize: 11, color: c.textSecondary))),
                        DropdownMenuItem(value: StockSort.value, child: Text('Value', style: TextStyle(fontSize: 11, color: c.textSecondary))),
                        DropdownMenuItem(value: StockSort.holdings, child: Text('Qty', style: TextStyle(fontSize: 11, color: c.textSecondary))),
                      ],
                      onChanged: (v) => setState(() => _sort = v ?? StockSort.name),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Stock Cards
        Consumer<PortfolioProvider>(builder: (_, provider, __) {
          final stocks = _apply(provider.stocks.values.toList());
          if (stocks.isEmpty) {
            return SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
                child: Column(children: [
                  Icon(LucideIcons.trendingUp, size: 44, color: c.textFaint),
                  const SizedBox(height: 14),
                  Text(_filter != 0 ? 'No ${_filterLabels[_filter].toLowerCase()} stocks' : 'No stocks added', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: c.textPrimary)),
                  const SizedBox(height: 6),
                  Text('Tap + to add your first stock.', style: TextStyle(fontSize: 13, color: c.textSecondary)),
                ]),
              ),
            );
          }
          return SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            sliver: SliverList(delegate: SliverChildBuilderDelegate(
              (_, i) => StockCard(stock: stocks[i]),
              childCount: stocks.length,
            )),
          );
        }),
      ],
    );
  }

  Widget _iconBtn(IconData? icon, AC c, VoidCallback onTap, {bool loading = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42, height: 42,
        decoration: BoxDecoration(color: c.chipBg, borderRadius: BorderRadius.circular(14), border: Border.all(color: c.border)),
        child: loading
            ? const Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(AppColors.em))))
            : Icon(icon, color: c.textSecondary, size: 18),
      ),
    );
  }
}
