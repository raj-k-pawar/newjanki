import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../models/models.dart';
import '../../services/storage_service.dart';
import '../../utils/app_theme.dart';
import '../auth/login_screen.dart';
import '../shared/widgets.dart';

class CanteenDashboard extends StatefulWidget {
  final UserModel user;
  const CanteenDashboard({super.key, required this.user});
  @override
  State<CanteenDashboard> createState() => _CanteenDashboardState();
}

class _CanteenDashboardState extends State<CanteenDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() { super.initState(); _tab = TabController(length: 2, vsync: this); }

  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0A4D6E), Color(0xFF0A9396), Color(0xFF48CAE4)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(bottom: false, child: Column(children: [
            Padding(padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: Row(children: [
                Container(width: 46, height: 46,
                  decoration: BoxDecoration(color: Colors.white24,
                      borderRadius: BorderRadius.circular(13)),
                  child: Center(child: Text(widget.user.fullName[0].toUpperCase(),
                      style: GoogleFonts.poppins(fontSize: 20,
                          fontWeight: FontWeight.w700, color: Colors.white)))),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Canteen Staff', style: GoogleFonts.poppins(fontSize: 11, color: Colors.white70)),
                  Text(widget.user.fullName, style: GoogleFonts.poppins(
                      fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                ])),
                GestureDetector(
                  onTap: () async {
                    await StorageService.instance.logout();
                    if (!mounted) return;
                    Navigator.pushAndRemoveUntil(context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
                  },
                  child: Container(padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.white24,
                        borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.logout, color: Colors.white, size: 20))),
              ])),
            TabBar(controller: _tab,
              tabs: const [Tab(text: 'Scan QR Code'), Tab(text: 'All Customers')],
              indicatorColor: Colors.white, labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          ])),
        ),
        Expanded(child: TabBarView(controller: _tab, children: [
          _ScanQrTab(canteenUser: widget.user),
          _CustomerListTab(canteenUser: widget.user),
        ])),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// SCAN QR TAB
// ══════════════════════════════════════════════════════════════════════════════
class _ScanQrTab extends StatefulWidget {
  final UserModel canteenUser;
  const _ScanQrTab({required this.canteenUser});
  @override State<_ScanQrTab> createState() => _ScanQrTabState();
}

