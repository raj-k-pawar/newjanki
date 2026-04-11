import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/models.dart';
import '../../services/storage_service.dart';
import '../../utils/app_theme.dart';
import '../shared/widgets.dart';

class ManageAccountScreen extends StatefulWidget {
  const ManageAccountScreen({super.key});
  @override State<ManageAccountScreen> createState() => _ManageAccountScreenState();
}
class _ManageAccountScreenState extends State<ManageAccountScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  @override void initState() { super.initState(); _tab = TabController(length: 2, vsync: this); }
  @override void dispose() { _tab.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(
      title: const Text('Manage Account'),
      leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context)),
      bottom: TabBar(controller: _tab,
        tabs: const [Tab(text: 'Tax Limit'), Tab(text: 'Generate Report')],
        indicatorColor: Colors.white, labelColor: Colors.white,
        unselectedLabelColor: Colors.white60,
        labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13)),
    ),
    body: TabBarView(controller: _tab, children: const [
      _TaxLimitTab(), _GenerateReportTab(),
    ]),
  );
}

// ══════════════════════════════════════════════════════════════════════════════
// TAB 1 – Tax Limit
// ══════════════════════════════════════════════════════════════════════════════
class _TaxLimitTab extends StatefulWidget {
  const _TaxLimitTab();
  @override State<_TaxLimitTab> createState() => _TaxLimitTabState();
}
class _TaxLimitTabState extends State<_TaxLimitTab> {
  String _taxYear = _currentTaxYear();
  final _amtCtrl = TextEditingController();
  bool _saving = false, _loading = true;

  static String _currentTaxYear() {
    final now = DateTime.now();
    final startYear = now.month >= 4 ? now.year : now.year - 1;
    return '$startYear-${(startYear + 1).toString().substring(2)}';
  }

  static List<String> _taxYears() {
    final years = <String>[];
    final now = DateTime.now();
    final cur = now.month >= 4 ? now.year : now.year - 1;
    for (int y = cur - 3; y <= cur + 2; y++) {
      years.add('$y-${(y + 1).toString().substring(2)}');
    }
    return years;
  }

  @override
  void initState() { super.initState(); _load(); }
  @override void dispose() { _amtCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    final data = await StorageService.instance.getTaxSettings();
    setState(() {
      _taxYear = data['taxYear'] ?? _currentTaxYear();
      _amtCtrl.text = (data['taxableAmount'] ?? '').toString();
      _loading = false;
    });
  }

  Future<void> _save() async {
    if (_amtCtrl.text.trim().isEmpty) {
      showSnack(context, 'Please enter taxable amount', error: true); return;
    }
    setState(() => _saving = true);
    await StorageService.instance.saveTaxSettings({
      'taxYear': _taxYear,
      'taxableAmount': double.tryParse(_amtCtrl.text) ?? 0,
    });
    setState(() => _saving = false);
    if (mounted) showSnack(context, 'Tax settings saved!');
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Info card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.07),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary.withOpacity(0.2))),
          child: Row(children: [
            const Icon(Icons.info_outline, color: AppColors.primary, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(
              'Set the taxable income limit for a tax year. '
              'When generating a report, bookings will be included '
              'until the total reaches this limit (online payments first).',
              style: GoogleFonts.poppins(fontSize: 12, color: AppColors.primary))),
          ])),
        const SizedBox(height: 20),
        const SectionHeader('Tax Year', icon: Icons.calendar_today_outlined),
        WhiteCard(child: DropdownButtonFormField<String>(
          value: _taxYear,
          items: _taxYears().map((y) => DropdownMenuItem(
              value: y,
              child: Text('FY $y  (Apr ${y.split('-')[0]} – Mar 20${y.split('-')[1]})',
                  style: GoogleFonts.poppins(fontSize: 13)))).toList(),
          onChanged: (v) { if (v != null) setState(() => _taxYear = v); },
          decoration: const InputDecoration(
            labelText: 'Select Financial Year',
            prefixIcon: Icon(Icons.event_note_outlined, color: AppColors.primary, size: 20)),
        )),
        const SectionHeader('Taxable Amount', icon: Icons.currency_rupee),
        WhiteCard(child: TextFormField(
          controller: _amtCtrl,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
          decoration: const InputDecoration(
            labelText: 'Taxable Amount (Rs.)',
            prefixIcon: Icon(Icons.currency_rupee, color: AppColors.primary, size: 20),
            hintText: 'e.g. 300000'),
        )),
        const SizedBox(height: 24),
        PrimaryButton(
          label: 'Save Tax Settings',
          icon: Icons.save_outlined,
          loading: _saving,
          onTap: _save,
        ),
        const SizedBox(height: 30),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// TAB 2 – Generate Report
