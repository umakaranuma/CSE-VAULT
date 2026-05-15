import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';


import '../theme/app_colors.dart';
import '../models/models.dart';
import '../utils/formatters.dart';

import '../screens/stocks/stock_detail_screen.dart';

class StockCard extends StatelessWidget {
  final Stock stock;
  const StockCard({super.key, required this.stock});

  @override
  Widget build(BuildContext context) {
    final s = stock;
    final isUp = s.unrealised >= 0;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => StockDetailScreen(code: s.code)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.glass,
          border: Border.all(color: AppColors.border2),
          borderRadius: BorderRadius.circular(20),
        ),
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
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: -0.1),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        s.code.replaceAll('.N0000', ''),
                        style: GoogleFonts.jetBrainsMono(fontSize: 10, color: AppColors.t3, fontWeight: FontWeight.w500),
                      ),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        width: 2, height: 2,
                        decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.t4),
                      ),
                      Text(
                        '${Formatters.compactCurrency(s.holdingsQty)} shares',
                        style: const TextStyle(fontSize: 10, color: AppColors.t3, fontWeight: FontWeight.w500),
                      ),
                      if (s.transactions.isNotEmpty) ...[
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          width: 2, height: 2,
                          decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.t4),
                        ),
                        Text(
                          '${s.transactions.length} txn${s.transactions.length != 1 ? 's' : ''}',
                          style: const TextStyle(fontSize: 10, color: AppColors.t4, fontWeight: FontWeight.w500),
                        ),
                      ],
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
                  style: GoogleFonts.jetBrainsMono(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: -0.3),
                ),
                const SizedBox(height: 3),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isUp ? const Color(0x1400FFA3) : const Color(0x14FF4D6A),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    Formatters.percentage(s.pnlPercent),
                    style: GoogleFonts.jetBrainsMono(fontSize: 11, fontWeight: FontWeight.w700, color: isUp ? AppColors.em : AppColors.red),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 6),
            const Icon(LucideIcons.chevronRight, color: AppColors.t4, size: 16),
          ],
        ),
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
      width: 46, height: 46,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(colors: [c1, c2], begin: Alignment.topLeft, end: Alignment.bottomRight),
        border: Border.all(color: border),
      ),
      alignment: Alignment.center,
      child: Text(
        code.length >= 4 ? code.substring(0, 4) : code,
        style: GoogleFonts.jetBrainsMono(fontSize: 10, fontWeight: FontWeight.w800, color: textC, letterSpacing: 0.4),
      ),
    );
  }
}
