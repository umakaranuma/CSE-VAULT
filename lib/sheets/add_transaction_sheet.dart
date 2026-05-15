import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../providers/portfolio_provider.dart';
import '../models/models.dart';

class AddTransactionSheet extends StatefulWidget {
  final String code;
  final String type;
  /// If editing, pass the existing transaction
  final Transaction? editTransaction;

  const AddTransactionSheet({
    super.key,
    required this.code,
    required this.type,
    this.editTransaction,
  });

  @override
  State<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<AddTransactionSheet> {
  late String _type;
  final _qtyC = TextEditingController();
  final _priceC = TextEditingController();
  final _commissionPercentC = TextEditingController(text: '1.12');

  bool get _isEditing => widget.editTransaction != null;

  @override
  void initState() {
    super.initState();
    _type = widget.type;

    // Pre-fill fields if editing
    if (_isEditing) {
      final t = widget.editTransaction!;
      _type = t.type;
      _qtyC.text = t.qty.toString();
      _priceC.text = t.price.toString();
      // Reverse-calculate commission percent from stored amount
      final total = t.qty * t.price;
      if (total > 0 && t.commission > 0) {
        _commissionPercentC.text = ((t.commission / total) * 100).toStringAsFixed(2);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
            Text(_isEditing ? 'Edit Transaction' : 'Add Transaction', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.4)),
            const SizedBox(height: 16),
            const Text('TRANSACTION TYPE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.t2, letterSpacing: 1.0)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _buildTypeToggle('Buy', 'buy', _type == 'buy', AppColors.em, const Color(0x3300FFA3))),
                const SizedBox(width: 4),
                Expanded(child: _buildTypeToggle('Sell', 'sell', _type == 'sell', AppColors.red, const Color(0x33FF4D6A))),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildField('Quantity *', _qtyC, '100', isNum: true)),
                const SizedBox(width: 12),
                Expanded(child: _buildField('Price / Share *', _priceC, '95.00', isNum: true)),
              ],
            ),
            const SizedBox(height: 16),
            _buildField('Broker Fee (%)', _commissionPercentC, '1.12', isNum: true),
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
                child: Text(_isEditing ? 'Save Changes' : 'Add Transaction', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: -0.2)),
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

  Widget _buildTypeToggle(String label, String value, bool isSelected, Color activeColor, Color activeBg) {
    return GestureDetector(
      onTap: () => setState(() => _type = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? activeBg : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: isSelected ? activeColor.withValues(alpha: 0.5) : Colors.transparent),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isSelected ? activeColor : AppColors.t2,
          ),
        ),
      ),
    );
  }

  void _save() {
    final qty = double.tryParse(_qtyC.text) ?? 0;
    final price = double.tryParse(_priceC.text) ?? 0;
    final commissionPercent = double.tryParse(_commissionPercentC.text) ?? 1.12;

    if (qty <= 0 || price <= 0) return;

    final commissionAmount = (qty * price) * (commissionPercent / 100);
    final provider = context.read<PortfolioProvider>();

    if (_isEditing) {
      provider.updateTransaction(widget.code, widget.editTransaction!.id, _type, qty, price, commission: commissionAmount);
    } else {
      provider.addTransaction(widget.code, _type, qty, price, DateTime.now(), commission: commissionAmount);
    }
    Navigator.pop(context);
  }
}
