import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../models/models.dart';
import '../../services/storage_service.dart';
import '../../utils/app_theme.dart';
import '../shared/widgets.dart';

class ManageWorkersScreen extends StatefulWidget {
  final bool ownerMode;
  const ManageWorkersScreen({super.key, this.ownerMode = false});
  @override
  State<ManageWorkersScreen> createState() => _ManageWorkersScreenState();
}

class _ManageWorkersScreenState extends State<ManageWorkersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  List<WorkerModel>    _workers  = [];
  List<AdvancePayment> _advances = [];
  List<SalaryPayment>  _salaries = [];
  bool _loading = true;
  DateTime _attDate = DateTime.now();
  Map<String, String> _attStatus = {}; // workerId -> "present"|"absent"|"halfday"

  @override
  void initState() {
    super.initState();
    // Owner: Add Worker, Workers List, Advance, Salary, Monthly Attendance (5 tabs)
    // Manager: Attendance only (1 tab)
    final count = widget.ownerMode ? 5 : 1;
    _tab = TabController(length: count, vsync: this);
    _load();
  }

  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    _workers  = await StorageService.instance.getWorkers();
    _advances = await StorageService.instance.getAdvances();
    _salaries = await StorageService.instance.getSalaries();
    final att = <String, String>{};
    for (final w in _workers) {
      att[w.id] = await StorageService.instance
          .getWorkerAttendanceStatus(w.id, _attDate);
    }
    setState(() { _attStatus = att; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final tabs = widget.ownerMode
        ? const [
            Tab(text: 'Add Worker'),
            Tab(text: 'Workers'),
            Tab(text: 'Attendance'),
            Tab(text: 'Advance'),
            Tab(text: 'Salary'),
          ]
        : const [Tab(text: 'Attendance')];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Manage Workers'),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 18),
            onPressed: () => Navigator.pop(context)),
        bottom: TabBar(
          controller: _tab, tabs: tabs,
          isScrollable: true,
          indicatorColor: Colors.white, labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : TabBarView(
              controller: _tab,
              children: widget.ownerMode
                  ? [
                      _AddWorkerTab(onSaved: _load),
                      _WorkersListTab(workers: _workers, onChanged: _load),
                      _AttendanceTab(
                          workers: _workers, attStatus: _attStatus,
                          attDate: _attDate,
                          onDateChanged: (d) { _attDate = d; _load(); },
                          onAttChanged: (wId, status) async {
                            await StorageService.instance
                                .setAttendance(wId, _attDate, status);
                            setState(() => _attStatus[wId] = status);
                          }),
                      _AdvanceTab(workers: _workers, advances: _advances, onSaved: _load),
                      _SalaryTab(workers: _workers, advances: _advances,
                          salaries: _salaries, onSaved: _load),
                    ]
                  : [
                      _AttendanceTab(
                          workers: _workers, attStatus: _attStatus,
                          attDate: _attDate,
                          onDateChanged: (d) { _attDate = d; _load(); },
                          onAttChanged: (wId, status) async {
                            await StorageService.instance
                                .setAttendance(wId, _attDate, status);
                            setState(() => _attStatus[wId] = status);
                          }),
                    ],
            ),
    );
  }
}

// ══ Add Worker Tab ═════════════════════════════════════════════════════════
class _AddWorkerTab extends StatefulWidget {
  final VoidCallback onSaved;
  const _AddWorkerTab({required this.onSaved});
  @override State<_AddWorkerTab> createState() => _AddWorkerTabState();
}
class _AddWorkerTabState extends State<_AddWorkerTab> {
  final _fk   = GlobalKey<FormState>();
  final _nameC = TextEditingController();
  final _phC   = TextEditingController();
  final _cityC = TextEditingController();
  final _roleC = TextEditingController();
  final _payC  = TextEditingController();
  bool _saving = false;

