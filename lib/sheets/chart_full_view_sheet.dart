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

    // Time-based X values (minutes from first entry)
    final baseTime = log.first.dt.millisecondsSinceEpoch.toDouble();
    final spots = log
        .map((l) => FlSpot(
              (l.dt.millisecondsSinceEpoch.toDouble() - baseTime) / 60000,
              l.price,
            ))
        .toList();

    // Tight Y bounds
    final prices = log.map((l) => l.price).toList();
    final minPrice = prices.reduce((a, b) => a < b ? a : b);
    final maxPrice = prices.reduce((a, b) => a > b ? a : b);
    final priceRange = maxPrice - minPrice;
    final yPadding = priceRange > 0 ? priceRange * 0.12 : maxPrice * 0.02;
    final yMin = minPrice - yPadding;
    final yMax = maxPrice + yPadding;

    final lastPrice = log.last.price;
    final isUp = lastPrice >= s.avgBuyPrice;
    final cMain = isUp ? AppColors.em : AppColors.red;

    final showAvgLine = s.avgBuyPrice >= yMin && s.avgBuyPrice <= yMax && s.avgBuyPrice > 0;

    final gridInterval = priceRange > 0
        ? (priceRange / 4).ceilToDouble().clamp(0.1, 1000.0)
        : 1.0;

    return LineChart(
      LineChartData(
        minY: yMin,
        maxY: yMax,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.25,
            color: cMain,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, bar, index) =>
                  FlDotCirclePainter(
                radius: 3.5,
                color: cMain,
                strokeWidth: 2,
                strokeColor: AppColors.bg,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [cMain.withValues(alpha: 0.2), Colors.transparent],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          if (showAvgLine)
            LineChartBarData(
              spots: [
                FlSpot(spots.first.x, s.avgBuyPrice),
                FlSpot(spots.last.x, s.avgBuyPrice),
              ],
              isCurved: false,
              color: AppColors.blue.withValues(alpha: 0.5),
              barWidth: 1.5,
              dashArray: [4, 4],
              dotData: const FlDotData(show: false),
            ),
        ],
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 50,
              getTitlesWidget: (val, meta) {
                if (val == meta.min || val == meta.max) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Text(val.toStringAsFixed(1), style: GoogleFonts.jetBrainsMono(fontSize: 10, color: AppColors.t3)),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (val, meta) {
                // Find closest log entry to this X value
                int closestIdx = 0;
                double closestDist = double.infinity;
                for (int i = 0; i < spots.length; i++) {
                  final dist = (spots[i].x - val).abs();
                  if (dist < closestDist) {
                    closestDist = dist;
                    closestIdx = i;
                  }
                }
                // Only show labels at spaced intervals
                if (closestDist > 1) return const SizedBox.shrink();
                final step = (log.length / 5).ceil().clamp(1, log.length);
                if (closestIdx % step != 0 && closestIdx != log.length - 1) return const SizedBox.shrink();

                final dt = log[closestIdx].dt;
                String text;
                if (['1H', '1D'].contains(_selectedFilter)) {
                  text = Formatters.formatTime(dt);
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
          horizontalInterval: gridInterval,
          getDrawingHorizontalLine: (value) => const FlLine(color: Color(0x0AFFFFFF), strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            fitInsideHorizontally: true,
            fitInsideVertically: true,
            getTooltipColor: (touchedSpot) => const Color(0xEB0F1428),
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                if (spot.barIndex > 0) return null;
                final idx = spot.spotIndex;
                final entry = idx < log.length ? log[idx] : null;
                final timeStr = entry != null ? Formatters.formatTime(entry.dt) : '';
                final dateStr = entry != null ? Formatters.formatDateWithDay(entry.dt) : '';
                final noteStr = entry?.note ?? '';
                return LineTooltipItem(
                  '$timeStr  $dateStr\n',
                  const TextStyle(fontSize: 10, color: AppColors.t2, height: 1.5),
                  children: [
                    TextSpan(
                      text: 'LKR ${spot.y.toStringAsFixed(2)}',
                      style: GoogleFonts.jetBrainsMono(fontSize: 14, fontWeight: FontWeight.w800, color: cMain),
                    ),
                    if (noteStr.isNotEmpty)
                      TextSpan(
                        text: '\n$noteStr',
                        style: const TextStyle(fontSize: 9, color: AppColors.t3, fontWeight: FontWeight.w500),
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
