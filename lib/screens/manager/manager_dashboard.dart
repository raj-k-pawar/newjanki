import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../models/models.dart';
import '../../services/storage_service.dart';
import '../../utils/app_theme.dart';
import '../auth/login_screen.dart';
import '../shared/widgets.dart';
import 'add_customer_screen.dart';
import 'all_customers_screen.dart';
import 'manage_workers_screen.dart';
import 'enquiry_screen.dart';

class ManagerDashboard extends StatefulWidget {
  final UserModel user;
  const ManagerDashboard({super.key, required this.user});
  @override
  State<ManagerDashboard> createState() => _ManagerDashboardState();
}

class _ManagerDashboardState extends State<ManagerDashboard> {
  DateTime _selectedDate = DateTime.now();
  List<CustomerModel> _customers = [];
  bool _loading = true;
  bool _calExpanded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    _customers = await StorageService.instance.getCustomersByDate(_selectedDate);
    setState(() => _loading = false);
  }

  int    get _totalBookings => _customers.length;
  int    get _totalGuests   => _customers.fold(0, (s, c) => s + c.totalGuests);
  double get _cashAmt       => _customers
      .where((c) => c.paymentMode == PaymentMode.cash)
      .fold(0.0, (s, c) => s + c.totalAmount);
  double get _onlineAmt     => _customers
      .where((c) => c.paymentMode == PaymentMode.online)
      .fold(0.0, (s, c) => s + c.totalAmount);
  double get _totalAmt      => _cashAmt + _onlineAmt;

  int _batchCount(bool Function(CustomerModel) f) =>
      _customers.where(f).fold(0, (s, c) => s + c.totalGuests);

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##,###', 'en_IN');
    final isToday = sameDay(_selectedDate, DateTime.now());
    final dateLabel = isToday
        ? 'Today – ${DateFormat('dd MMM yyyy').format(_selectedDate)}'
        : DateFormat('EEEE, dd MMM yyyy').format(_selectedDate);
    final hour = DateTime.now().hour;
    final greet = hour < 12 ? 'Good Morning' : hour < 17 ? 'Good Afternoon' : 'Good Evening';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppColors.primary,
        child: CustomScrollView(
          slivers: [
            // ── Header ──────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1B4332), Color(0xFF2D6A4F), Color(0xFF40916C)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Column(
                    children: [
                      // Top bar
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                        child: Row(
                          children: [
                            Container(
                              width: 48, height: 48,
                              decoration: BoxDecoration(
                                color: Colors.white24,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Center(
                                child: Text(
                                  widget.user.fullName[0].toUpperCase(),
                                  style: GoogleFonts.poppins(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(greet,
                                      style: GoogleFonts.poppins(
                                          fontSize: 11, color: Colors.white70)),
                                  Text(widget.user.fullName,
                                      style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white)),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: () async {
                                await StorageService.instance.logout();
                                if (!mounted) return;
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                                  (_) => false,
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white24,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.logout,
                                    color: Colors.white, size: 20),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Role badge
                      Padding(
                        padding: const EdgeInsets.only(left: 20),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text('🌿 ${widget.user.roleLabel}',
                                style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Date selector bar
                      GestureDetector(
                        onTap: () =>
                            setState(() => _calExpanded = !_calExpanded),
                        child: Container(
                          margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white30),
                          ),
                          child: Row(children: [
                            const Icon(Icons.calendar_today,
                                color: Colors.white, size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(dateLabel,
                                  style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white)),
                            ),
                            Icon(
                              _calExpanded
                                  ? Icons.expand_less
                                  : Icons.expand_more,
                              color: Colors.white,
                            ),
                          ]),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),

            // ── Calendar (expandable) ─────────────────────────────────
            if (_calExpanded)
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.08),
                          blurRadius: 12),
                    ],
                  ),
                  child: TableCalendar(
                    firstDay: DateTime(2020),
                    lastDay: DateTime(2030),
                    focusedDay: _selectedDate,
                    selectedDayPredicate: (d) => sameDay(d, _selectedDate),
                    calendarFormat: CalendarFormat.month,
                    headerStyle: HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                      titleTextStyle: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                    calendarStyle: const CalendarStyle(
                      selectedDecoration: BoxDecoration(
                          color: AppColors.primary, shape: BoxShape.circle),
                      todayDecoration: BoxDecoration(
                          color: Color(0x5552B788), shape: BoxShape.circle),
                      todayTextStyle: TextStyle(color: AppColors.primaryDark),
                    ),
                    onDaySelected: (sel, _) {
                      setState(() {
                        _selectedDate = sel;
                        _calExpanded = false;
                      });
                      _load();
                    },
                  ),
                ),
              ),

            // ── Stats Cards ───────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(color: AppColors.primary))
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Transaction Details
                          Text('Transaction Details',
                              style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textDark)),
                          const SizedBox(height: 10),
                          Row(children: [
                            Expanded(
                              child: _statCard('Bookings',
                                  '$_totalBookings',
                                  Icons.book_online_outlined,
                                  const Color(0xFF4361EE)),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _statCard('Guests',
                                  '$_totalGuests',
                                  Icons.groups_outlined,
                                  AppColors.primary),
                            ),
                          ]),
                          const SizedBox(height: 10),
                          _wideCard(
                            'Total Revenue',
                            'Rs.${fmt.format(_totalAmt)}',
                            Icons.currency_rupee,
                            const Color(0xFF2D6A4F),
                          ),
                          const SizedBox(height: 10),
                          Row(children: [
                            Expanded(
                              child: _statCard(
                                  'Cash',
                                  'Rs.${fmt.format(_cashAmt)}',
                                  Icons.money_outlined,
                                  const Color(0xFFF4A261),
                                  small: true),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _statCard(
                                  'Online',
                                  'Rs.${fmt.format(_onlineAmt)}',
                                  Icons.phone_android_outlined,
                                  const Color(0xFF7B2D8B),
                                  small: true),
                            ),
                          ]),
                          const SizedBox(height: 20),

                          // Batch Wise
                          Text('Batch Wise',
                              style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textDark)),
                          const SizedBox(height: 10),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3)),
                              ],
                            ),
                            child: Column(children: [
                              _batchRow('Morning Batch',
                                  Icons.wb_sunny_outlined,
                                  const Color(0xFFF4A261),
                                  _batchCount((c) =>
                                      c.packageName.contains('सकाळी') &&
                                      !c.packageName.contains('निवासी'))),
                              _divider(),
                              _batchRow('Evening Batch',
                                  Icons.nights_stay_outlined,
                                  const Color(0xFF7B2D8B),
                                  _batchCount((c) =>
                                      c.packageName.contains('सायंकाळी') &&
                                      !c.packageName.contains('निवासी'))),
                              _divider(),
                              _batchRow('Full Day',
                                  Icons.all_inclusive_outlined,
                                  const Color(0xFF4361EE),
                                  _batchCount((c) =>
                                      c.packageName.contains('फुल डे'))),
                              _divider(),
                              _batchRow('Stay Customers',
                                  Icons.hotel_outlined,
                                  const Color(0xFF0A9396),
                                  _batchCount((c) =>
                                      c.packageName.contains('निवासी'))),
                            ]),
                          ),
                          const SizedBox(height: 20),

                          // Action buttons
                          Text('Quick Actions',
                              style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textDark)),
                          const SizedBox(height: 10),
                          _actionBtn(
                            icon: Icons.person_add_outlined,
                            label: 'Add New Customer',
                            sub: 'Register a new booking',
                            color: AppColors.primary,
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AddCustomerScreen(
                                      managerUser: widget.user),
                                ),
                              );
                              _load();
                            },
                          ),
                          _actionBtn(
                            icon: Icons.people_outline,
                            label: 'View All Customers',
                            sub: 'Browse & manage bookings',
                            color: const Color(0xFF4361EE),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const AllCustomersScreen()),
                            ),
                          ),
                          _actionBtn(
                            icon: Icons.badge_outlined,
                            label: 'Manage Workers',
                            sub: 'Mark attendance',
                            color: const Color(0xFF0A9396),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const ManageWorkersScreen(ownerMode: false),
                              ),
                            ),
                          ),
                          _actionBtn(
                            icon: Icons.contact_phone_outlined,
                            label: 'Add Enquiry',
                            sub: 'Record visitor enquiry',
                            color: const Color(0xFFF4A261),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const EnquiryScreen()),
                            ),
                          ),
                  const SizedBox(height: 30),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color,
      {bool small = false}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.75)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 34, height: 34,
          decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(9)),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
        const SizedBox(height: 10),
        Text(value,
            style: GoogleFonts.poppins(
                fontSize: small ? 14 : 20,
                fontWeight: FontWeight.w700,
                color: Colors.white)),
        Text(label,
            style: GoogleFonts.poppins(
                fontSize: 11, color: Colors.white.withOpacity(0.85))),
      ]),
    );
  }

  Widget _wideCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withRed(20), color],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: color.withOpacity(0.35),
              blurRadius: 10,
              offset: const Offset(0, 5)),
        ],
      ),
      child: Row(children: [
        Container(
          width: 50, height: 50,
          decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: Colors.white, size: 28),
        ),
        const SizedBox(width: 14),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 12, color: Colors.white70)),
          Text(value,
              style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.white)),
        ]),
        const Spacer(),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(8)),
          child: Text('Today',
              style: GoogleFonts.poppins(
                  fontSize: 11, color: Colors.white)),
        ),
      ]),
    );
  }

  Widget _batchRow(String label, IconData icon, Color color, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 13, color: AppColors.textDark)),
        ),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20)),
          child: Text('$count guests',
              style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color)),
        ),
      ]),
    );
  }

  Widget _divider() => Container(
      height: 0.5,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: Colors.grey.shade200);

  Widget _actionBtn({
    required IconData icon,
    required String label,
    required String sub,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 3)),
          ],
        ),
        child: Row(children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark)),
                Text(sub,
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: AppColors.textLight)),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: color),
        ]),
      ),
    );
  }
}