  @override void dispose() {
    _nameC.dispose(); _phC.dispose(); _cityC.dispose(); _roleC.dispose(); _payC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(key: _fk, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SectionHeader('Add New Worker', icon: Icons.person_add_outlined),
        WhiteCard(child: Column(children: [
          _wf(_nameC, 'Full Name', Icons.person_outline, req: true),
          const SizedBox(height: 12),
          _wf(_phC, 'Mobile Number', Icons.phone_outlined,
              type: TextInputType.phone, req: true),
          const SizedBox(height: 12),
          _wf(_cityC, 'City', Icons.location_city_outlined),
          const SizedBox(height: 12),
          _wf(_roleC, 'Role / Designation', Icons.work_outline, req: true),
          const SizedBox(height: 12),
          TextFormField(
            controller: _payC,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: 'Pay Per Day (Rs.)',
              prefixIcon: Icon(Icons.currency_rupee, color: AppColors.primary, size: 20)),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null),
          const SizedBox(height: 20),
          SizedBox(width: double.infinity, height: 50,
            child: ElevatedButton.icon(
              onPressed: _saving ? null : () async {
                if (!_fk.currentState!.validate()) return;
                setState(() => _saving = true);
                await StorageService.instance.saveWorker(WorkerModel(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: _nameC.text.trim(), phone: _phC.text.trim(),
                  city: _cityC.text.trim(), role: _roleC.text.trim(),
                  payPerDay: double.tryParse(_payC.text) ?? 0,
                  joiningDate: DateTime.now(),
                ));
                _nameC.clear(); _phC.clear(); _cityC.clear(); _roleC.clear(); _payC.clear();
                setState(() => _saving = false);
                widget.onSaved();
                if (mounted) showSnack(context, 'Worker added!');
              },
              icon: const Icon(Icons.save_outlined, color: Colors.white),
              label: Text('Save Worker', style: GoogleFonts.poppins(
                  fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)))),
        ])),
      ])),
    );
  }

  Widget _wf(TextEditingController c, String label, IconData icon,
      {TextInputType? type, bool req = false}) =>
    TextFormField(controller: c, keyboardType: type,
      decoration: InputDecoration(labelText: label,
          prefixIcon: Icon(icon, color: AppColors.primary, size: 20)),
      validator: req ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null : null);
}

// ══ Workers List Tab ═══════════════════════════════════════════════════════
class _WorkersListTab extends StatelessWidget {
  final List<WorkerModel> workers;
  final VoidCallback onChanged;
  const _WorkersListTab({required this.workers, required this.onChanged});

  void _edit(BuildContext context, WorkerModel w) {
    final nameC = TextEditingController(text: w.name);
    final phC   = TextEditingController(text: w.phone);
    final cityC = TextEditingController(text: w.city);
    final roleC = TextEditingController(text: w.role);
    final payC  = TextEditingController(text: w.payPerDay.toStringAsFixed(0));

    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('Edit Worker', style: GoogleFonts.poppins(
                fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            TextField(controller: nameC,
                decoration: const InputDecoration(labelText: 'Full Name')),
            const SizedBox(height: 10),
            TextField(controller: phC, keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Mobile Number')),
            const SizedBox(height: 10),
            TextField(controller: cityC,
                decoration: const InputDecoration(labelText: 'City')),
            const SizedBox(height: 10),
            TextField(controller: roleC,
                decoration: const InputDecoration(labelText: 'Role')),
            const SizedBox(height: 10),
            TextField(controller: payC, keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Pay Per Day (Rs.)')),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await StorageService.instance.saveWorker(WorkerModel(
                  id: w.id,
                  name: nameC.text.trim(), phone: phC.text.trim(),
                  city: cityC.text.trim(), role: roleC.text.trim(),
                  payPerDay: double.tryParse(payC.text) ?? w.payPerDay,
                  joiningDate: w.joiningDate,
                ));
                if (ctx.mounted) Navigator.pop(ctx);
                onChanged();
              },
              style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 46)),
              child: const Text('Update Worker')),
            const SizedBox(height: 10),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (workers.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.badge_outlined, size: 60, color: Colors.grey.shade300),
        const SizedBox(height: 12),
        Text('No workers yet', style: GoogleFonts.poppins(color: AppColors.textLight)),
        Text('Add workers from the "Add Worker" tab',
            style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textLight)),
      ]));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(14),
      itemCount: workers.length,
      itemBuilder: (_, i) {
        final w = workers[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6)]),
          child: Row(children: [
            CircleAvatar(radius: 22,
              backgroundColor: AppColors.primary.withOpacity(0.12),
              child: Text(w.name[0].toUpperCase(), style: GoogleFonts.poppins(
                  fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.primary))),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(w.name, style: GoogleFonts.poppins(
                  fontSize: 13, fontWeight: FontWeight.w700)),
              Text('${w.phone}  •  ${w.city}',
                  style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textLight)),
              const SizedBox(height: 3),
              Row(children: [
                _chip(w.role, AppColors.primary),
                const SizedBox(width: 6),
                _chip('Rs.${w.payPerDay.toStringAsFixed(0)}/day', const Color(0xFFB88B1A),
                    bg: const Color(0xFFFAEEDA)),
              ]),
            ])),
            Column(children: [
              IconButton(icon: const Icon(Icons.edit_outlined,
                  color: AppColors.cardBlue, size: 20),
                padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                onPressed: () => _edit(context, w)),
              const SizedBox(height: 4),
              IconButton(icon: const Icon(Icons.delete_outline,
                  color: AppColors.error, size: 20),
                padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                onPressed: () async {
                  await StorageService.instance.deleteWorker(w.id);
                  onChanged();
                }),
            ]),
          ]));
      });
  }

  Widget _chip(String t, Color color, {Color? bg}) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(color: bg ?? color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6)),
    child: Text(t, style: GoogleFonts.poppins(
        fontSize: 10, color: color, fontWeight: FontWeight.w600)));
}