// ══════════════════════════════════════════════════════════════════════════════
class _ReportRow {
  final String name, phone, city, bookingDate, paymentType;
  final int totalGuests;
  final double amount;
  _ReportRow({required this.name, required this.phone, required this.city,
      required this.bookingDate, required this.totalGuests,
      required this.amount, required this.paymentType});
}

class _GenerateReportTab extends StatefulWidget {
  const _GenerateReportTab();
  @override State<_GenerateReportTab> createState() => _GenerateReportTabState();
}
class _GenerateReportTabState extends State<_GenerateReportTab> {
  String _taxYear = _TaxLimitTabState._currentTaxYear();
  double _taxableAmount = 0;
  List<_ReportRow> _rows = [];
  bool _generating = false, _generated = false, _downloading = false;
  double _totalOnline = 0, _totalCash = 0, _grandTotal = 0;

  static List<String> _taxYears() => _TaxLimitTabState._taxYears();

  @override
  void initState() { super.initState(); _loadSettings(); }

  Future<void> _loadSettings() async {
    final data = await StorageService.instance.getTaxSettings();
    setState(() {
      if (data['taxYear'] != null) _taxYear = data['taxYear'];
      _taxableAmount = (data['taxableAmount'] ?? 0).toDouble();
    });
  }

  Future<void> _generate() async {
    setState(() { _generating = true; _generated = false; _rows = []; });

    final all = await StorageService.instance.getCustomersByTaxYear(_taxYear);

    // Separate online and cash
    final online = all.where((c) => c.paymentMode == PaymentMode.online).toList();
    final cash   = all.where((c) => c.paymentMode == PaymentMode.cash).toList();

    // Sort by date ascending
    online.sort((a, b) => a.visitDate.compareTo(b.visitDate));
    cash.sort((a, b) => a.visitDate.compareTo(b.visitDate));

    final fmt = DateFormat('dd MMM yyyy');
    final result = <_ReportRow>[];
    double running = 0;
    final limit = _taxableAmount;

    // Priority 1: Online customers — include whole booking only if it fits within limit
    for (final c in online) {
      if (limit > 0 && running >= limit) break;
      // If no limit set, include all. Otherwise include only if full amount fits.
      if (limit > 0 && running + c.totalAmount > limit) continue; // skip, doesn't fit
      running += c.totalAmount;
      result.add(_ReportRow(
        name: c.name, phone: c.phone, city: c.city,
        bookingDate: fmt.format(c.visitDate),
        totalGuests: c.totalGuests,
        amount: c.totalAmount,
        paymentType: 'Online',
      ));
    }

    // Priority 2: Cash customers — continue until limit reached (whole bookings only)
    for (final c in cash) {
      if (limit > 0 && running >= limit) break;
      if (limit > 0 && running + c.totalAmount > limit) continue; // skip, doesn't fit
      running += c.totalAmount;
      result.add(_ReportRow(
        name: c.name, phone: c.phone, city: c.city,
        bookingDate: fmt.format(c.visitDate),
        totalGuests: c.totalGuests,
        amount: c.totalAmount,
        paymentType: 'Cash',
      ));
    }

    // Sort final result by date
    result.sort((a, b) => a.bookingDate.compareTo(b.bookingDate));

    final onlineTotal = result.where((r) => r.paymentType == 'Online')
        .fold(0.0, (s, r) => s + r.amount);
    final cashTotal = result.where((r) => r.paymentType == 'Cash')
        .fold(0.0, (s, r) => s + r.amount);

    setState(() {
      _rows = result;
      _totalOnline = onlineTotal;
      _totalCash   = cashTotal;
      _grandTotal  = running;
      _generating  = false;
      _generated   = true;
    });
  }