class _ScanQrTabState extends State<_ScanQrTab> with WidgetsBindingObserver {
  MobileScannerController _camCtrl = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back, torchEnabled: false,
  );
  final _manualCtrl = TextEditingController();
  bool _cameraActive = false, _processing = false, _torchOn = false;
  String? _resultMsg;
  Color _resultColor = AppColors.success;
  IconData _resultIcon = Icons.check_circle_outline;
  CustomerModel? _resultCustomer;

  @override void initState() { super.initState(); WidgetsBinding.instance.addObserver(this); }
  @override void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    try { _camCtrl.dispose(); } catch (_) {}
    _manualCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      if (_cameraActive) _camCtrl.stop();
    } else if (state == AppLifecycleState.resumed && _cameraActive) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted && _cameraActive) _camCtrl.start();
      });
    }
  }

  Future<void> _toggleCamera() async {
    if (_cameraActive) {
      try { await _camCtrl.stop(); } catch (_) {}
      try { await _camCtrl.dispose(); } catch (_) {}
      setState(() {
        _cameraActive = false; _torchOn = false;
        _camCtrl = MobileScannerController(
          detectionSpeed: DetectionSpeed.noDuplicates,
          facing: CameraFacing.back, torchEnabled: false,
        );
      });
    } else {
      setState(() => _cameraActive = true);
      await Future.delayed(const Duration(milliseconds: 100));
      try { await _camCtrl.start(); } catch (_) {
        try { await _camCtrl.dispose(); } catch (_) {}
        _camCtrl = MobileScannerController(
          detectionSpeed: DetectionSpeed.noDuplicates,
          facing: CameraFacing.back, torchEnabled: false,
        );
        await _camCtrl.start();
      }
    }
  }

  void _toggleTorch() { setState(() => _torchOn = !_torchOn); _camCtrl.toggleTorch(); }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_processing) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null || barcode.rawValue == null) return;
    final code = barcode.rawValue!.trim();
    setState(() { _processing = true; _cameraActive = false; _torchOn = false; });
    try { await _camCtrl.stop(); } catch (_) {}
    try { await _camCtrl.dispose(); } catch (_) {}
    _camCtrl = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back, torchEnabled: false,
    );
    await _validate(code);
  }

  Future<void> _validate(String code) async {
    final trimmed = code.trim();
    if (trimmed.isEmpty) { showSnack(context, 'Please enter a QR code', error: true); return; }
    setState(() { _processing = true; _resultMsg = null; });

    final all = await StorageService.instance.getCustomers();
    final today = DateTime.now();
    CustomerModel? customer;
    for (final c in all) { if (c.qrCode == trimmed) { customer = c; break; } }

    if (customer == null) {
      setState(() {
        _resultMsg = 'QR code not found.\nInvalid or unrecognised code.';
        _resultColor = AppColors.error; _resultIcon = Icons.cancel_outlined;
        _resultCustomer = null; _processing = false;
      });
      return;
    }
    if (!sameDay(customer.visitDate, today)) {
      setState(() {
        _resultMsg = 'QR not valid for today.\nBooked for: ${DateFormat("dd MMM yyyy").format(customer!.visitDate)}';
        _resultColor = AppColors.warning; _resultIcon = Icons.warning_amber_outlined;
        _resultCustomer = customer; _processing = false;
      });
      return;
    }
    if (customer.canteenServed) {
      setState(() {
        _resultMsg = 'Already served!\nThis QR was already scanned today.';
        _resultColor = AppColors.warning; _resultIcon = Icons.info_outline;
        _resultCustomer = customer; _processing = false;
      });
      return;
    }

    final servedCustomer = customer;
    await StorageService.instance.markCanteenServed(servedCustomer.id);
    _manualCtrl.clear();
    final displayCustomer = CustomerModel(
      id: servedCustomer.id, name: servedCustomer.name, city: servedCustomer.city,
      phone: servedCustomer.phone, packageId: servedCustomer.packageId,
      packageName: servedCustomer.packageName, adultsCount: servedCustomer.adultsCount,
      childrenCount: servedCustomer.childrenCount, adultRate: servedCustomer.adultRate,
      childRate: servedCustomer.childRate, food: servedCustomer.food,
      advance: servedCustomer.advance, foodDeductionAmt: servedCustomer.foodDeductionAmt,
      paymentMode: servedCustomer.paymentMode, visitDate: servedCustomer.visitDate,
      createdAt: servedCustomer.createdAt, qrCode: servedCustomer.qrCode,
      managerId: servedCustomer.managerId, managerName: servedCustomer.managerName,
      qrUsed: true, canteenServed: true,
    );
    setState(() {
      _resultMsg = 'Valid QR! Customer marked as SERVED.';
      _resultColor = AppColors.success; _resultIcon = Icons.check_circle_outline;
      _resultCustomer = displayCustomer; _processing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SectionHeader('Camera QR Scanner', icon: Icons.qr_code_scanner),
        GestureDetector(
          onTap: _cameraActive ? null : _toggleCamera,
          child: Container(
            width: double.infinity, height: 220,
            decoration: BoxDecoration(
              color: _cameraActive ? Colors.black : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: _cameraActive ? const Color(0xFF0A9396) : Colors.grey.shade300,
                  width: 2)),
            child: _cameraActive
              ? ClipRRect(borderRadius: BorderRadius.circular(14),
                  child: Stack(children: [
                    MobileScanner(controller: _camCtrl, onDetect: _onDetect,
                      errorBuilder: (ctx, err, child) => Center(child: Column(
                        mainAxisAlignment: MainAxisAlignment.center, children: [
                          const Icon(Icons.camera_alt_outlined, size: 48, color: Colors.white54),
                          const SizedBox(height: 10),
                          Text('Camera error', style: GoogleFonts.poppins(color: Colors.white, fontSize: 12)),
                          const SizedBox(height: 12),
                          ElevatedButton(onPressed: () async {
                            try { await _camCtrl.stop(); } catch (_) {}
                            await Future.delayed(const Duration(milliseconds: 300));
                            await _camCtrl.start();
                          }, child: const Text('Retry')),
                        ]))),
                    Center(child: Container(width: 170, height: 170,
                      decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFF48CAE4), width: 2.5),
                          borderRadius: BorderRadius.circular(12)))),
                    Positioned(top: 10, right: 10, child: Row(children: [
                      GestureDetector(onTap: _toggleTorch,
                        child: Container(padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.black45,
                              borderRadius: BorderRadius.circular(8)),
                          child: Icon(_torchOn ? Icons.flash_on : Icons.flash_off,
                              color: _torchOn ? Colors.yellow : Colors.white, size: 22))),
                      const SizedBox(width: 8),
                      GestureDetector(onTap: _toggleCamera,
                        child: Container(padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.black45,
                              borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.close, color: Colors.white, size: 22))),
                    ])),
                    const Positioned(bottom: 16, left: 0, right: 0,
                      child: Center(child: Text('Point at QR code',
                          style: TextStyle(color: Colors.white, fontSize: 13,
                              fontWeight: FontWeight.w600,
                              shadows: [Shadow(blurRadius: 4)])))),
                  ]))
              : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.qr_code_scanner, size: 60, color: Colors.grey.shade400),
                  const SizedBox(height: 10),
                  Text('Tap to Open Camera', style: GoogleFonts.poppins(
                      fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
                  Text('Scan customer booking QR code', style: GoogleFonts.poppins(
                      fontSize: 12, color: Colors.grey.shade500)),
                ]),
          )),
        const SizedBox(height: 20),
        const SectionHeader('Or Enter QR Code Manually', icon: Icons.keyboard_outlined),
        WhiteCard(child: Column(children: [
          TextFormField(controller: _manualCtrl,
            decoration: InputDecoration(
              labelText: 'QR Code (e.g. JAT-1234567890)',
              prefixIcon: const Icon(Icons.qr_code_2, color: AppColors.primary, size: 22),
              suffixIcon: IconButton(icon: const Icon(Icons.send, color: AppColors.primary),
                  onPressed: () => _validate(_manualCtrl.text))),
            onFieldSubmitted: _validate, textInputAction: TextInputAction.done),
          const SizedBox(height: 14),
          SizedBox(width: double.infinity, height: 50,
            child: ElevatedButton.icon(
              onPressed: _processing ? null : () => _validate(_manualCtrl.text),
              icon: _processing
                ? const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.check_circle_outline, color: Colors.white),
              label: Text('Validate & Mark Served', style: GoogleFonts.poppins(
                  fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0A9396)))),
        ])),

        // ── Result ──────────────────────────────────────────────────
        if (_resultMsg != null) ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _resultColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _resultColor.withOpacity(0.4))),
            child: Row(children: [
              Icon(_resultIcon, color: _resultColor, size: 28),
              const SizedBox(width: 12),
              Expanded(child: Text(_resultMsg!, style: GoogleFonts.poppins(
                  fontSize: 14, fontWeight: FontWeight.w700, color: _resultColor))),
            ])),
          if (_resultCustomer != null) ...[
            const SizedBox(height: 12),
            _CustomerDetailCard(customer: _resultCustomer!),
          ],
        ],
        const SizedBox(height: 30),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// SHARED: Customer Detail Card (used in Scan result + All Customers list)
