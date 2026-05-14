import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../theme/app_colors.dart';
import '../../providers/portfolio_provider.dart';
import '../../widgets/stock_card.dart';
import '../../sheets/add_stock_sheet.dart';

class StocksScreen extends StatelessWidget {
  const StocksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
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
                    const Text(
                      'My Stocks',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Consumer<PortfolioProvider>(
                      builder: (context, provider, _) {
                        final count = provider.stocks.length;
                        return Text(
                          '$count stock${count != 1 ? 's' : ''} tracked',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.t2,
                          ),
                        );
                      },
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => const AddStockSheet(),
                    );
                  },
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.glass2,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border2),
                    ),
                    child: const Icon(LucideIcons.plus, color: AppColors.t2, size: 18),
                  ),
                ),
              ],
            ),
          ),
        ),
        Consumer<PortfolioProvider>(
          builder: (context, provider, child) {
            final stocks = provider.stocks.values.toList();
            if (stocks.isEmpty) {
              return SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
                  child: Column(
                    children: [
                      const Text('📊', style: TextStyle(fontSize: 48)),
                      const SizedBox(height: 16),
                      const Text(
                        'No stocks added',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, letterSpacing: -0.2),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Add stocks to track your holdings, buy/sell history, and P&L.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: AppColors.t2, height: 1.6),
                      ),
                    ],
                  ),
                ),
              );
            }
            return SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 30),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    return StockCard(stock: stocks[index]);
                  },
                  childCount: stocks.length,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