  Future<void> _download() async {
    if (_rows.isEmpty) return;
    setState(() => _downloading = true);

    try {
      // Build CSV content
      final sb = StringBuffer();
      // Header
      sb.writeln('Janki Agro Tourism - Tax Report');
      sb.writeln('Financial Year: FY $_taxYear');
      sb.writeln('Taxable Limit: Rs.${_taxableAmount.toStringAsFixed(0)}');
      sb.writeln('Generated: ${DateFormat('dd MMM yyyy HH:mm').format(DateTime.now())}');
      sb.writeln('');
      // Column headers
      sb.writeln('Sr No,Customer Name,Mobile No,City,Booking Date,Total Guests,Amount Paid (Rs.),Payment Type');
      // Data rows
      for (int i = 0; i < _rows.length; i++) {
        final r = _rows[i];
        // Escape commas in fields
        String esc(String s) => s.contains(',') ? '"$s"' : s;
        sb.writeln('${i + 1},${esc(r.name)},${esc(r.phone)},${esc(r.city)},${r.bookingDate},${r.totalGuests},${r.amount.toStringAsFixed(0)},${r.paymentType}');
      }
      // Totals
      sb.writeln('');
      sb.writeln(',,,,,,Online Total,Rs.${_totalOnline.toStringAsFixed(0)}');
      sb.writeln(',,,,,,Cash Total,Rs.${_totalCash.toStringAsFixed(0)}');
      sb.writeln(',,,,,,Grand Total,Rs.${_grandTotal.toStringAsFixed(0)}');

      // Write to temp file
      final dir  = await getTemporaryDirectory();
      final fileName = 'JAT_TaxReport_${_taxYear.replaceAll('-', '_')}.csv';
      final file = File('${dir.path}/$fileName');
      await file.writeAsString(sb.toString());

      // Share / download
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'text/csv')],
        subject: 'Janki Agro Tourism – Tax Report FY $_taxYear',
      );
    } catch (e) {
      if (mounted) showSnack(context, 'Download failed: $e', error: true);
    }
    setState(() => _downloading = false);
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##,###', 'en_IN');
    return Column(children: [
      // Controls
      Container(
        color: Colors.white,
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Tax year selector + taxable amount display
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Expanded(child: DropdownButtonFormField<String>(
              value: _taxYear,
              items: _taxYears().map((y) => DropdownMenuItem(
                  value: y,
                  child: Text('FY $y', style: GoogleFonts.poppins(fontSize: 13)))).toList(),
              onChanged: (v) { if (v != null) setState(() => _taxYear = v); },
              decoration: const InputDecoration(
                labelText: 'Select Tax Year',
                prefixIcon: Icon(Icons.calendar_today_outlined,
                    color: AppColors.primary, size: 18)),
            )),
          ]),
          if (_taxableAmount > 0) ...[
            const SizedBox(height: 8),
            Row(children: [
              const Icon(Icons.currency_rupee, size: 13, color: AppColors.textLight),
              const SizedBox(width: 4),
              Text('Taxable limit: Rs.${fmt.format(_taxableAmount)}',
                  style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textMedium)),
              const SizedBox(width: 6),
              Text('(Online first, then Cash)',
                  style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textLight)),
            ]),
          ] else
            Text('⚠️  No tax limit set. Go to Tax Limit tab to configure.',
                style: GoogleFonts.poppins(fontSize: 12, color: AppColors.warning)),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity, height: 46,
            child: ElevatedButton.icon(
              onPressed: _generating ? null : _generate,
              icon: _generating
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.bar_chart_outlined, color: Colors.white),
              label: Text('Generate Report', style: GoogleFonts.poppins(
                  fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)))),
        ]),
      ),

      // Summary cards (shown after generation)
      if (_generated) ...[
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          color: AppColors.background,
          child: Row(children: [
            Expanded(child: _summaryCard('Online', _totalOnline, const Color(0xFF4361EE))),
            const SizedBox(width: 8),
            Expanded(child: _summaryCard('Cash', _totalCash, const Color(0xFFF4A261))),
            const SizedBox(width: 8),
            Expanded(child: _summaryCard('Total', _grandTotal, AppColors.primary)),
          ])),
      ],

      // Grid header
      if (_generated) ...[
        Container(
          color: AppColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(children: [
            Expanded(child: Text('${_rows.length} customers  •  FY $_taxYear',
                style: GoogleFonts.poppins(fontSize: 12,
                    fontWeight: FontWeight.w600, color: Colors.white))),
            if (_rows.isNotEmpty)
              GestureDetector(
                onTap: _downloading ? null : _download,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8)),
                  child: Row(children: [
                    _downloading
                        ? const SizedBox(width: 14, height: 14,
                            child: CircularProgressIndicator(
                                color: AppColors.primary, strokeWidth: 2))
                        : const Icon(Icons.download_outlined,
                            color: AppColors.primary, size: 16),
                    const SizedBox(width: 5),
                    Text(_downloading ? 'Saving...' : 'Download CSV',
                        style: GoogleFonts.poppins(fontSize: 12,
                            fontWeight: FontWeight.w700, color: AppColors.primary)),
                  ])),
              ),
          ])),
      ],

      // Data grid
      if (_generated)
        Expanded(child: _rows.isEmpty
          ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.inbox_outlined, size: 56, color: Colors.grey.shade300),
              const SizedBox(height: 10),
              Text('No bookings found for FY $_taxYear',
                  style: GoogleFonts.poppins(color: AppColors.textLight)),
            ]))
          : SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(12),
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(AppColors.primary.withOpacity(0.08)),
                  border: TableBorder.all(color: Colors.grey.shade200, width: 0.5),
                  columnSpacing: 18,
                  headingRowHeight: 40,
                  dataRowMinHeight: 44,
                  dataRowMaxHeight: 52,
                  columns: [
                    _col('Sr'), _col('Name'), _col('Mobile'),
                    _col('City'), _col('Date'), _col('Guests'),
                    _col('Amount (Rs.)'), _col('Type'),
                  ],
                  rows: List.generate(_rows.length, (i) {
                    final r = _rows[i];
                    final isOnline = r.paymentType == 'Online';
                    return DataRow(cells: [
                      _cell('${i + 1}'),
                      _cell(r.name, bold: true),
                      _cell(r.phone),
                      _cell(r.city),
                      _cell(r.bookingDate),
                      _cell('${r.totalGuests}'),
                      _cell(fmt.format(r.amount), bold: true,
                          color: AppColors.primary),
                      DataCell(Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: (isOnline
                              ? const Color(0xFF4361EE)
                              : const Color(0xFFF4A261)).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12)),
                        child: Text(r.paymentType,
                            style: GoogleFonts.poppins(fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isOnline
                                    ? const Color(0xFF4361EE)
                                    : const Color(0xFFB86B00))))),
                    ]);
                  }),
                ),
              ),
            ),
        ),

      if (!_generated)
        Expanded(child: Center(child: Column(
          mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.assessment_outlined, size: 70, color: Colors.grey.shade300),
          const SizedBox(height: 14),
          Text('Select a tax year and click', style: GoogleFonts.poppins(
              fontSize: 14, color: AppColors.textLight)),
          Text('Generate Report', style: GoogleFonts.poppins(
              fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.primary)),
        ]))),
    ]);
  }

  DataColumn _col(String label) => DataColumn(
    label: Text(label, style: GoogleFonts.poppins(
        fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textDark)));

  DataCell _cell(String text, {bool bold = false, Color? color}) => DataCell(
    Text(text, style: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
        color: color ?? AppColors.textDark)));

  Widget _summaryCard(String label, double amount, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(
      gradient: LinearGradient(colors: [color, color.withOpacity(0.75)],
          begin: Alignment.topLeft, end: Alignment.bottomRight),
      borderRadius: BorderRadius.circular(10),
      boxShadow: [BoxShadow(color: color.withOpacity(0.25),
          blurRadius: 6, offset: const Offset(0, 3))]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: GoogleFonts.poppins(fontSize: 10, color: Colors.white70)),
      Text('Rs.${NumberFormat('#,##,###', 'en_IN').format(amount)}',
          style: GoogleFonts.poppins(fontSize: 13,
              fontWeight: FontWeight.w700, color: Colors.white)),
    ]));
}
