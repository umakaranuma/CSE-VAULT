import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../providers/portfolio_provider.dart';
import '../services/cse_service.dart';

class AddStockSheet extends StatefulWidget {
  const AddStockSheet({super.key});

  @override
  State<AddStockSheet> createState() => _AddStockSheetState();
}

class _AddStockSheetState extends State<AddStockSheet> {
  String _type = 'buy';
  final _codeC = TextEditingController();
  final _nameC = TextEditingController();
  final _qtyC = TextEditingController();
  final _priceC = TextEditingController();
  final _todayC = TextEditingController();
  final _commissionPercentC = TextEditingController(text: '1.12');
  final _cseService = CseService();

  bool _isFetching = false;
  List<dynamic> _allStocks = [];
  List<dynamic> _filteredStocks = [];

  /// Tracks which field is actively showing suggestions: 'code', 'name', or null
  String? _activeSearchField;

  final _codeFocus = FocusNode();
  final _nameFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _codeC.addListener(_onCodeChanged);
    _nameC.addListener(_onNameChanged);
    _codeFocus.addListener(() {
      if (!_codeFocus.hasFocus && _activeSearchField == 'code') {
        // Delay so tap on suggestion registers before we hide
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted && !_codeFocus.hasFocus) {
            setState(() => _activeSearchField = null);
          }
        });
      }
    });
    _nameFocus.addListener(() {
      if (!_nameFocus.hasFocus && _activeSearchField == 'name') {
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted && !_nameFocus.hasFocus) {
            setState(() => _activeSearchField = null);
          }
        });
      }
    });
    _fetchAllStocks();
  }

  @override
  void dispose() {
    _codeC.removeListener(_onCodeChanged);
    _nameC.removeListener(_onNameChanged);
    _codeC.dispose();
    _nameC.dispose();
    _qtyC.dispose();
    _priceC.dispose();
    _todayC.dispose();
    _commissionPercentC.dispose();
    _codeFocus.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  // ─── Data Fetching ───────────────────────────────────────────

  Future<void> _fetchAllStocks() async {
    setState(() => _isFetching = true);
    try {
      final stocks = await _cseService.getTradeSummary();
      if (mounted) {
        setState(() {
          _allStocks = stocks;
          debugPrint('Loaded ${_allStocks.length} stocks for search.');
        });
      }
    } catch (e) {
      debugPrint('Failed to load stocks: $e');
    } finally {
      if (mounted) setState(() => _isFetching = false);
    }
  }

  // ─── Search / Filter Logic ───────────────────────────────────

  void _onCodeChanged() {
    if (!_codeFocus.hasFocus) return; // Only filter when user is typing here
    final query = _codeC.text.trim().toUpperCase();
    _filterAndShow(query, 'code');
  }

  void _onNameChanged() {
    if (!_nameFocus.hasFocus) return;
    final query = _nameC.text.trim().toUpperCase();
    _filterAndShow(query, 'name');
  }

  void _filterAndShow(String query, String field) {
    if (query.isEmpty) {
      setState(() {
        _filteredStocks = [];
        _activeSearchField = null;
      });
      return;
    }

    // Check for exact symbol match to auto-fill
    final exactMatch = _allStocks.firstWhere(
      (s) => s['symbol']?.toString().toUpperCase() == query,
      orElse: () => null,
    );

    if (exactMatch != null && field == 'code') {
      _nameC.text = exactMatch['name']?.toString() ?? _nameC.text;
      _todayC.text = (exactMatch['price'] ?? exactMatch['lastTradedPrice'])?.toString() ?? _todayC.text;
    }

    final filtered = _allStocks.where((s) {
      final symbol = s['symbol']?.toString().toUpperCase() ?? '';
      final name = s['name']?.toString().toUpperCase() ?? '';
      if (field == 'code') {
        return symbol.contains(query) || name.contains(query);
      } else {
        // Name field: prioritise name match, but also match symbol
        return name.contains(query) || symbol.contains(query);
      }
    }).toList();

    setState(() {
      _filteredStocks = filtered.take(6).toList();
      _activeSearchField = (_filteredStocks.isNotEmpty && exactMatch == null) ? field : null;
    });
  }

  void _selectStock(Map<String, dynamic> stock) {
    setState(() {
      _codeC.text = stock['symbol']?.toString() ?? '';
      _nameC.text = stock['name']?.toString() ?? '';
      _todayC.text = (stock['price'] ?? stock['lastTradedPrice'])?.toString() ?? '';
      _activeSearchField = null;
      _filteredStocks = [];
    });
    FocusScope.of(context).unfocus();
  }

  // ─── Build ───────────────────────────────────────────────────

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
            // ── Drag handle
            Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(top: 14, bottom: 22), decoration: BoxDecoration(color: AppColors.s5, borderRadius: BorderRadius.circular(2)))),
            // ── Title row
            Row(
              children: [
                const Text('Add Stock', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.4)),
                const Spacer(),
                if (_isFetching)
                  const SizedBox(
                    width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(AppColors.em)),
                  )
                else if (_allStocks.isNotEmpty)
                  Text('${_allStocks.length} stocks', style: const TextStyle(fontSize: 11, color: AppColors.t3))
                else
                  GestureDetector(
                    onTap: _fetchAllStocks,
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.refresh, size: 14, color: AppColors.red),
                        SizedBox(width: 4),
                        Text('Retry', style: TextStyle(fontSize: 11, color: AppColors.red)),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Stock Code field + suggestions
            _buildSearchField('Stock Code *', _codeC, 'AAIC.N0000', _codeFocus, 'code'),
            if (_activeSearchField == 'code') _buildSuggestionsList(),
            const SizedBox(height: 16),

            // ── Company Name field + suggestions
            _buildSearchField('Company Name *', _nameC, 'Softlogic Life', _nameFocus, 'name'),
            if (_activeSearchField == 'name') _buildSuggestionsList(),
            const SizedBox(height: 16),

            // ── Transaction Type
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

            // ── Quantity & Price
            Row(
              children: [
                Expanded(child: _buildField('Quantity *', _qtyC, '510', isNum: true)),
                const SizedBox(width: 12),
                Expanded(child: _buildField('Price / Share (LKR) *', _priceC, '97.90', isNum: true)),
              ],
            ),
            const SizedBox(height: 16),

            // ── Current Price & Broker Fee
            Row(
              children: [
                Expanded(flex: 2, child: _buildField('Current Price (LKR)', _todayC, 'Auto from CSE', isNum: true)),
                const SizedBox(width: 12),
                Expanded(flex: 1, child: _buildField('Broker Fee (%)', _commissionPercentC, '1.12', isNum: true)),
              ],
            ),
            const SizedBox(height: 24),

            // ── Save button
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
                child: const Text('Add to Portfolio', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: -0.2)),
              ),
            ),
            const SizedBox(height: 10),

            // ── Cancel button
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

  // ─── Search-enabled text field ────────────────────────────────

  Widget _buildSearchField(String label, TextEditingController controller, String hint, FocusNode focusNode, String fieldKey) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.t2, letterSpacing: 1.0)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: TextInputType.text,
          textCapitalization: fieldKey == 'code' ? TextCapitalization.characters : TextCapitalization.words,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          onTap: () {
            if (_allStocks.isEmpty && !_isFetching) _fetchAllStocks();
          },
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.t3),
            filled: true,
            fillColor: const Color(0x4D000000),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.border3)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.border3)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.em, width: 2)),
            prefixIcon: Icon(
              fieldKey == 'code' ? Icons.tag : Icons.business,
              size: 18,
              color: AppColors.t3,
            ),
            suffixIcon: controller.text.isNotEmpty
                ? GestureDetector(
                    onTap: () {
                      controller.clear();
                      if (fieldKey == 'code') {
                        _nameC.clear();
                        _todayC.clear();
                      }
                      setState(() {
                        _filteredStocks = [];
                        _activeSearchField = null;
                      });
                    },
                    child: const Icon(Icons.close, size: 18, color: AppColors.t2),
                  )
                : null,
          ),
        ),
      ],
    );
  }

  // ─── Suggestion dropdown ──────────────────────────────────────

  Widget _buildSuggestionsList() {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      constraints: const BoxConstraints(maxHeight: 260),
      decoration: BoxDecoration(
        color: AppColors.s3,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border2),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 6)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: ListView.separated(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 6),
          itemCount: _filteredStocks.length,
          separatorBuilder: (_, __) => Divider(height: 1, color: AppColors.border.withOpacity(0.3)),
          itemBuilder: (context, index) {
            final s = _filteredStocks[index];
            final symbol = s['symbol']?.toString() ?? '';
            final name = s['name']?.toString() ?? '';
            final price = (s['price'] ?? s['lastTradedPrice'])?.toString() ?? '-';
            final change = double.tryParse((s['percentageChange'] ?? s['changePercentage'])?.toString() ?? '0') ?? 0;
            final isUp = change >= 0;

            return InkWell(
              onTap: () => _selectStock(s),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    // Leading icon
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.em.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          symbol.isNotEmpty ? symbol[0] : '?',
                          style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.em, fontSize: 15),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Symbol & name
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            symbol.replaceAll('.N0000', ''),
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.text),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11, color: AppColors.t2),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Price & change
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'LKR $price',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppColors.text),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${isUp ? '+' : ''}${change.toStringAsFixed(2)}%',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isUp ? AppColors.em : AppColors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ─── Standard field (non-searchable) ──────────────────────────

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
          border: Border.all(color: isSelected ? activeColor.withOpacity(0.5) : Colors.transparent),
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
    final code = _codeC.text.trim().toUpperCase();
    final name = _nameC.text.trim();
    final qty = double.tryParse(_qtyC.text) ?? 0;
    final price = double.tryParse(_priceC.text) ?? 0;
    final today = double.tryParse(_todayC.text) ?? 0;
    final commissionPercent = double.tryParse(_commissionPercentC.text) ?? 1.12;

    if (code.isEmpty || name.isEmpty || qty <= 0 || price <= 0) return;

    final commissionAmount = (qty * price) * (commissionPercent / 100);

    context.read<PortfolioProvider>().addStock(code, name, _type, qty, price, DateTime.now(), today, commission: commissionAmount);
    Navigator.pop(context);
  }
}
