import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_colors.dart';
import '../../providers/theme_provider.dart';
import '../../providers/portfolio_provider.dart';


class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.glass : Colors.white;
    final borderColor = isDark ? AppColors.border2 : const Color(0x1A000000);
    final subtitleColor = isDark ? AppColors.t2 : const Color(0xFF6B7280);

    return CustomScrollView(
      slivers: [
        // ── Header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Settings', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                const SizedBox(height: 3),
                Text('Preferences & portfolio tools', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: subtitleColor)),
              ],
            ),
          ),
        ),

        // ── Portfolio Summary
        SliverToBoxAdapter(
          child: Consumer<PortfolioProvider>(
            builder: (context, provider, _) {
              final stockCount = provider.stocks.length;
              final totalTxns = provider.stocks.values.fold<int>(0, (s, st) => s + st.transactions.length);
              final totalLogs = provider.stocks.values.fold<int>(0, (s, st) => s + st.priceLog.length);

              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: cardColor,
                    border: Border.all(color: borderColor),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(LucideIcons.database, size: 16, color: AppColors.blue),
                          const SizedBox(width: 8),
                          const Text('LOCAL DATA', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.blue, letterSpacing: 1.0)),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          _dataStat('Stocks', '$stockCount', AppColors.em),
                          const SizedBox(width: 16),
                          _dataStat('Transactions', '$totalTxns', AppColors.gold),
                          const SizedBox(width: 16),
                          _dataStat('Price Logs', '$totalLogs', AppColors.blue),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // ── Appearance Section
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
            child: Text('APPEARANCE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: subtitleColor, letterSpacing: 1.0)),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              decoration: BoxDecoration(color: cardColor, border: Border.all(color: borderColor), borderRadius: BorderRadius.circular(16)),
              child: Consumer<ThemeProvider>(
                builder: (context, themeProvider, _) {
                  return _settingsTile(
                    icon: themeProvider.isDark ? LucideIcons.moon : LucideIcons.sun,
                    iconColor: themeProvider.isDark ? const Color(0xFF9B7DFF) : AppColors.gold,
                    title: themeProvider.isDark ? 'Dark Mode' : 'Light Mode',
                    subtitle: themeProvider.isDark ? 'Tap to switch to light' : 'Tap to switch to dark',
                    trailing: Switch.adaptive(
                      value: themeProvider.isDark,
                      onChanged: (_) => themeProvider.toggle(),
                      activeTrackColor: AppColors.em.withValues(alpha: 0.4),
                      activeColor: AppColors.em,
                      inactiveTrackColor: AppColors.gold.withValues(alpha: 0.3),
                      inactiveThumbColor: AppColors.gold,
                    ),
                  );
                },
              ),
            ),
          ),
        ),

        // ── Data Management Section
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
            child: Text('DATA MANAGEMENT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: subtitleColor, letterSpacing: 1.0)),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              decoration: BoxDecoration(color: cardColor, border: Border.all(color: borderColor), borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  _settingsTile(
                    icon: LucideIcons.refreshCw,
                    iconColor: AppColors.em,
                    title: 'Refresh All Prices',
                    subtitle: 'Fetch latest from CSE',
                    onTap: () {
                      context.read<PortfolioProvider>().refreshPrices();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: const Text('Refreshing prices...'), backgroundColor: isDark ? AppColors.s3 : Colors.black87, duration: const Duration(seconds: 2)),
                      );
                    },
                  ),
                  Divider(height: 1, color: borderColor),
                  _settingsTile(
                    icon: LucideIcons.trash2,
                    iconColor: AppColors.red,
                    title: 'Clear All Data',
                    subtitle: 'Delete all stocks, transactions & logs',
                    onTap: () => _showClearDialog(context),
                  ),
                ],
              ),
            ),
          ),
        ),

        // ── About Section
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
            child: Text('ABOUT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: subtitleColor, letterSpacing: 1.0)),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              decoration: BoxDecoration(color: cardColor, border: Border.all(color: borderColor), borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  _settingsTile(icon: LucideIcons.info, iconColor: AppColors.blue, title: 'CSE Vault', subtitle: 'Version 1.0.0'),
                  Divider(height: 1, color: borderColor),
                  _settingsTile(icon: LucideIcons.code2, iconColor: AppColors.t2, title: 'Built with', subtitle: 'Flutter • Hive • CSE API'),
                ],
              ),
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  Widget _dataStat(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: GoogleFonts.jetBrainsMono(fontSize: 22, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 10, color: AppColors.t2, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _settingsTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.t2)),
                ],
              ),
            ),
            if (trailing != null) trailing,
            if (onTap != null && trailing == null)
              const Icon(LucideIcons.chevronRight, size: 16, color: AppColors.t3),
          ],
        ),
      ),
    );
  }

  void _showClearDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? AppColors.s2 : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Clear All Data?', style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text('This will permanently delete all your stocks, transactions, and price logs. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: AppColors.t2))),
          TextButton(
            onPressed: () {
              final provider = context.read<PortfolioProvider>();
              final codes = provider.stocks.keys.toList();
              for (final code in codes) {
                provider.deleteStock(code);
              }
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All data cleared'), backgroundColor: AppColors.red, duration: Duration(seconds: 2)),
              );
            },
            child: const Text('Delete All', style: TextStyle(color: AppColors.red, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
