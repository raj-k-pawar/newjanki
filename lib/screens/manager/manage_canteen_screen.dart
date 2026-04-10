import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../models/models.dart';
import '../../services/storage_service.dart';
import '../../utils/app_theme.dart';
import '../shared/widgets.dart';

class ManageCanteenScreen extends StatefulWidget {
  const ManageCanteenScreen({super.key});
  @override State<ManageCanteenScreen> createState() => _ManageCanteenScreenState();
}
class _ManageCanteenScreenState extends State<ManageCanteenScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  @override void initState() { super.initState(); _tab = TabController(length: 3, vsync: this); }
  @override void dispose() { _tab.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(
      title: const Text('Manage Canteen'),
      leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context)),
      bottom: TabBar(controller: _tab,
        tabs: const [Tab(text: 'Guests Served'), Tab(text: 'Generate Payment'), Tab(text: 'All Transactions')],
        indicatorColor: Colors.white, labelColor: Colors.white,
        unselectedLabelColor: Colors.white60,
        labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 12))),
    body: TabBarView(controller: _tab, children: const [
      _GuestsServedTab(), _GeneratePaymentTab(), _AllTransactionsTab(),
    ]));
}

// ══ Guests Served Tab ════════════════════════════════════════════════════════
class _GuestsServedTab extends StatefulWidget {
  const _GuestsServedTab();
  @override State<_GuestsServedTab> createState() => _GuestsServedTabState();
}
class _GuestsServedTabState extends State<_GuestsServedTab> {
  DateTime _date = DateTime.now();
  List<CustomerModel> _all = [], _filtered = [];
  bool _loading = true;
  String _filter = 'all';