// ══ Attendance Tab ══════════════════════════════════════════════════════════
class _AttendanceTab extends StatelessWidget {
  final List<WorkerModel> workers;
  final Map<String, String> attStatus;
  final DateTime attDate;
  final void Function(DateTime) onDateChanged;
  final void Function(String workerId, String status) onAttChanged;

  const _AttendanceTab({
    required this.workers, required this.attStatus,
    required this.attDate, required this.onDateChanged,
    required this.onAttChanged,
  });

  Future<void> _pickDate(BuildContext context) async {
    DateTime sel = attDate;
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
          ElevatedButton(
            onPressed: () { Navigator.pop(ctx); onDateChanged(sel); },
            style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 44)),
            child: const Text('Apply')),
        ]))));
  }

  @override
  Widget build(BuildContext context) {
    final present  = attStatus.values.where((s) => s == 'present').length;
    final halfday  = attStatus.values.where((s) => s == 'halfday').length;
    final absent   = attStatus.values.where((s) => s == 'absent').length;

    return Column(children: [
      Container(margin: const EdgeInsets.all(14), padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [AppColors.primaryDark, AppColors.primary],
              begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(14)),
        child: Column(children: [
          Row(children: [
            const Icon(Icons.calendar_today, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Text(DateFormat('dd MMMM yyyy').format(attDate),
                style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
            const Spacer(),
            GestureDetector(
              onTap: () => _pickDate(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.white24,
                    borderRadius: BorderRadius.circular(8)),
                child: Text('Change', style: GoogleFonts.poppins(
                    color: Colors.white, fontSize: 11)))),
          ]),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _stat('Total',   '${workers.length}'),
            _stat('Present', '$present'),
            _stat('Half Day','$halfday'),
            _stat('Absent',  '$absent'),
          ]),
        ])),
      if (workers.isEmpty)
        Expanded(child: Center(child: Text('No workers added',
            style: GoogleFonts.poppins(color: AppColors.textLight))))
      else
        Expanded(child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 20),
          itemCount: workers.length,
          itemBuilder: (_, i) {
            final w = workers[i];
            final status = attStatus[w.id] ?? 'absent';
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6)]),
              child: Row(children: [
                CircleAvatar(radius: 22,
                  backgroundColor: _statusColor(status).withOpacity(0.12),
                  child: Text(w.name[0].toUpperCase(), style: GoogleFonts.poppins(
                      fontSize: 17, fontWeight: FontWeight.w700,
                      color: _statusColor(status)))),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(w.name, style: GoogleFonts.poppins(
                      fontSize: 13, fontWeight: FontWeight.w700)),
                  Text(w.role, style: GoogleFonts.poppins(
                      fontSize: 11, color: AppColors.textLight)),
                ])),
                // Three-button attendance selector
                _attBtn('P', 'present', status, AppColors.success, w.id, onAttChanged),
                const SizedBox(width: 6),
                _attBtn('H', 'halfday', status, AppColors.warning, w.id, onAttChanged),
                const SizedBox(width: 6),
                _attBtn('A', 'absent',  status, AppColors.error,   w.id, onAttChanged),
              ]));
          })),
    ]);
  }

  Widget _stat(String l, String v) => Column(children: [
    Text(v, style: GoogleFonts.poppins(fontSize: 20,
        fontWeight: FontWeight.w700, color: Colors.white)),
    Text(l, style: GoogleFonts.poppins(fontSize: 10, color: Colors.white70)),
  ]);

  Widget _attBtn(String label, String val, String current, Color color,
      String wId, void Function(String, String) onChanged) {
    final sel = current == val;
    return GestureDetector(
      onTap: () => onChanged(wId, val),
      child: Container(
        width: 34, height: 34,
        decoration: BoxDecoration(
          color: sel ? color : color.withOpacity(0.1),
          shape: BoxShape.circle,
          border: Border.all(color: color, width: sel ? 2 : 1)),
        child: Center(child: Text(label, style: GoogleFonts.poppins(
            fontSize: 12, fontWeight: FontWeight.w700,
            color: sel ? Colors.white : color)))));
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'present': return AppColors.success;
      case 'halfday': return AppColors.warning;
      default:        return AppColors.error;
    }
  }
}

