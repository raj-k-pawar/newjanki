import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/booking_model.dart';
import '../../services/data_service.dart';
import '../../utils/app_theme.dart';
import 'add_customer_screen.dart';
import 'qr_screen.dart';

class AllCustomersScreen extends StatefulWidget {
  const AllCustomersScreen({super.key});
  @override
  State<AllCustomersScreen> createState() => _AllCustomersScreenState();
}

class _AllCustomersScreenState extends State<AllCustomersScreen> {
  final DataService _ds = DataService();
  List<CustomerModel> _all = [];
  List<CustomerModel> _filtered = [];
  bool _isLoading = true;
  String _search = '';
  BookingStatus? _statusFilter;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    _all = await _ds.getCustomers();
    _applyFilter();
    setState(() => _isLoading = false);
  }

  void _applyFilter() {
    setState(() {
      _filtered = _all.where((c) {
        final matchSearch = _search.isEmpty ||
            c.name.toLowerCase().contains(_search.toLowerCase()) ||
            c.phone.contains(_search) ||
            c.city.toLowerCase().contains(_search.toLowerCase());
        final matchStatus = _statusFilter == null || c.status == _statusFilter;
        return matchSearch && matchStatus;
      }).toList();
    });
  }

  Future<void> _delete(CustomerModel c) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete Customer',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        content: Text('Are you sure you want to delete "${c.name}"?',
            style: GoogleFonts.poppins()),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _ds.deleteCustomer(c.id);
      _load();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Customer deleted'),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  Future<void> _edit(CustomerModel c) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => AddCustomerScreen(existing: c)),
    );
    if (updated == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('All Customers',
            style: GoogleFonts.playfairDisplay(
                fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _load),
        ],
      ),
      body: Column(children: [
        // Search + filter
        Container(
          color: AppColors.primary,
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          child: Column(children: [
            Container(
              height: 42,
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(10)),
              child: TextField(
                onChanged: (v) { _search = v; _applyFilter(); },
                decoration: InputDecoration(
                  hintText: 'Search name, city, phone...',
                  hintStyle: GoogleFonts.poppins(fontSize: 12, color: AppColors.textLight),
                  prefixIcon: Icon(Icons.search, color: AppColors.textLight, size: 18),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                _chip(null, 'All'),
                ...BookingStatus.values.map((s) => _chip(s, s.name[0].toUpperCase() + s.name.substring(1))),
              ]),
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${_filtered.length} bookings',
                  style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textLight)),
              Text('Pull to refresh',
                  style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textLight)),
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : _filtered.isEmpty
                  ? _empty()
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: AppColors.primary,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(14, 0, 14, 20),
                        itemCount: _filtered.length,
                        itemBuilder: (_, i) => _customerCard(_filtered[i]),
                      ),
                    ),
        ),
      ]),
    );
  }

  Widget _chip(BookingStatus? s, String label) {
    final sel = _statusFilter == s;
    return GestureDetector(
      onTap: () { _statusFilter = s; _applyFilter(); },
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: sel ? Colors.white : Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: GoogleFonts.poppins(
                fontSize: 11, fontWeight: FontWeight.w600,
                color: sel ? AppColors.primary : Colors.white)),
      ),
    );
  }

  Widget _customerCard(CustomerModel c) {
    final statusColor = _statusColor(c.status);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Header row
          Row(children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.primary.withOpacity(0.1),
              child: Text(c.name[0].toUpperCase(),
                  style: GoogleFonts.poppins(
                      fontSize: 17, fontWeight: FontWeight.w700,
                      color: AppColors.primary)),
            ),
            const SizedBox(width: 10),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.name,
                    style: GoogleFonts.poppins(
                        fontSize: 14, fontWeight: FontWeight.w700,
                        color: AppColors.textDark)),
                Text('${c.city}  •  ${c.phone}',
                    style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textLight)),
              ],
            )),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(c.statusDisplay,
                  style: GoogleFonts.poppins(
                      fontSize: 10, fontWeight: FontWeight.w700,
                      color: statusColor)),
            ),
          ]),
          const SizedBox(height: 10),
          // Batch
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.06),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(c.batchDisplayName,
                style: GoogleFonts.poppins(
                    fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.primary)),
          ),
          const SizedBox(height: 8),
          // Stats row
          Row(children: [
            _badge(Icons.groups_outlined, '${c.totalGuests} guests'),
            const SizedBox(width: 8),
            _badge(c.paymentMethod == PaymentMethod.cash
                ? Icons.money_outlined : Icons.phone_android_outlined,
                c.paymentMethodDisplay),
            const Spacer(),
            Text('₹${c.totalAmount.toStringAsFixed(0)}',
                style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.w700,
                    color: AppColors.primary)),
          ]),
          // QR status
          const SizedBox(height: 8),
          Row(children: [
            GestureDetector(
              onTap: () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => QrScreen(customer: c))),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: c.qrUsed
                      ? AppColors.error.withOpacity(0.1)
                      : AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: c.qrUsed ? AppColors.error.withOpacity(0.3)
                        : AppColors.success.withOpacity(0.3),
                  ),
                ),
                child: Row(children: [
                  Icon(Icons.qr_code, size: 13,
                      color: c.qrUsed ? AppColors.error : AppColors.success),
                  const SizedBox(width: 4),
                  Text(c.qrUsed ? 'QR Used' : 'View QR',
                      style: GoogleFonts.poppins(
                          fontSize: 10, fontWeight: FontWeight.w600,
                          color: c.qrUsed ? AppColors.error : AppColors.success)),
                ]),
              ),
            ),
            const Spacer(),
            // Edit
            IconButton(
              icon: Icon(Icons.edit_outlined, color: AppColors.cardBlue, size: 20),
              onPressed: () => _edit(c),
              padding: EdgeInsets.zero, constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 16),
            // Delete
            IconButton(
              icon: Icon(Icons.delete_outline, color: AppColors.error, size: 20),
              onPressed: () => _delete(c),
              padding: EdgeInsets.zero, constraints: const BoxConstraints(),
            ),
          ]),
        ]),
      ),
    );
  }

  Widget _badge(IconData icon, String label) => Row(children: [
        Icon(icon, size: 13, color: AppColors.textLight),
        const SizedBox(width: 3),
        Text(label,
            style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textMedium)),
      ]);

  Widget _empty() => Center(child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(Icons.people_outline, size: 60, color: Colors.grey.shade300),
      const SizedBox(height: 14),
      Text('No customers found',
          style: GoogleFonts.poppins(fontSize: 15, color: AppColors.textLight)),
    ],
  ));

  Color _statusColor(BookingStatus s) {
    switch (s) {
      case BookingStatus.confirmed: return AppColors.success;
      case BookingStatus.pending:   return AppColors.warning;
      case BookingStatus.cancelled: return AppColors.error;
      case BookingStatus.completed: return AppColors.cardBlue;
    }
  }
}