  @override void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    _all = await StorageService.instance.getCustomersByDate(_date);
    _apply();
    setState(() => _loading = false);
  }

  void _apply() {
    setState(() {
      switch (_filter) {
        case 'served':    _filtered = _all.where((c) => c.canteenServed).toList(); break;
        case 'notserved': _filtered = _all.where((c) => !c.canteenServed).toList(); break;
        default:          _filtered = List.from(_all);
      }
    });
  }

  Future<void> _pickDate(BuildContext context) async {
    DateTime sel = _date;
    await showDialog(context: context, builder: (ctx) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(padding: const EdgeInsets.all(14),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TableCalendar(firstDay: DateTime(2020), lastDay: DateTime(2030), focusedDay: sel,
            selectedDayPredicate: (d) => sameDay(d, sel),
            calendarFormat: CalendarFormat.month,
            headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),
            calendarStyle: const CalendarStyle(
              selectedDecoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
              todayDecoration: BoxDecoration(color: Color(0x5552B788), shape: BoxShape.circle)),
            onDaySelected: (s, _) => sel = s),
          ElevatedButton(onPressed: () { _date = sel; Navigator.pop(ctx); _load(); },
            style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 44)),
            child: const Text('Apply')),
        ]))));
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(color: AppColors.primary,
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
        child: Column(children: [
          GestureDetector(onTap: () => _pickDate(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
              child: Row(children: [
                const Icon(Icons.calendar_today, color: AppColors.primary, size: 16),
                const SizedBox(width: 8),
                Text(DateFormat('dd MMMM yyyy').format(_date),
                    style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
                const Spacer(),
                const Icon(Icons.edit_calendar_outlined, color: AppColors.textLight, size: 16),
              ]))),
          const SizedBox(height: 8),
          Row(children: [
            _fc('All', 'all'), const SizedBox(width: 6),
            _fc('Served', 'served'), const SizedBox(width: 6),
            _fc('Not Served', 'notserved'),
          ]),
        ])),
      Container(color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(children: [
          Text('Total: ${_all.length}  ', style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textMedium)),
          Text('Served: ${_all.where((c) => c.canteenServed).length}',
              style: GoogleFonts.poppins(fontSize: 12, color: AppColors.success)),
          Text('  Pending: ${_all.where((c) => !c.canteenServed).length}',
              style: GoogleFonts.poppins(fontSize: 12, color: AppColors.warning)),
        ])),
      Expanded(child: _loading
        ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
        : _filtered.isEmpty
            ? Center(child: Text('No customers', style: GoogleFonts.poppins(color: AppColors.textLight)))
            : RefreshIndicator(onRefresh: _load, color: AppColors.primary,
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 20),
                  itemCount: _filtered.length,
                  itemBuilder: (_, i) => _card(_filtered[i])))),
    ]);
  }

  // Rich card with name, package, guests, food options
  Widget _card(CustomerModel c) {
    final served = c.canteenServed;
    final hasFoods = c.food.breakfast > 0 || c.food.lunch > 0 ||
        c.food.snacks > 0 || c.food.dinner > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 7)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header row
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.06),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(14), topRight: Radius.circular(14))),
          child: Row(children: [
            CircleAvatar(radius: 18,
              backgroundColor: (served ? AppColors.success : AppColors.warning).withOpacity(0.15),
              child: Text(c.name[0].toUpperCase(), style: GoogleFonts.poppins(
                  fontSize: 14, fontWeight: FontWeight.w700,
                  color: served ? AppColors.success : AppColors.warning))),
            const SizedBox(width: 10),
            Expanded(child: Text(c.name, style: GoogleFonts.poppins(
                fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: (served ? AppColors.success : AppColors.warning).withOpacity(0.12),
                borderRadius: BorderRadius.circular(20)),
              child: Text(served ? '✓ Served' : 'Pending', style: GoogleFonts.poppins(
                  fontSize: 11, fontWeight: FontWeight.w700,
                  color: served ? AppColors.success : AppColors.warning))),
          ])),
        Padding(padding: const EdgeInsets.all(12), child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Package
          Text(c.packageName, style: GoogleFonts.poppins(
              fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          // Total guests
          Row(children: [
            const Icon(Icons.groups_outlined, size: 14, color: AppColors.textLight),
            const SizedBox(width: 5),
            Text('Total Guests : ', style: GoogleFonts.poppins(
                fontSize: 12, color: AppColors.textMedium)),
            Text('${c.totalGuests}', style: GoogleFonts.poppins(
                fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark)),
          ]),
          // Food options
          if (hasFoods) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Food Options', style: GoogleFonts.poppins(
                    fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                const SizedBox(height: 6),
                if (c.food.breakfast > 0) _fRow('🍽️ Breakfast', c.food.breakfast),
                if (c.food.lunch > 0)     _fRow('🍛 Lunch',     c.food.lunch),
                if (c.food.snacks > 0)    _fRow('☕ Snacks',    c.food.snacks),
                if (c.food.dinner > 0)    _fRow('🌙 Dinner',    c.food.dinner),
              ])),
          ],
        ])),
      ]));
  }

  Widget _fRow(String label, int count) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(children: [
      Text(label, style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textMedium)),
      const Spacer(),
      Text('$count guests', style: GoogleFonts.poppins(
          fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
    ]));

  Widget _fc(String label, String val) {
    final sel = _filter == val;
    return GestureDetector(onTap: () { _filter = val; _apply(); },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: sel ? Colors.white : Colors.white24, borderRadius: BorderRadius.circular(20)),
        child: Text(label, style: GoogleFonts.poppins(
            fontSize: 11, fontWeight: FontWeight.w600,
            color: sel ? AppColors.primary : Colors.white))));
  }
}

// ══ Generate Payment Tab ═════════════════════════════════════════════════════
class _ThursdayWeek {
  final DateTime start, end;
  final String label;
  _ThursdayWeek(this.start, this.end, this.label);
}

class _GeneratePaymentTab extends StatefulWidget {
  const _GeneratePaymentTab();
  @override State<_GeneratePaymentTab> createState() => _GeneratePaymentTabState();
}

class _GeneratePaymentTabState extends State<_GeneratePaymentTab> {
  List<_ThursdayWeek> _weeks = [];
  int _weekIdx = 0;
  final _snackRateCtrl = TextEditingController(text: '50');
  final _mealRateCtrl  = TextEditingController(text: '100');
  final _extraCtrl     = TextEditingController(text: '0');

  // Computed from selected week
  int _snackGuests = 0; // breakfast + snacks guests
  int _mealGuests  = 0; // lunch + dinner guests
  bool _loading    = false;
  bool _saving     = false;

