import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';

import '../theme/app_colors.dart';
import '../models/models.dart';
import '../utils/formatters.dart';
import '../providers/portfolio_provider.dart';
import '../sheets/log_price_sheet.dart';
import '../sheets/add_transaction_sheet.dart';
import '../sheets/chart_full_view_sheet.dart';

class StockCard extends StatefulWidget {
  final Stock stock;
  const StockCard({super.key, required this.stock});

  @override
  State<StockCard> createState() => _StockCardState();
}

class _StockCardState extends State<StockCard> {
  bool _isOpen = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.stock;
    final isUp = s.unrealised >= 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.glass,
        border: Border.all(color: AppColors.border2),
        borderRadius: BorderRadius.circular(20),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _isOpen = !_isOpen),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  _buildAvatar(s.code),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.1,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Text(
                              s.code,
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 10,
                                color: AppColors.t3,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 6),
                              width: 2,
                              height: 2,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.t4,
                              ),
                            ),
                            Text(
                              '${Formatters.compactCurrency(s.holdingsQty)} shares',
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.t3,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'LKR ${s.todayPrice.toStringAsFixed(2)}',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        Formatters.percentage(s.pnlPercent),
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isUp ? AppColors.em : AppColors.red,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: _isOpen ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 250),
                    child: const Icon(
                      LucideIcons.chevronDown,
                      color: AppColors.t4,
                      size: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isOpen)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 14),
                  _buildTodayTile(context, s),
                  const SizedBox(height: 12),
                  _buildMetricsGrid(s, isUp),
                  const SizedBox(height: 14),
                  _buildChart(s),
                  const SizedBox(height: 14),
                  _buildActionButtons(context, s.code),
                  if (s.priceLog.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildSubSectionTitle('Price Log'),
                    ...s.priceLog
                        .take(8)
                        .map((l) => _buildLogItem(context, s, l)),
                  ],
                  if (s.transactions.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildSubSectionTitle('Transactions'),
                    ...s.transactions
                        .take(6)
                        .map((t) => _buildTxItem(context, s, t)),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAvatar(String code) {
    int sum = code.codeUnits.fold(0, (a, b) => a + b);
    final avTypes = ['green', 'blue', 'gold'];
    final avType = avTypes[sum % avTypes.length];

    Color c1, c2, border, textC;
    if (avType == 'green') {
      c1 = const Color(0x2600FFA3);
      c2 = const Color(0x1A00B872);
      border = const Color(0x4000FFA3);
      textC = AppColors.em;
    } else if (avType == 'blue') {
      c1 = const Color(0x264D8FFF);
      c2 = const Color(0x144D8FFF);
      border = const Color(0x404D8FFF);
      textC = AppColors.blue;
    } else {
      c1 = const Color(0x26FFC53D);
      c2 = const Color(0x14FFC53D);
      border = const Color(0x40FFC53D);
      textC = AppColors.gold;
    }

    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          colors: [c1, c2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: border),
      ),
      alignment: Alignment.center,
      child: Text(
        code.substring(0, 4),
        style: GoogleFonts.jetBrainsMono(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: textC,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  Widget _buildTodayTile(BuildContext context, Stock s) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0x0A00FFA3),
        border: Border.all(color: const Color(0x1F00FFA3)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'TODAY\'S PRICE',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Color(0x8000FFA3),
                  letterSpacing: 1.0,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Tap to update',
                style: TextStyle(fontSize: 10, color: AppColors.t3),
              ),
            ],
          ),
          SizedBox(
            width: 120,
            child: TextField(
              controller: TextEditingController(
                text: s.todayPrice.toStringAsFixed(2),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textAlign: TextAlign.right,
              style: GoogleFonts.jetBrainsMono(
                color: AppColors.em,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.zero,
                border: InputBorder.none,
              ),
              onSubmitted: (v) {
                final d = double.tryParse(v);
                if (d != null && d > 0) {
                  context.read<PortfolioProvider>().updateTodayPrice(s.code, d);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(Stock s, bool isUp) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 2.5,
      children: [
        _buildMetricBox(
          'AVG BUY',
          s.avgBuyPrice > 0 ? s.avgBuyPrice.toStringAsFixed(2) : '—',
          Colors.white,
        ),
        _buildMetricBox(
          'IN MARKET',
          Formatters.compactCurrency(s.unrealised),
          isUp ? AppColors.em : AppColors.red,
        ),
        _buildMetricBox(
          'CASHED OUT',
          Formatters.compactCurrency(s.realised),
          s.realised >= 0 ? AppColors.em : AppColors.red,
        ),
        _buildMetricBox(
          'BOUGHT',
          Formatters.compactCurrency(s.totalBoughtQty),
          AppColors.em,
        ),
        _buildMetricBox(
          'SOLD',
          Formatters.compactCurrency(s.totalSoldQty),
          AppColors.gold,
        ),
        _buildMetricBox(
          'HOLDING',
          Formatters.compactCurrency(s.holdingsQty),
          AppColors.blue,
        ),
      ],
    );
  }

  Widget _buildMetricBox(String label, String value, Color vColor) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0x40000000),
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: AppColors.t4,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: vColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChart(Stock s) {
    final log = s.priceLog.toList()..sort((a, b) => a.dt.compareTo(b.dt));
    if (log.length < 2) {
      return Container(
        height: 130,
        decoration: BoxDecoration(
          color: const Color(0x33000000),
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(LucideIcons.trendingUp, color: AppColors.t4, size: 28),
            SizedBox(height: 5),
            Text(
              'Log 2+ prices to see chart',
              style: TextStyle(fontSize: 11, color: AppColors.t4),
            ),
          ],
        ),
      );
    }

    final lastPrice = log.last.price;
    final isUp = lastPrice >= s.avgBuyPrice;
    final cMain = isUp ? AppColors.em : AppColors.red;

    return Stack(
      children: [
        Container(
          height: 130,
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0x33000000),
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(14),
          ),
          child: LineChart(
            LineChartData(
              lineBarsData: [
                LineChartBarData(
                  spots: log
                      .asMap()
                      .entries
                      .map((e) => FlSpot(e.key.toDouble(), e.value.price))
                      .toList(),
                  isCurved: true,
                  color: cMain,
                  barWidth: 2,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [cMain.withOpacity(0.18), Colors.transparent],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
                LineChartBarData(
                  spots: log
                      .asMap()
                      .entries
                      .map((e) => FlSpot(e.key.toDouble(), s.avgBuyPrice))
                      .toList(),
                  isCurved: false,
                  color: AppColors.blue.withOpacity(0.5),
                  barWidth: 1.5,
                  dashArray: [4, 4],
                  dotData: const FlDotData(show: false),
                ),
              ],
              titlesData: FlTitlesData(
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (val, meta) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Text(
                          val.toStringAsFixed(0),
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 9,
                            color: AppColors.t3,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 10,
                getDrawingHorizontalLine: (value) =>
                    const FlLine(color: Color(0x0AFFFFFF), strokeWidth: 1),
              ),
              borderData: FlBorderData(show: false),
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: IconButton(
            icon: const Icon(
              LucideIcons.maximize2,
              size: 16,
              color: AppColors.t2,
            ),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => ChartFullViewSheet(stock: s),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, String code) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildBtn(
                'Buy',
                LucideIcons.trendingUp,
                const Color(0x2600FFA3),
                const Color(0x1400B872),
                const Color(0x3300FFA3),
                AppColors.em,
                () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) =>
                        AddTransactionSheet(code: code, type: 'buy'),
                  );
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildBtn(
                'Sell',
                LucideIcons.trendingDown,
                const Color(0x26FF4D6A),
                const Color(0x14FF2D4D),
                const Color(0x33FF4D6A),
                AppColors.red,
                () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) =>
                        AddTransactionSheet(code: code, type: 'sell'),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: _buildBtn(
            'Log Today\'s Price',
            LucideIcons.clock,
            const Color(0x1A4D8FFF),
            const Color(0x0D4D8FFF),
            const Color(0x264D8FFF),
            AppColors.blue,
            () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => LogPriceSheet(code: code),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBtn(
    String text,
    IconData icon,
    Color c1,
    Color c2,
    Color b,
    Color tColor,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(13),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(13),
          gradient: LinearGradient(
            colors: [c1, c2],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: b),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: tColor),
            const SizedBox(width: 7),
            Text(
              text,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: tColor,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 10),
      child: Row(
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.t3,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Container(height: 1, color: AppColors.border)),
        ],
      ),
    );
  }

  Widget _buildLogItem(BuildContext context, Stock s, PriceLog l) {
    final isNearClose = l.price >= s.todayPrice * 0.99;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isNearClose ? AppColors.em : AppColors.red,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LKR ${l.price.toStringAsFixed(2)}',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  Formatters.formatDate(l.dt),
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.t3,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (l.note != null && l.note!.isNotEmpty)
                  Text(
                    l.note!,
                    style: const TextStyle(fontSize: 10, color: AppColors.t2),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(LucideIcons.x, size: 14, color: AppColors.t3),
            onPressed: () =>
                context.read<PortfolioProvider>().deletePriceLog(s.code, l.id),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildTxItem(BuildContext context, Stock s, Transaction t) {
    final isBuy = t.type == 'buy';
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: isBuy ? const Color(0x1400FFA3) : const Color(0x14FF4D6A),
              border: Border.all(
                color: isBuy
                    ? const Color(0x2600FFA3)
                    : const Color(0x26FF4D6A),
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isBuy ? LucideIcons.trendingUp : LucideIcons.trendingDown,
              size: 15,
              color: isBuy ? AppColors.em : AppColors.red,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.type.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isBuy ? AppColors.em : AppColors.red,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  Formatters.formatDate(t.dt),
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10,
                    color: AppColors.t3,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'LKR ${t.price.toStringAsFixed(2)}',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${Formatters.compactCurrency(t.qty)} shares',
                style: const TextStyle(fontSize: 10, color: AppColors.t2),
              ),
            ],
          ),
          const SizedBox(width: 10),
          IconButton(
            icon: const Icon(LucideIcons.x, size: 14, color: AppColors.t3),
            onPressed: () => context
                .read<PortfolioProvider>()
                .deleteTransaction(s.code, t.id),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}