// ══════════════════════════════════════════════════════════════════════════════
class _CustomerDetailCard extends StatelessWidget {
  final CustomerModel customer;
  final bool showStatus;
  const _CustomerDetailCard({required this.customer, this.showStatus = true});

  @override
  Widget build(BuildContext context) {
    final served = customer.canteenServed;
    final hasFoods = customer.food.breakfast > 0 || customer.food.lunch > 0 ||
        customer.food.snacks > 0 || customer.food.dinner > 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07),
            blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Container(
          padding: const EdgeInsets.all(14),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0A4D6E), Color(0xFF0A9396)],
              begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16), topRight: Radius.circular(16))),
          child: Row(children: [
            CircleAvatar(radius: 22, backgroundColor: Colors.white24,
              child: Text(customer.name[0].toUpperCase(),
                  style: GoogleFonts.poppins(fontSize: 18,
                      fontWeight: FontWeight.w700, color: Colors.white))),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(customer.name, style: GoogleFonts.poppins(
                  fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
              Text(customer.city, style: GoogleFonts.poppins(
                  fontSize: 12, color: Colors.white70)),
            ])),
            if (showStatus)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: served ? AppColors.success : AppColors.warning,
                  borderRadius: BorderRadius.circular(20)),
                child: Text(served ? '✓ SERVED' : 'PENDING',
                    style: GoogleFonts.poppins(fontSize: 12,
                        fontWeight: FontWeight.w700, color: Colors.white))),
          ])),

        // Body
        Padding(padding: const EdgeInsets.all(14), child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Package
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF0A9396).withOpacity(0.08),
              borderRadius: BorderRadius.circular(8)),
            child: Text(customer.packageName, style: GoogleFonts.poppins(
                fontSize: 12, fontWeight: FontWeight.w600,
                color: const Color(0xFF0A4D6E)))),
          const SizedBox(height: 12),
          // Total guests
          Row(children: [
            Container(width: 34, height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFF0A9396).withOpacity(0.1),
                borderRadius: BorderRadius.circular(9)),
              child: const Icon(Icons.groups_outlined,
                  color: Color(0xFF0A9396), size: 20)),
            const SizedBox(width: 10),
            Text('Total Guests :  ', style: GoogleFonts.poppins(
                fontSize: 13, color: AppColors.textMedium)),
            Text('${customer.totalGuests}', style: GoogleFonts.poppins(
                fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textDark)),
          ]),
          // Food options
          if (hasFoods) ...[
            const SizedBox(height: 14),
            Row(children: [
              Container(width: 4, height: 16,
                decoration: BoxDecoration(color: const Color(0xFF0A9396),
                    borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 8),
              Text('Food Options', style: GoogleFonts.poppins(
                  fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textDark)),
            ]),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200)),
              child: Column(children: [
                if (customer.food.breakfast > 0)
                  _foodRow('🍽️', 'Breakfast', customer.food.breakfast, true),
                if (customer.food.lunch > 0)
                  _foodRow('🍛', 'Lunch', customer.food.lunch,
                      customer.food.breakfast == 0),
                if (customer.food.snacks > 0)
                  _foodRow('☕', 'Snacks', customer.food.snacks,
                      customer.food.breakfast == 0 && customer.food.lunch == 0),
                if (customer.food.dinner > 0)
                  _foodRow('🌙', 'Dinner', customer.food.dinner,
                      customer.food.breakfast == 0 && customer.food.lunch == 0 &&
                          customer.food.snacks == 0),
              ])),
          ],
        ])),
      ]));
  }

  Widget _foodRow(String emoji, String label, int count, bool isFirst) =>
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        border: isFirst ? null : const Border(
            top: BorderSide(color: Color(0xFFEEEEEE)))),
      child: Row(children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: GoogleFonts.poppins(
            fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textDark))),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFF0A9396).withOpacity(0.1),
            borderRadius: BorderRadius.circular(20)),
          child: Text('$count guests', style: GoogleFonts.poppins(
              fontSize: 13, fontWeight: FontWeight.w700,
              color: const Color(0xFF0A4D6E)))),
      ]));
}

