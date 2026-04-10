import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../models/models.dart';
import '../../services/storage_service.dart';
import '../../utils/app_theme.dart';
import '../shared/widgets.dart';
import 'add_customer_screen.dart';

class AllCustomersScreen extends StatefulWidget {
  const AllCustomersScreen({super.key});
  @override State<AllCustomersScreen> createState() => _AllCustomersScreenState();
}

class _AllCustomersScreenState extends State<AllCustomersScreen> {
  List<CustomerModel> _all = [], _filtered = [];
  bool _loading = true;
  String _search = '';
  DateTime? _filterDate;
  UserModel? _currentUser;

  @override void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    _currentUser = await StorageService.instance.getSession();
    _all = await StorageService.instance.getCustomers();
    _apply();
    setState(() => _loading = false);
  }

  void _apply() {
    setState(() {
      _filtered = _all.where((c) {
        final ms = _search.isEmpty ||
            c.name.toLowerCase().contains(_search.toLowerCase()) ||
            c.phone.contains(_search) ||
            c.city.toLowerCase().contains(_search.toLowerCase());
        final md = _filterDate == null || sameDay(c.visitDate, _filterDate!);
        return ms && md;
      }).toList();
    });
  }

  Future<void> _delete(CustomerModel c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text('Delete?', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        content: Text('Delete booking for "${c.name}"?', style: GoogleFonts.poppins()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok == true) { await StorageService.instance.deleteCustomer(c.id); _load(); }
  }

  Future<void> _pickDate() async {
    DateTime sel = _filterDate ?? DateTime.now();
    await showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TableCalendar(
              firstDay: DateTime(2020), lastDay: DateTime(2030), focusedDay: sel,
              selectedDayPredicate: (d) => sameDay(d, sel),
              calendarFormat: CalendarFormat.month,
              headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),
              calendarStyle: const CalendarStyle(
                selectedDecoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                todayDecoration: BoxDecoration(color: Color(0x5552B788), shape: BoxShape.circle),
              ),
              onDaySelected: (s, _) => sel = s,
            ),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              TextButton(
                onPressed: () { _filterDate = null; _apply(); Navigator.pop(ctx); },
                child: const Text('Clear'),
              ),
              ElevatedButton(
                onPressed: () { _filterDate = sel; _apply(); Navigator.pop(ctx); },
                child: const Text('Apply'),
              ),
            ]),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('All Customers'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: _load),
        ],
      ),
      body: Column(children: [
        Container(
          color: AppColors.primary,
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          child: Column(children: [
            Container(
              height: 42,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
              child: TextField(
                onChanged: (v) { _search = v; _apply(); },
                decoration: InputDecoration(
                  hintText: 'Search name, city, phone...',
                  hintStyle: GoogleFonts.poppins(fontSize: 12, color: AppColors.textLight),
                  prefixIcon: const Icon(Icons.search, color: AppColors.textLight, size: 18),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(children: [
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _filterDate != null ? Colors.white : Colors.white24,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(children: [
                    Icon(Icons.calendar_today, size: 13,
                        color: _filterDate != null ? AppColors.primary : Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      _filterDate != null
                          ? DateFormat('dd MMM').format(_filterDate!)
                          : 'Filter by date',
                      style: GoogleFonts.poppins(
                          fontSize: 11, fontWeight: FontWeight.w600,
                          color: _filterDate != null ? AppColors.primary : Colors.white),
                    ),
                  ]),
                ),
              ),
              if (_filterDate != null) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () { _filterDate = null; _apply(); },
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                    child: const Icon(Icons.close, color: Colors.white, size: 14),
                  ),
                ),
              ],
            ]),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
          child: Text('${_filtered.length} customers',
              style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textLight)),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : _filtered.isEmpty
                  ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.people_outline, size: 56, color: Colors.grey.shade300),
                      const SizedBox(height: 10),
                      Text('No customers found',
                          style: GoogleFonts.poppins(color: AppColors.textLight)),
                    ]))
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: AppColors.primary,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(14, 0, 14, 30),
                        itemCount: _filtered.length,
                        itemBuilder: (_, i) => _card(_filtered[i]),
                      ),
                    ),
        ),
      ]),
    );
  }

  Widget _card(CustomerModel c) {
    final fmt = NumberFormat('#,##,###', 'en_IN');
    final served = c.canteenServed;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06),
            blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // ── Header bar ──────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.06),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16), topRight: Radius.circular(16),
            ),
          ),
          child: Row(children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.primary.withOpacity(0.15),
              child: Text(c.name[0].toUpperCase(),
                  style: GoogleFonts.poppins(fontSize: 16,
                      fontWeight: FontWeight.w700, color: AppColors.primary)),
            ),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(c.name, style: GoogleFonts.poppins(
                  fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark)),
              Text('${c.city}  •  ${c.phone}',
                  style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textLight)),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('Rs.${fmt.format(c.totalAmount)}',
                  style: GoogleFonts.poppins(fontSize: 14,
                      fontWeight: FontWeight.w700, color: AppColors.primary)),
              Container(
                margin: const EdgeInsets.only(top: 3),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: (served ? AppColors.success : AppColors.warning).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(served ? 'Served' : 'Pending',
                    style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w700,
                        color: served ? AppColors.success : AppColors.warning)),
              ),
            ]),
          ]),
        ),

        Padding(
          padding: const EdgeInsets.all(14),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // ── Left: Details ────────────────────────────────────────
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Package
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(c.packageName,
                    style: GoogleFonts.poppins(fontSize: 11,
                        color: AppColors.primary, fontWeight: FontWeight.w500)),
              ),
              const SizedBox(height: 8),
              // Guests + payment
              Row(children: [
                const Icon(Icons.groups_outlined, size: 14, color: AppColors.textLight),
                const SizedBox(width: 4),
                Text('${c.totalGuests} guests',
                    style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textMedium)),
                const SizedBox(width: 10),
                Icon(c.paymentMode == PaymentMode.cash
                    ? Icons.money_outlined : Icons.phone_android_outlined,
                    size: 14, color: AppColors.textLight),
                const SizedBox(width: 4),
                Text(c.paymentMode == PaymentMode.cash ? 'Cash' : 'Online',
                    style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textMedium)),
              ]),
              const SizedBox(height: 6),
              Text('Booked: ${DateFormat('dd MMM yyyy').format(c.visitDate)}',
                  style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textLight)),
              const SizedBox(height: 8),
              // Food options
              if (c.food.breakfast > 0 || c.food.lunch > 0 ||
                  c.food.snacks > 0 || c.food.dinner > 0) ...[
                Text('Food Options:',
                    style: GoogleFonts.poppins(fontSize: 11,
                        fontWeight: FontWeight.w600, color: AppColors.textDark)),
                const SizedBox(height: 4),
                if (c.food.breakfast > 0) _foodRow('Breakfast', c.food.breakfast),
                if (c.food.lunch > 0)     _foodRow('Lunch',     c.food.lunch),
                if (c.food.snacks > 0)    _foodRow('Snacks',    c.food.snacks),
                if (c.food.dinner > 0)    _foodRow('Dinner',    c.food.dinner),
              ],
              const SizedBox(height: 10),
              // Edit / Delete buttons
              Row(children: [
                if (_currentUser != null &&
                    (_currentUser!.role == UserRole.manager ||
                        _currentUser!.role == UserRole.owner ||
                        _currentUser!.role == UserRole.admin))
                  GestureDetector(
                    onTap: () async {
                      final pkgs = await StorageService.instance.getPackages();
                      if (!mounted) return;
                      final ok = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(builder: (_) => BookingFormScreen(
                          managerUser: _currentUser!, pkg: null,
                          existing: c, packages: pkgs,
                        )),
                      );
                      if (ok == true) _load();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.cardBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(children: [
                        const Icon(Icons.edit_outlined, size: 13, color: AppColors.cardBlue),
                        const SizedBox(width: 4),
                        Text('Edit', style: GoogleFonts.poppins(
                            fontSize: 11, color: AppColors.cardBlue,
                            fontWeight: FontWeight.w600)),
                      ]),
                    ),
                  ),
                const SizedBox(width: 8),
                if (_currentUser != null &&
                    (_currentUser!.role == UserRole.owner ||
                        _currentUser!.role == UserRole.admin))
                  GestureDetector(
                    onTap: () => _delete(c),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(children: [
                        const Icon(Icons.delete_outline, size: 13, color: AppColors.error),
                        const SizedBox(width: 4),
                        Text('Delete', style: GoogleFonts.poppins(
                            fontSize: 11, color: AppColors.error,
                            fontWeight: FontWeight.w600)),
                      ]),
                    ),
                  ),
              ]),
            ])),

            const SizedBox(width: 12),

            // ── Right: QR Code (always visible) ─────────────────────
            Column(children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200, width: 1.5),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06),
                      blurRadius: 6, offset: const Offset(0, 2))],
                ),
                child: QrImageView(
                  data: c.qrCode,
                  version: QrVersions.auto,
                  size: 100,
                  backgroundColor: Colors.white,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: Color(0xFF1B4332),
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Color(0xFF1B4332),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text('Scan to serve',
                  style: GoogleFonts.poppins(fontSize: 9, color: AppColors.textLight)),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: (served ? AppColors.success : Colors.grey).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  served ? '✓ Used' : 'Valid',
                  style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.w700,
                      color: served ? AppColors.success : Colors.grey),
                ),
              ),
            ]),
          ]),
        ),
      ]),
    );
  }

  Widget _foodRow(String label, int count) => Padding(
    padding: const EdgeInsets.only(bottom: 2),
    child: Row(children: [
      const Icon(Icons.circle, size: 5, color: AppColors.primary),
      const SizedBox(width: 5),
      Text('$label: $count guests',
          style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textMedium)),
    ]),
  );
}