// ══ Advance Tab ════════════════════════════════════════════════════════════
class _AdvanceTab extends StatelessWidget {
  final List<WorkerModel>    workers;
  final List<AdvancePayment> advances;
  final VoidCallback         onSaved;
  const _AdvanceTab({required this.workers, required this.advances, required this.onSaved});

  void _showAdd(BuildContext context) {
    if (workers.isEmpty) { showSnack(context, 'Add workers first', error: true); return; }
    WorkerModel? sel = workers.first;
    final amtC = TextEditingController();
    DateTime date = DateTime.now();

    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSt) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('Add Advance', style: GoogleFonts.poppins(
                fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            DropdownButtonFormField<WorkerModel>(
              value: sel,
              items: workers.map((w) => DropdownMenuItem(
                  value: w, child: Text(w.name))).toList(),
              onChanged: (v) => setSt(() => sel = v),
              decoration: const InputDecoration(labelText: 'Select Worker')),
            const SizedBox(height: 10),
            TextField(controller: amtC, keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Advance Amount (Rs.)')),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () async {
                final p = await showDatePicker(context: ctx,
                    initialDate: date, firstDate: DateTime(2020), lastDate: DateTime(2030));
                if (p != null) setSt(() => date = p);
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(10)),
                child: Row(children: [
                  const Icon(Icons.calendar_today, color: AppColors.primary, size: 16),
                  const SizedBox(width: 8),
                  Text(DateFormat('dd MMM yyyy').format(date),
                      style: GoogleFonts.poppins(fontSize: 13)),
                ]))),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                if (sel == null || amtC.text.isEmpty) return;
                await StorageService.instance.addAdvance(AdvancePayment(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  workerId: sel!.id, workerName: sel!.name,
                  amount: double.tryParse(amtC.text) ?? 0, date: date));
                if (ctx.mounted) Navigator.pop(ctx);
                onSaved();
              },
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 46)),
              child: const Text('Save Advance')),
            const SizedBox(height: 10),
          ]),
        ))));
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Padding(padding: const EdgeInsets.all(14),
        child: ElevatedButton.icon(
          onPressed: () => _showAdd(context),
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text('Add Advance Payment'),
          style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 46)))),
      Expanded(child: advances.isEmpty
        ? Center(child: Text('No advance payments',
            style: GoogleFonts.poppins(color: AppColors.textLight)))
        : ListView.builder(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 20),
            itemCount: advances.length,
            itemBuilder: (_, i) {
              final a = advances[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)]),
                child: Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(a.workerName, style: GoogleFonts.poppins(
                        fontSize: 13, fontWeight: FontWeight.w700)),
                    Text(DateFormat('dd MMM yyyy').format(a.date),
                        style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textLight)),
                  ])),
                  Text('Rs.${a.amount.toStringAsFixed(0)}',
                      style: GoogleFonts.poppins(fontSize: 16,
                          fontWeight: FontWeight.w700, color: AppColors.error)),
                ]));
            })),
    ]);
  }
}

// ══ Salary Tab ═════════════════════════════════════════════════════════════
class _SalaryTab extends StatelessWidget {
  final List<WorkerModel>    workers;
  final List<AdvancePayment> advances;
  final List<SalaryPayment>  salaries;
  final VoidCallback         onSaved;
  const _SalaryTab({required this.workers, required this.advances,
      required this.salaries, required this.onSaved});

  Future<Map> _calc(WorkerModel w, int month, int year) async {
    final all = await StorageService.instance.getAttendance();
    double days = all.where((a) =>
        a.workerId == w.id && a.date.month == month && a.date.year == year)
        .fold(0.0, (s, a) => s + a.dayValue);
    final gross = days * w.payPerDay;
    final adv = advances.where((a) =>
        a.workerId == w.id && a.date.month == month && a.date.year == year)
        .fold(0.0, (s, a) => s + a.amount);
    return {'days': days, 'gross': gross, 'adv': adv,
        'pay': (gross - adv).clamp(0.0, double.infinity)};
  }

