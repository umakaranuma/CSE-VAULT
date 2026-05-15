import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_colors.dart';
import 'home/home_screen.dart';
import 'stocks/stocks_screen.dart';
import 'history/history_screen.dart';
import 'more/more_screen.dart';
import '../sheets/add_stock_sheet.dart';

import '../providers/portfolio_provider.dart';
import 'package:provider/provider.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PortfolioProvider>().refreshPrices();
    });
  }
  
  final List<Widget> _screens = [
    const HomeScreen(),
    const StocksScreen(),
    const HistoryScreen(),
    const MoreScreen(),
  ];



  void _showAddStockSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddStockSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = colors(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: c.bg,
      body: Stack(
        children: [
          if (isDark)
            Positioned(
              top: -100,
              right: -80,
              child: Container(
                width: 300,
                height: 300,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [Color(0x1400FFA3), Colors.transparent],
                    stops: [0.0, 0.7],
                  ),
                ),
              ),
            ),
          if (isDark)
            Positioned(
              bottom: 100,
              left: -80,
              child: Container(
                width: 250,
                height: 250,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [Color(0x124D8FFF), Colors.transparent],
                    stops: [0.0, 0.7],
                  ),
                ),
              ),
            ),
          
          SafeArea(
            bottom: false,
            child: IndexedStack(
              index: _currentIndex,
              children: _screens,
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        height: 76 + MediaQuery.of(context).padding.bottom,
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
        decoration: BoxDecoration(
          color: c.navBar,
          border: Border(top: BorderSide(color: c.border, width: 1)),
        ),
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: 0,
              left: MediaQuery.of(context).size.width * 0.1,
              right: MediaQuery.of(context).size.width * 0.1,
              child: Container(
                height: 1,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.transparent, Color(0x4D00FFA3), Colors.transparent],
                  ),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildTabItem(0, 'Home', LucideIcons.home),
                _buildTabItem(1, 'Stocks', LucideIcons.trendingUp),
                const SizedBox(width: 72), // Space for FAB
                _buildTabItem(2, 'History', LucideIcons.clock),
                _buildTabItem(3, 'More', LucideIcons.moreHorizontal),
              ],
            ),
            // FAB
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 12,
              child: GestureDetector(
                onTap: _showAddStockSheet,
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(17),
                    gradient: const LinearGradient(
                      colors: [AppColors.em, AppColors.em2],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: const [
                      BoxShadow(color: Color(0x4D00FFA3), blurRadius: 24, offset: Offset(0, 8)),
                      BoxShadow(color: Color(0x3300FFA3), blurRadius: 8, offset: Offset(0, 2)),
                    ],
                  ),
                  child: const Icon(LucideIcons.plus, color: AppColors.bg, size: 28),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabItem(int index, String label, IconData icon) {
    bool isActive = _currentIndex == index;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          setState(() {
            _currentIndex = index;
          });
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 22,
              color: isActive ? AppColors.em : AppColors.t3,
            ),
            const SizedBox(height: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isActive ? AppColors.em : AppColors.t3,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