  @override
  void initState() {
    super.initState();
    _buildWeeks();
    for (final c in [_snackRateCtrl, _mealRateCtrl, _extraCtrl]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override void dispose() {
    _snackRateCtrl.dispose(); _mealRateCtrl.dispose(); _extraCtrl.dispose();
    super.dispose();
  }

  double get _snackRate => double.tryParse(_snackRateCtrl.text) ?? 50;
  double get _mealRate  => double.tryParse(_mealRateCtrl.text) ?? 100;
  double get _extra     => double.tryParse(_extraCtrl.text) ?? 0;
  double get _amtA      => _snackGuests * _snackRate;
  double get _amtB      => _mealGuests  * _mealRate;
  double get _total     => _amtA + _amtB + _extra;

  /// Build Thursday-ending weeks. If today is Thursday, week = prev Thu → today.
  void _buildWeeks() {
    _weeks = _thursdayWeeks();
    // Default to the week containing today
    final today = DateTime.now();
    for (int i = 0; i < _weeks.length; i++) {
      if (!today.isBefore(_weeks[i].start) && !today.isAfter(_weeks[i].end)) {
        _weekIdx = i;
        break;
      }
    }
    _calcStats();
  }

  static List<_ThursdayWeek> _thursdayWeeks() {
    final weeks = <_ThursdayWeek>[];
    final fmt = DateFormat('dd MMM');
    final today = DateTime.now();

    // Go back up to 12 weeks to cover current + past weeks
    // Find the most recent Thursday (inclusive of today if Thursday)
    DateTime thu = DateTime(today.year, today.month, today.day);
    while (thu.weekday != DateTime.thursday) {
      thu = thu.subtract(const Duration(days: 1));
    }

    // Build 8 weeks going back
    for (int w = 0; w < 8; w++) {
      final weekEnd   = thu.subtract(Duration(days: 7 * w));
      final weekStart = weekEnd.subtract(const Duration(days: 6));
      weeks.add(_ThursdayWeek(
        weekStart, weekEnd,
        '${fmt.format(weekStart)} – ${fmt.format(weekEnd)}',
      ));
    }
    return weeks; // newest first
  }

  Future<void> _calcStats() async {
    if (_weeks.isEmpty) return;
    setState(() => _loading = true);
    final w = _weeks[_weekIdx];
    final all = await StorageService.instance.getCustomers();

    int snack = 0, meal = 0;
    for (final c in all) {
      if (!c.canteenServed) continue;
      if (c.visitDate.isBefore(w.start) || c.visitDate.isAfter(w.end)) continue;
      snack += c.food.breakfast + c.food.snacks;
      meal  += c.food.lunch + c.food.dinner;
    }
    setState(() { _snackGuests = snack; _mealGuests = meal; _loading = false; });
  }

  Future<void> _save() async {
    if (_weeks.isEmpty) return;
    setState(() => _saving = true);
    final w = _weeks[_weekIdx];

    // Check if already paid for this week
    final existing = await StorageService.instance.getCanteenTransactions();
    final alreadyPaid = existing.any((t) => t.weekLabel == w.label);
    if (alreadyPaid) {
      setState(() => _saving = false);
      if (mounted) showSnack(context, 'Payment already saved for this week!', error: true);
      return;
    }

    await StorageService.instance.addCanteenTransaction(CanteenTransaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      month: w.end.month, year: w.end.year,
      weekNumber: _weekIdx + 1, weekLabel: w.label,
      totalCustomers: _snackGuests + _mealGuests,
      amountPaid: _total, paidDate: DateTime.now(),
      snackGuests: _snackGuests, mealGuests: _mealGuests,
      snackRate: _snackRate, mealRate: _mealRate, extraAmount: _extra,
    ));
    setState(() => _saving = false);
    if (mounted) showSnack(context, 'Payment saved successfully!');
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Week selector
        const SectionHeader('Select Week', icon: Icons.date_range_outlined),
        WhiteCard(child: Column(children: [
          if (_weeks.isNotEmpty)
            DropdownButtonFormField<int>(
              value: _weekIdx,
              items: List.generate(_weeks.length, (i) => DropdownMenuItem(
                value: i,
                child: Text('Week ${i+1}: ${_weeks[i].label}',
                    style: GoogleFonts.poppins(fontSize: 12)))),
              onChanged: (v) { if (v != null) { setState(() => _weekIdx = v); _calcStats(); } },
              decoration: const InputDecoration(labelText: 'Thursday-based Week')),
          const SizedBox(height: 6),
          Row(children: [
            const Icon(Icons.info_outline, size: 13, color: AppColors.textLight),
            const SizedBox(width: 5),
            Expanded(child: Text('Weeks end on Thursday. Today\'s week is pre-selected.',
                style: GoogleFonts.poppins(fontSize: 10, color: AppColors.textLight))),
          ]),
        ])),

        // Rate inputs
        const SectionHeader('Rate Per Plate', icon: Icons.local_dining_outlined),
        WhiteCard(child: Column(children: [
          Row(children: [
            Expanded(child: TextFormField(
              controller: _snackRateCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
              decoration: const InputDecoration(
                labelText: 'Breakfast / Snacks rate (Rs.)',
                prefixIcon: Icon(Icons.currency_rupee, color: AppColors.primary, size: 18)))),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: TextFormField(
              controller: _mealRateCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
              decoration: const InputDecoration(
                labelText: 'Lunch / Dinner rate (Rs.)',
                prefixIcon: Icon(Icons.currency_rupee, color: AppColors.primary, size: 18)))),
          ]),
        ])),

        // Payment Summary
        const SectionHeader('Payment Summary', icon: Icons.summarize_outlined),
        if (_loading)
          const Center(child: CircularProgressIndicator(color: AppColors.primary))
        else
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1B4332), Color(0xFF2D6A4F)],
                begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.35),
                  blurRadius: 12, offset: const Offset(0, 6))]),
            child: Column(children: [
              // Selected week
              Padding(padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
                child: Row(children: [
                  const Icon(Icons.calendar_month, color: Colors.white70, size: 16),
                  const SizedBox(width: 8),
                  Text('Selected Week',
                      style: GoogleFonts.poppins(fontSize: 11, color: Colors.white70)),
                  const Spacer(),
                  Text(_weeks.isNotEmpty ? _weeks[_weekIdx].label : '–',
                      style: GoogleFonts.poppins(fontSize: 12,
                          fontWeight: FontWeight.w600, color: Colors.white)),
                ])),
              const Padding(padding: EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                child: Divider(color: Colors.white24)),
              // Guests
              Padding(padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Column(children: [
                  _sRow('Breakfast / Snacks guests', '$_snackGuests guests'),
                  const SizedBox(height: 6),
                  _sRow('Lunch / Dinner guests', '$_mealGuests guests'),
                ])),
              const Padding(padding: EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                child: Divider(color: Colors.white24)),
              // Calculation
              Padding(padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Column(children: [
                  _calcRow('A', 'Breakfast/Snacks',
                      '$_snackGuests × Rs.${_snackRate.toStringAsFixed(0)}', _amtA),
                  const SizedBox(height: 6),
                  _calcRow('B', 'Lunch/Dinner',
                      '$_mealGuests × Rs.${_mealRate.toStringAsFixed(0)}', _amtB),
                ])),
              const Padding(padding: EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                child: Divider(color: Colors.white24)),
              // Sub total + extra
              Padding(padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Column(children: [
                  _sRow('Sub Total (A + B)', 'Rs.${(_amtA + _amtB).toStringAsFixed(0)}'),
                  const SizedBox(height: 8),
                  // Additional amount input inline
                  Row(children: [
                    Text('Additional Amount', style: GoogleFonts.poppins(
                        fontSize: 13, color: Colors.white70)),
                    const Spacer(),
                    SizedBox(width: 110, child: TextFormField(
                      controller: _extraCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
                      textAlign: TextAlign.right,
                      style: GoogleFonts.poppins(fontSize: 13,
                          fontWeight: FontWeight.w600, color: Colors.white),
                      decoration: InputDecoration(
                        hintText: '0',
                        hintStyle: GoogleFonts.poppins(color: Colors.white38),
                        prefixText: 'Rs. ',
                        prefixStyle: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
                        enabledBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.white38)),
                        focusedBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.white)),
                        isDense: true, contentPadding: EdgeInsets.zero),
                    )),
                  ]),
                ])),
              const Padding(padding: EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                child: Divider(color: Colors.white24)),
              // Total
              Padding(padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('Total to Pay', style: GoogleFonts.poppins(
                      fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white70)),
                  Text('Rs.${_total.toStringAsFixed(0)}', style: GoogleFonts.poppins(
                      fontSize: 28, fontWeight: FontWeight.w700, color: Colors.white)),
                ])),
            ])),

        const SizedBox(height: 20),
        SizedBox(width: double.infinity, height: 50,
          child: ElevatedButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
              ? const SizedBox(width: 18, height: 18,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Icon(Icons.save_outlined, color: Colors.white),
            label: Text('Save Payment', style: GoogleFonts.poppins(
                fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)))),
        const SizedBox(height: 30),
      ]),
    );
  }

  Widget _sRow(String l, String v) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
    Text(l, style: GoogleFonts.poppins(fontSize: 13, color: Colors.white70)),
    Text(v, style: GoogleFonts.poppins(fontSize: 13,
        fontWeight: FontWeight.w600, color: Colors.white)),
  ]);

  Widget _calcRow(String tag, String label, String formula, double amt) => Row(children: [
    Container(width: 22, height: 22,
      decoration: BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
      child: Center(child: Text(tag, style: GoogleFonts.poppins(
          fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)))),
    const SizedBox(width: 8),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: GoogleFonts.poppins(fontSize: 11, color: Colors.white70)),
      Text(formula, style: GoogleFonts.poppins(fontSize: 10, color: Colors.white54)),
    ])),
    Text('Rs.${amt.toStringAsFixed(0)}', style: GoogleFonts.poppins(
        fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
  ]);
}