  void _showCalc(BuildContext context) {
    if (workers.isEmpty) { showSnack(context, 'No workers', error: true); return; }
    WorkerModel? sel = workers.first;
    final now = DateTime.now();
    int m = now.month, y = now.year;
    const months = ['','Jan','Feb','Mar','Apr','May','Jun',
                    'Jul','Aug','Sep','Oct','Nov','Dec'];

    showDialog(context: context, builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSt) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Salary Calculator',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          DropdownButtonFormField<WorkerModel>(
            value: sel,
            items: workers.map((w) => DropdownMenuItem(
                value: w, child: Text(w.name))).toList(),
            onChanged: (v) => setSt(() => sel = v),
            decoration: const InputDecoration(labelText: 'Worker')),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: DropdownButtonFormField<int>(
              value: m,
              items: List.generate(12, (i) => DropdownMenuItem(
                  value: i+1, child: Text(months[i+1]))),
              onChanged: (v) => setSt(() => m = v!),
              decoration: const InputDecoration(labelText: 'Month'))),
            const SizedBox(width: 10),
            Expanded(child: DropdownButtonFormField<int>(
              value: y,
              items: [2024, 2025, 2026, 2027].map((yr) =>
                  DropdownMenuItem(value: yr, child: Text('$yr'))).toList(),
              onChanged: (v) => setSt(() => y = v!),
              decoration: const InputDecoration(labelText: 'Year'))),
          ]),
          const SizedBox(height: 14),
          if (sel != null) FutureBuilder<Map>(
            future: _calc(sel!, m, y),
            builder: (ctx, snap) {
              if (!snap.hasData) return const CircularProgressIndicator();
              final d = snap.data!;
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(10)),
                child: Column(children: [
                  _cr('Days Present', '${d['days']} days'),
                  _cr('Pay / Day', 'Rs.${sel!.payPerDay.toStringAsFixed(0)}'),
                  _cr('Gross', 'Rs.${d['gross'].toStringAsFixed(0)}'),
                  _cr('Advance', '- Rs.${d['adv'].toStringAsFixed(0)}'),
                  const Divider(),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('Payable', style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700, color: AppColors.primary)),
                    Text('Rs.${d['pay'].toStringAsFixed(0)}',
                        style: GoogleFonts.poppins(fontSize: 18,
                            fontWeight: FontWeight.w700, color: AppColors.primary)),
                  ]),
                ]));
            }),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (sel == null) return;
              final already = await StorageService.instance.isSalaryPaid(sel!.id, m, y);
              if (already) {
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) showSnack(context,
                    'Salary already paid for this month!', error: true);
                return;
              }
              final d = await _calc(sel!, m, y);
              await StorageService.instance.addSalary(SalaryPayment(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                workerId: sel!.id, workerName: sel!.name,
                month: m, year: y, amount: d['pay'], paidDate: DateTime.now()));
              if (ctx.mounted) Navigator.pop(ctx);
              onSaved();
              if (context.mounted) showSnack(context, 'Salary paid!');
            },
            child: const Text('Pay Now')),
        ])));
  }

  Widget _cr(String l, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(l, style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textMedium)),
      Text(v, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500)),
    ]));

  @override
  Widget build(BuildContext context) {
    const months = ['','Jan','Feb','Mar','Apr','May','Jun',
                    'Jul','Aug','Sep','Oct','Nov','Dec'];
    return Column(children: [
      Padding(padding: const EdgeInsets.all(14),
        child: ElevatedButton.icon(
          onPressed: () => _showCalc(context),
          icon: const Icon(Icons.calculate_outlined, color: Colors.white),
          label: const Text('Calculate & Pay Salary'),
          style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 46)))),
      Expanded(child: salaries.isEmpty
        ? Center(child: Text('No salary payments yet',
            style: GoogleFonts.poppins(color: AppColors.textLight)))
        : ListView.builder(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 20),
            itemCount: salaries.length,
            itemBuilder: (_, i) {
              final s = salaries[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)]),
                child: Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(s.workerName, style: GoogleFonts.poppins(
                        fontSize: 13, fontWeight: FontWeight.w700)),
                    Text('${months[s.month]} ${s.year}',
                        style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textLight)),
                    Container(
                      margin: const EdgeInsets.only(top: 3),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: AppColors.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6)),
                      child: Text('Paid', style: GoogleFonts.poppins(
                          fontSize: 10, color: AppColors.success, fontWeight: FontWeight.w600))),
                  ])),
                  Text('Rs.${s.amount.toStringAsFixed(0)}', style: GoogleFonts.poppins(
                      fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.success)),
                ]));
            })),
    ]);
  }
}