// ══════════════════════════════════════════════════════════════════════════════
// ALL CUSTOMERS TAB
// ══════════════════════════════════════════════════════════════════════════════
class _CustomerListTab extends StatefulWidget {
  final UserModel canteenUser;
  const _CustomerListTab({required this.canteenUser});
  @override State<_CustomerListTab> createState() => _CustomerListTabState();
}

class _CustomerListTabState extends State<_CustomerListTab> {
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
    final picked = await showDatePickerDialog(context, initial: _date);
    if (picked != null) { _date = picked; _load(); }
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(color: const Color(0xFF0A9396),
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
        child: Column(children: [
          GestureDetector(onTap: () => _pickDate(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(color: Colors.white,
                  borderRadius: BorderRadius.circular(10)),
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
            _fChip('All', 'all'), const SizedBox(width: 6),
            _fChip('Served', 'served'), const SizedBox(width: 6),
            _fChip('Not Served', 'notserved'),
          ]),
        ])),
      Container(color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(children: [
          Text('Total: ${_all.length}  ',
              style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textMedium)),
          Container(width: 6, height: 6,
              decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle)),
          Text(' ${_all.where((c) => c.canteenServed).length} served  ',
              style: GoogleFonts.poppins(fontSize: 12, color: AppColors.success)),
          Container(width: 6, height: 6,
              decoration: const BoxDecoration(color: AppColors.warning, shape: BoxShape.circle)),
          Text(' ${_all.where((c) => !c.canteenServed).length} pending',
              style: GoogleFonts.poppins(fontSize: 12, color: AppColors.warning)),
        ])),
      Expanded(child: _loading
        ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
        : _filtered.isEmpty
            ? Center(child: Text('No customers',
                style: GoogleFonts.poppins(color: AppColors.textLight)))
            : RefreshIndicator(onRefresh: _load, color: AppColors.primary,
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 20),
                  itemCount: _filtered.length,
                  itemBuilder: (_, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _CustomerDetailCard(customer: _filtered[i]))))),
    ]);
  }

  Widget _fChip(String label, String val) {
    final sel = _filter == val;
    return GestureDetector(
      onTap: () { _filter = val; _apply(); },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: sel ? Colors.white : Colors.white24,
          borderRadius: BorderRadius.circular(20)),
        child: Text(label, style: GoogleFonts.poppins(
            fontSize: 11, fontWeight: FontWeight.w600,
            color: sel ? const Color(0xFF0A9396) : Colors.white))));
  }
}