// ══ All Transactions Tab ═════════════════════════════════════════════════════
class _AllTransactionsTab extends StatefulWidget {
  const _AllTransactionsTab();
  @override State<_AllTransactionsTab> createState() => _AllTransactionsTabState();
}
class _AllTransactionsTabState extends State<_AllTransactionsTab> {
  List<CanteenTransaction> _txns = [];
  bool _loading = true;

  @override void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    _txns = await StorageService.instance.getCanteenTransactions();
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return _loading
      ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
      : _txns.isEmpty
          ? Center(child: Text('No transactions yet',
              style: GoogleFonts.poppins(color: AppColors.textLight)))
          : RefreshIndicator(onRefresh: _load, color: AppColors.primary,
              child: ListView.builder(
                padding: const EdgeInsets.all(14),
                itemCount: _txns.length,
                itemBuilder: (_, i) {
                  final t = _txns[i];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05),
                            blurRadius: 7, offset: const Offset(0, 3))]),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      // Week header
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: const BoxDecoration(
                          color: Color(0xFFEBF5EE),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(14), topRight: Radius.circular(14))),
                        child: Row(children: [
                          const Icon(Icons.calendar_month, color: AppColors.primary, size: 16),
                          const SizedBox(width: 8),
                          Expanded(child: Text(t.weekLabel,
                              style: GoogleFonts.poppins(fontSize: 13,
                                  fontWeight: FontWeight.w700, color: AppColors.textDark))),
                          Text('Rs.${t.amountPaid.toStringAsFixed(0)}',
                              style: GoogleFonts.poppins(fontSize: 15,
                                  fontWeight: FontWeight.w700, color: AppColors.primary)),
                        ])),
                      Padding(padding: const EdgeInsets.all(12),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        // Guest breakdown
                        Row(children: [
                          Expanded(child: _txnBox('🍽️ Breakfast\n+ Snacks',
                              t.snackGuests, const Color(0xFFF4A261))),
                          const SizedBox(width: 10),
                          Expanded(child: _txnBox('🍛 Lunch\n+ Dinner',
                              t.mealGuests, AppColors.primary)),
                        ]),
                        const SizedBox(height: 10),
                        // Rate info
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade200)),
                          child: Column(children: [
                            _txnRow('Snack/Breakfast Rate', 'Rs.${t.snackRate.toStringAsFixed(0)}/guest'),
                            _txnRow('Meal Rate', 'Rs.${t.mealRate.toStringAsFixed(0)}/guest'),
                            if (t.extraAmount > 0)
                              _txnRow('Additional', 'Rs.${t.extraAmount.toStringAsFixed(0)}'),
                            const Divider(height: 10),
                            _txnRow('Total Paid', 'Rs.${t.amountPaid.toStringAsFixed(0)}', bold: true),
                          ])),
                        const SizedBox(height: 6),
                        Text('Paid on ${DateFormat('dd MMM yyyy').format(t.paidDate)}',
                            style: GoogleFonts.poppins(
                                fontSize: 10, color: AppColors.textLight)),
                      ])),
                    ]));
                }));
  }

  Widget _txnBox(String label, int count, Color color) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: GoogleFonts.poppins(fontSize: 11, color: color)),
      const SizedBox(height: 4),
      Text('$count guests', style: GoogleFonts.poppins(
          fontSize: 16, fontWeight: FontWeight.w700, color: color)),
    ]));

  Widget _txnRow(String l, String v, {bool bold = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(l, style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textLight)),
      Text(v, style: GoogleFonts.poppins(fontSize: 12,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
          color: bold ? AppColors.primary : AppColors.textDark)),
    ]));
}
