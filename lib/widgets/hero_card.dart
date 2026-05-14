import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../providers/portfolio_provider.dart';
import '../utils/formatters.dart';

class HeroCard extends StatelessWidget {
  const HeroCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PortfolioProvider>(
      builder: (context, provider, child) {
        final totalValue = provider.totalValue;
        final totalInvested = provider.totalInvested;
        final totalUnrealised = provider.totalUnrealised;
        final totalRealised = provider.totalRealised;
        final pnlPercent = provider.totalPnlPercent;
        final isUp = totalUnrealised >= 0;

        final valueParts = totalValue.toStringAsFixed(2).split('.');
        final valueMain = int.parse(valueParts[0]).toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
        final valueCents = valueParts[1];

        return Container(
          margin: const EdgeInsets.fromLTRB(16, 6, 16, 20),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: const LinearGradient(
              colors: [Color(0xFF0D1528), Color(0xFF0A1220), Color(0xFF0D1E1A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: const Color(0x1F00FFA3)),
            boxShadow: const [
              BoxShadow(color: Color(0x80000000), blurRadius: 60, offset: Offset(0, 20)),
              BoxShadow(color: Color(0x0D00FFA3), spreadRadius: 1),
            ],
          ),
          child: Stack(
            children: [
              // Sparkles / Background elements
              Positioned(
                top: -60,
                right: -60,
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [Color(0x1A00FFA3), Colors.transparent],
                      stops: [0.0, 0.65],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: -40,
                left: -40,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [Color(0x124D8FFF), Colors.transparent],
                      stops: [0.0, 0.65],
                    ),
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'TOTAL VALUE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0x9900FFA3),
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        'LKR $valueMain',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -1.5,
                          shadows: [
                            const Shadow(
                              color: Color(0x2600FFA3),
                              blurRadius: 40,
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '.$valueCents',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: isUp ? const Color(0x1F00FFA3) : const Color(0x1FFF4D6A),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isUp ? const Color(0x3300FFA3) : const Color(0x33FF4D6A),
                      ),
                    ),
                    child: Text(
                      '${isUp ? '▲' : '▼'} ${Formatters.percentage(pnlPercent)}  |  ${isUp ? '+' : ''}LKR ${Formatters.compactCurrency(totalUnrealised)}',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isUp ? AppColors.em : AppColors.red,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0x33000000),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        _buildStat('INVESTED', 'LKR ${Formatters.compactCurrency(totalInvested)}', Colors.white),
                        Container(width: 1, height: 30, color: AppColors.border),
                        _buildStat('UNREALISED', '${isUp ? '+' : ''}${Formatters.compactCurrency(totalUnrealised)}', isUp ? AppColors.em : AppColors.red),
                        Container(width: 1, height: 30, color: AppColors.border),
                        _buildStat('REALISED', '${totalRealised >= 0 ? '+' : ''}${Formatters.compactCurrency(totalRealised)}', totalRealised >= 0 ? AppColors.em : AppColors.red),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStat(String label, String value, Color valueColor) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: AppColors.t3,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: valueColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
