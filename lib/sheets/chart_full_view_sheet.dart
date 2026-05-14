import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_colors.dart';
import '../models/models.dart';
import '../utils/formatters.dart';

class ChartFullViewSheet extends StatefulWidget {
  final Stock stock;
  const ChartFullViewSheet({super.key, required this.stock});

  @override
  State<ChartFullViewSheet> createState() => _ChartFullViewSheetState();
}

class _ChartFullViewSheetState extends State<ChartFullViewSheet> {
  String _selectedFilter = 'ALL';
  final List<String> _filters = ['1H', '1D', '3D', '5D', '1W', '1M', '1Y', 'ALL'];

  @override
  Widget build(BuildContext context) {
    final s = widget.stock;

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
            colors: [AppColors.s2, AppColors.s1],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: AppColors.border3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
              child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(top: 14, bottom: 22),
                  decoration: BoxDecoration(color: AppColors.s5, borderRadius: BorderRadius.circular(2)))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.4)),
                    const SizedBox(height: 4),
                    Text('${s.code} • LKR ${s.todayPrice.toStringAsFixed(2)}', style: TextStyle(fontSize: 13, color: AppColors.t2, fontWeight: FontWeight.w600)),
                  ],
                ),
                IconButton(
                  icon: const Icon(LucideIcons.x, color: AppColors.t2),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildFilters(),
          const SizedBox(height: 20),
          Expanded(child: Padding(padding: const EdgeInsets.fromLTRB(16, 0, 24, 40), child: _buildChart(s))),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return SizedBox(
      height: 34,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final f = _filters[index];
          final isOn = _selectedFilter == f;
          return GestureDetector(
            onTap: () => setState(() => _selectedFilter = f),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isOn ? const Color(0x1A4D8FFF) : AppColors.glass,
                border: Border.all(color: isOn ? const Color(0x404D8FFF) : AppColors.border2),
                borderRadius: BorderRadius.circular(20),
              ),
              alignment: Alignment.center,
              child: Text(
                f,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isOn ? AppColors.em : AppColors.t2,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildChart(Stock s) {
    final now = DateTime.now();
    DateTime? cutoff;
    switch (_selectedFilter) {
      case '1H': cutoff = now.subtract(const Duration(hours: 1)); break;
      case '1D': cutoff = now.subtract(const Duration(days: 1)); break;
      case '3D': cutoff = now.subtract(const Duration(days: 3)); break;
      case '5D': cutoff = now.subtract(const Duration(days: 5)); break;
      case '1W': cutoff = now.subtract(const Duration(days: 7)); break;
      case '1M': cutoff = now.subtract(const Duration(days: 30)); break;
      case '1Y': cutoff = now.subtract(const Duration(days: 365)); break;
      default: cutoff = null;
    }

    var log = s.priceLog.toList()..sort((a, b) => a.dt.compareTo(b.dt));
    if (cutoff != null) {
      log = log.where((l) => l.dt.isAfter(cutoff!)).toList();
    }

    if (log.length < 2) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.trendingUp, color: AppColors.t4, size: 40),
            const SizedBox(height: 12),
            Text('Not enough price data for $_selectedFilter', style: const TextStyle(fontSize: 14, color: AppColors.t4, fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }

    final lastPrice = log.last.price;
    final isUp = lastPrice >= s.avgBuyPrice;
    final cMain = isUp ? AppColors.em : AppColors.red;

    return LineChart(
      LineChartData(
        lineBarsData: [
          LineChartBarData(
            spots: log.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.price)).toList(),
            isCurved: true,
            color: cMain,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [cMain.withOpacity(0.2), Colors.transparent],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          if (s.avgBuyPrice > 0)
            LineChartBarData(
              spots: log.asMap().entries.map((e) => FlSpot(e.key.toDouble(), s.avgBuyPrice)).toList(),
              isCurved: false,
              color: AppColors.blue.withOpacity(0.5),
              barWidth: 1.5,
              dashArray: [4, 4],
              dotData: const FlDotData(show: false),
            ),
        ],
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 44,
              getTitlesWidget: (val, meta) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Text(Formatters.compactCurrency(val), style: GoogleFonts.jetBrainsMono(fontSize: 10, color: AppColors.t3)),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              getTitlesWidget: (val, meta) {
                final idx = val.toInt();
                if (idx < 0 || idx >= log.length) return const SizedBox.shrink();
                // Show fewer dates so they don't overlap
                if (idx % (log.length / 4).ceil() != 0 && idx != log.length - 1) return const SizedBox.shrink();
                
                final dt = log[idx].dt;
                String text;
                if (['1H', '1D'].contains(_selectedFilter)) {
                  text = '${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
                } else if (['1Y', 'ALL'].contains(_selectedFilter)) {
                  text = '${dt.month}/${dt.year.toString().substring(2)}';
                } else {
                  text = '${dt.day}/${dt.month}';
                }

                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(text, style: GoogleFonts.jetBrainsMono(fontSize: 9, color: AppColors.t4)),
                );
              },
            ),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: null,
          getDrawingHorizontalLine: (value) => const FlLine(color: Color(0x0AFFFFFF), strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (touchedSpot) => const Color(0xEB0F1428),
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((LineBarSpot touchedSpot) {
                if (touchedSpot.barIndex == 1) return null; // Avg buy line
                final price = touchedSpot.y;
                final dt = log[touchedSpot.x.toInt()].dt;
                return LineTooltipItem(
                  'LKR ${price.toStringAsFixed(2)}\n',
                  GoogleFonts.jetBrainsMono(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  children: [
                    TextSpan(
                      text: Formatters.formatDate(dt),
                      style: GoogleFonts.jetBrainsMono(color: AppColors.t2, fontSize: 10, fontWeight: FontWeight.normal),
                    ),
                  ],
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }
}
