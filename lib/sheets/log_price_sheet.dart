import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../providers/portfolio_provider.dart';

class LogPriceSheet extends StatefulWidget {
  final String code;
  const LogPriceSheet({super.key, required this.code});

  @override
  State<LogPriceSheet> createState() => _LogPriceSheetState();
}

class _LogPriceSheetState extends State<LogPriceSheet> {
  final _priceC = TextEditingController();
  final _noteC = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final stockName = context.read<PortfolioProvider>().stocks[widget.code]?.name ?? '';
    
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [AppColors.s2, AppColors.s1], begin: Alignment.topCenter, end: Alignment.bottomCenter),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: AppColors.border3)),
      ),
      padding: EdgeInsets.only(left: 20, right: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(top: 14, bottom: 22), decoration: BoxDecoration(color: AppColors.s5, borderRadius: BorderRadius.circular(2)))),
            Text('Log Price — $stockName', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.4)),
            const SizedBox(height: 16),
            _buildField('Price (LKR) *', _priceC, '93.80', isNum: true),
            const SizedBox(height: 16),
            _buildField('Note (optional)', _noteC, 'Opening / Closing / Midday...'),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.em,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 17),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Text('Log Price', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: -0.2)),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.t2,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: AppColors.border2)),
                ),
                child: const Text('Cancel', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, String hint, {bool isNum = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.t2, letterSpacing: 1.0)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: isNum ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.t3),
            filled: true,
            fillColor: const Color(0x4D000000),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.border3)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.border3)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.em, width: 2)),
          ),
        ),
      ],
    );
  }

  void _save() {
    final price = double.tryParse(_priceC.text) ?? 0;
    if (price <= 0) return;

    context.read<PortfolioProvider>().logPrice(widget.code, price, DateTime.now(), _noteC.text.trim());
    Navigator.pop(context);
  }
}
