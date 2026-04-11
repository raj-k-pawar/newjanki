import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/models.dart';
import '../../services/storage_service.dart';
import '../../utils/app_theme.dart';
import '../shared/widgets.dart';

// ══════════════════════════════════════════════════════════════════════════════
// STEP 1 – Package Selector (only shown when adding NEW customer)
// ══════════════════════════════════════════════════════════════════════════════
class AddCustomerScreen extends StatefulWidget {
  final UserModel managerUser;
  final CustomerModel? existing;
  const AddCustomerScreen({super.key, required this.managerUser, this.existing});

  @override
  State<AddCustomerScreen> createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends State<AddCustomerScreen> {
  List<PackageModel> _packages = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _packages = await StorageService.instance.getPackages();
    setState(() => _loading = false);
    // If editing, skip package selection — go directly to form
    if (widget.existing != null && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => BookingFormScreen(
            managerUser: widget.managerUser,
            pkg: null,
            packages: _packages,
            existing: widget.existing,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // While loading for edit mode, show spinner
    if (widget.existing != null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Select Package'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _packages.isEmpty
              ? Center(
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.category_outlined, size: 60, color: Colors.grey.shade300),
                    const SizedBox(height: 14),
                    Text('No packages configured',
                        style: GoogleFonts.poppins(color: AppColors.textLight, fontSize: 14)),
                    Text('Ask the owner to add packages first',
                        style: GoogleFonts.poppins(color: AppColors.textLight, fontSize: 12)),
                  ]),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Choose a Package',
                          style: GoogleFonts.poppins(fontSize: 18,
                              fontWeight: FontWeight.w700, color: AppColors.textDark)),
                      Text('Tap to select and continue',
                          style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textLight)),
                      const SizedBox(height: 16),
                      ..._packages.map((pkg) => _pkgCard(context, pkg)),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
    );
  }

  Widget _pkgCard(BuildContext context, PackageModel pkg) {
    final foods = <String>[];
    if (pkg.breakfast) foods.add('Breakfast');
    if (pkg.lunch)     foods.add('Lunch');
    if (pkg.snacks)    foods.add('Snacks');
    if (pkg.dinner)    foods.add('Dinner');

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BookingFormScreen(
            managerUser: widget.managerUser,
            pkg: pkg,
            packages: _packages,
          ),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06),
              blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Column(children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primaryDark, AppColors.primary],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16), topRight: Radius.circular(16),
              ),
            ),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(pkg.name, style: GoogleFonts.poppins(fontSize: 14,
                    fontWeight: FontWeight.w700, color: Colors.white)),
                const SizedBox(height: 3),
                Text(pkg.timeSlot, style: GoogleFonts.poppins(
                    fontSize: 11, color: Colors.white70)),
              ])),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.white24,
                    borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.arrow_forward, color: Colors.white, size: 18)),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(children: [
              if (foods.isNotEmpty)
                Row(children: [
                  const Icon(Icons.restaurant_outlined, size: 14, color: AppColors.textLight),
                  const SizedBox(width: 6),
                  Text(foods.join(' • '), style: GoogleFonts.poppins(
                      fontSize: 12, color: AppColors.textMedium)),
                ]),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: _priceBox('Children (3–10)', 'Rs.${pkg.childPrice.toStringAsFixed(0)}', const Color(0xFFF4A261))),
                const SizedBox(width: 10),
                Expanded(child: _priceBox('Adults (10+)', 'Rs.${pkg.adultPrice.toStringAsFixed(0)}', AppColors.primary)),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _priceBox(String label, String price, Color color) => Container(
    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
    decoration: BoxDecoration(color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: GoogleFonts.poppins(fontSize: 10, color: AppColors.textLight)),
      Text(price, style: GoogleFonts.poppins(fontSize: 16,
          fontWeight: FontWeight.w700, color: color)),
      Text('per person', style: GoogleFonts.poppins(fontSize: 9, color: AppColors.textLight)),
    ]),
  );
}

// ══════════════════════════════════════════════════════════════════════════════
// STEP 2 – Booking Form
// ══════════════════════════════════════════════════════════════════════════════
class BookingFormScreen extends StatefulWidget {
  final UserModel managerUser;
  final PackageModel? pkg;
  final CustomerModel? existing;
  final List<PackageModel> packages;

  const BookingFormScreen({
    super.key,
    required this.managerUser,
    required this.pkg,
    required this.packages,
    this.existing,
  });

  @override
  State<BookingFormScreen> createState() => _BookingFormScreenState();
}

class _BookingFormScreenState extends State<BookingFormScreen> {
  final _formKey  = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _phoneCtrl= TextEditingController();
  final _a10Ctrl  = TextEditingController(text: '0');
  final _aRCtrl   = TextEditingController();
  final _c3Ctrl   = TextEditingController(text: '0');
  final _cRCtrl   = TextEditingController();
  final _brCtrl   = TextEditingController(text: '0');
  final _luCtrl   = TextEditingController(text: '0');
  final _snCtrl   = TextEditingController(text: '0');
  final _diCtrl   = TextEditingController(text: '0');
  final _advCtrl  = TextEditingController(text: '0');

  PackageModel? _pkg;
  PaymentMode _pay = PaymentMode.cash;
  DateTime? _checkIn;
  DateTime? _checkOut;
  bool _loading = false;

  int    get _aC  => int.tryParse(_a10Ctrl.text) ?? 0;
  int    get _cC  => int.tryParse(_c3Ctrl.text) ?? 0;
  int    get _tot => _aC + _cC;
  double get _aR  => double.tryParse(_aRCtrl.text) ?? 0;
  double get _cR  => double.tryParse(_cRCtrl.text) ?? 0;
  double get _aA  => _aC * _aR;
  double get _cA  => _cC * _cR;
  double get _base=> _aA + _cA;
  double get _adv => double.tryParse(_advCtrl.text) ?? 0;

  double get _foodDed {
    if (_pkg == null) return 0;
    double d = 0;
    if (_pkg!.breakfast) d += (_tot - (int.tryParse(_brCtrl.text) ?? 0)).clamp(0,999) * 50;
    if (_pkg!.lunch)     d += (_tot - (int.tryParse(_luCtrl.text) ?? 0)).clamp(0,999) * 100;
    if (_pkg!.snacks)    d += (_tot - (int.tryParse(_snCtrl.text) ?? 0)).clamp(0,999) * 50;
    if (_pkg!.dinner)    d += (_tot - (int.tryParse(_diCtrl.text) ?? 0)).clamp(0,999) * 100;
    return d;
  }

  double get _payTotal => (_base - _foodDed - _adv).clamp(0, double.infinity);

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _populate(widget.existing!);
    } else if (widget.pkg != null) {
      _applyPkg(widget.pkg!);
    }
    for (final c in [_a10Ctrl, _aRCtrl, _c3Ctrl, _cRCtrl,
        _brCtrl, _luCtrl, _snCtrl, _diCtrl, _advCtrl]) {
      c.addListener(() => setState(() {}));
    }
  }

  void _populate(CustomerModel c) {
    _nameCtrl.text = c.name;
    _cityCtrl.text = c.city;
    _phoneCtrl.text= c.phone;
    _a10Ctrl.text  = c.adultsCount.toString();
    _aRCtrl.text   = c.adultRate.toStringAsFixed(0);
    _c3Ctrl.text   = c.childrenCount.toString();
    _cRCtrl.text   = c.childRate.toStringAsFixed(0);
    _brCtrl.text   = c.food.breakfast.toString();
    _luCtrl.text   = c.food.lunch.toString();
    _snCtrl.text   = c.food.snacks.toString();
    _diCtrl.text   = c.food.dinner.toString();
    _advCtrl.text  = c.advance.toStringAsFixed(0);
    _pay = c.paymentMode;
    _checkIn  = c.checkInDate;
    _checkOut = c.checkOutDate;
    // Find package from list — no error if not found (edit without pkg change)
    for (final p in widget.packages) {
      if (p.id == c.packageId) { _pkg = p; break; }
    }
    // If pkg not found in list (deleted), create a stub so food options still show
    if (_pkg == null && c.packageId.isNotEmpty) {
      _pkg = PackageModel(
        id: c.packageId, name: c.packageName, timeSlot: '',
        breakfast: c.food.breakfast > 0, lunch: c.food.lunch > 0,
        snacks: c.food.snacks > 0, dinner: c.food.dinner > 0,
        adultPrice: c.adultRate, childPrice: c.childRate,
      );
    }
  }

  void _applyPkg(PackageModel pkg) {
    _pkg = pkg;
    _aRCtrl.text = pkg.adultPrice.toStringAsFixed(0);
    _cRCtrl.text = pkg.childPrice.toStringAsFixed(0);
  }

  void _syncFood() {
    if (_pkg == null) return;
    final t = _tot.toString();
    setState(() {
      if (_pkg!.breakfast) _brCtrl.text = t;
      if (_pkg!.lunch)     _luCtrl.text = t;
      if (_pkg!.snacks)    _snCtrl.text = t;
      if (_pkg!.dinner)    _diCtrl.text = t;
    });
  }

  @override
  void dispose() {
    for (final c in [_nameCtrl, _cityCtrl, _phoneCtrl, _a10Ctrl, _aRCtrl,
        _c3Ctrl, _cRCtrl, _brCtrl, _luCtrl, _snCtrl, _diCtrl, _advCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final isEdit = widget.existing != null;
    final id = isEdit ? widget.existing!.id
        : DateTime.now().millisecondsSinceEpoch.toString();

    final customer = CustomerModel(
      id: id,
      name:          _nameCtrl.text.trim(),
      city:          _cityCtrl.text.trim(),
      phone:         _phoneCtrl.text.trim(),
      packageId:     _pkg?.id ?? widget.existing?.packageId ?? '',
      packageName:   _pkg?.name ?? widget.existing?.packageName ?? '',
      adultsCount:   _aC,
      childrenCount: _cC,
      adultRate:     _aR,
      childRate:     _cR,
      food: FoodCounts(
        breakfast: int.tryParse(_brCtrl.text) ?? 0,
        lunch:     int.tryParse(_luCtrl.text) ?? 0,
        snacks:    int.tryParse(_snCtrl.text) ?? 0,
        dinner:    int.tryParse(_diCtrl.text) ?? 0,
      ),
      advance:         _adv,
      foodDeductionAmt:_foodDed,
      paymentMode:     _pay,
      visitDate:       isEdit ? widget.existing!.visitDate : DateTime.now(),
      createdAt:       isEdit ? widget.existing!.createdAt : DateTime.now(),
      qrCode:          isEdit ? widget.existing!.qrCode : 'JAT-$id',
      managerId:       widget.managerUser.id,
      managerName:     widget.managerUser.fullName,
      qrUsed:          isEdit ? widget.existing!.qrUsed : false,
      canteenServed:   isEdit ? widget.existing!.canteenServed : false,
      checkInDate:  _checkIn,
      checkOutDate: _checkOut,
    );

    await StorageService.instance.saveCustomer(customer);
    setState(() => _loading = false);
    if (!mounted) return;

    if (isEdit) {
      showSnack(context, 'Customer updated successfully!');
      Navigator.pop(context, true);
    } else {
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => QrConfirmScreen(customer: customer)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Booking' : 'New Booking'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Package banner
              if (_pkg != null) _pkgBanner(_pkg!),

              // Customer Info
              const SectionHeader('Customer Information', icon: Icons.person_outline),
              WhiteCard(child: Column(children: [
                _tf(_nameCtrl, 'Customer Name', Icons.person_outline, req: true),
                const SizedBox(height: 12),
                _tf(_cityCtrl, 'City', Icons.location_city_outlined),
                const SizedBox(height: 12),
                _tf(_phoneCtrl, 'Mobile Number', Icons.phone_outlined,
                    type: TextInputType.phone, req: true),
              ])),

              // Adults
              const SectionHeader('Adults (10+ years)', icon: Icons.person_outlined),
              WhiteCard(child: Column(children: [
                Row(children: [
                  Expanded(child: _nf(_a10Ctrl, 'No. of Guests',
                      onChange: (_) => _syncFood())),
                  const SizedBox(width: 12),
                  Expanded(child: _nf(_aRCtrl, 'Amount / Person (Rs.)')),
                ]),
                const SizedBox(height: 10),
                _amtRow('Adults Amount', _aA,
                    calc: '${_aC} × Rs.${_aR.toStringAsFixed(0)}',
                    color: const Color(0xFF4361EE)),
              ])),

              // Children
              const SectionHeader('Children (3–10 years)', icon: Icons.child_care_outlined),
              WhiteCard(child: Column(children: [
                Row(children: [
                  Expanded(child: _nf(_c3Ctrl, 'No. of Guests',
                      onChange: (_) => _syncFood())),
                  const SizedBox(width: 12),
                  Expanded(child: _nf(_cRCtrl, 'Amount / Person (Rs.)')),
                ]),
                const SizedBox(height: 10),
                _amtRow('Children Amount', _cA,
                    calc: '${_cC} × Rs.${_cR.toStringAsFixed(0)}',
                    color: const Color(0xFFF4A261)),
              ])),

              // Food Options
              if (_pkg != null && (_pkg!.breakfast || _pkg!.lunch || _pkg!.snacks || _pkg!.dinner)) ...[
                const SectionHeader('Food Options', icon: Icons.restaurant_outlined),
                WhiteCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: AppColors.warning.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8)),
                    child: Text(
                      'Reduce guest count below total to deduct:\n'
                      'Breakfast / Snacks = -Rs.50/guest   Lunch / Dinner = -Rs.100/guest',
                      style: GoogleFonts.poppins(fontSize: 11, color: AppColors.warning)),
                  ),
                  const SizedBox(height: 12),
                  if (_pkg!.breakfast) _foodRow('🍽️  Breakfast', _brCtrl, 50),
                  if (_pkg!.lunch)     _foodRow('🍛  Lunch',     _luCtrl, 100),
                  if (_pkg!.snacks)    _foodRow('☕  Snacks',    _snCtrl, 50),
                  if (_pkg!.dinner)    _foodRow('🌙  Dinner',    _diCtrl, 100),
                  if (_foodDed > 0) ...[
                    const Divider(height: 16),
                    _deductRow('Total Food Deduction', _foodDed),
                  ],
                ])),
              ],

              // Advance
              const SectionHeader('Advance Payment', icon: Icons.payments_outlined),
              WhiteCard(child: Column(children: [
                _nf(_advCtrl, 'Advance Amount (Rs.)'),
                if (_adv > 0) ...[
                  const SizedBox(height: 10),
                  _deductRow('Advance Deduction', _adv),
                ],
              ])),

              // Summary
              const SectionHeader('Payment Summary', icon: Icons.receipt_long_outlined),
              _summaryCard(),

              // Payment Mode
              // ── Stay Dates (only for stay packages) ──────────────────
              if (_pkg != null && _pkg!.isStay) ...[
                const SectionHeader('Stay Dates', icon: Icons.hotel_outlined),
                WhiteCard(child: Column(children: [
                  _datePicker(
                    label: 'Check-In Date',
                    icon: Icons.login_outlined,
                    date: _checkIn,
                    onPick: () async {
                      final d = await showDatePickerDialog(context,
                          initial: _checkIn ?? DateTime.now());
                      if (d != null) setState(() {
                        _checkIn = d;
                        // Auto-set checkout to next day if not set or before check-in
                        if (_checkOut == null || !_checkOut!.isAfter(d)) {
                          _checkOut = d.add(const Duration(days: 1));
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  _datePicker(
                    label: 'Check-Out Date',
                    icon: Icons.logout_outlined,
                    date: _checkOut,
                    onPick: () async {
                      final d = await showDatePickerDialog(context,
                          initial: _checkOut ?? DateTime.now().add(const Duration(days: 1)));
                      if (d != null) {
                        if (_checkIn != null && !d.isAfter(_checkIn!)) {
                          showSnack(context,
                              'Check-out must be after check-in date', error: true);
                          return;
                        }
                        setState(() => _checkOut = d);
                      }
                    },
                  ),
                  if (_checkIn != null && _checkOut != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.07),
                        borderRadius: BorderRadius.circular(10)),
                      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text('Total Stay',
                            style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textMedium)),
                        Text(
                          '${_checkOut!.difference(_checkIn!).inDays.abs()} Night(s)',
                          style: GoogleFonts.poppins(fontSize: 15,
                              fontWeight: FontWeight.w700, color: AppColors.primary)),
                      ]),
                    ),
                  ],
                ])),
              ],
              const SectionHeader('Payment Mode', icon: Icons.payment_outlined),
              WhiteCard(child: Row(children: [
                Expanded(child: _payChip('💵  Cash', PaymentMode.cash)),
                const SizedBox(width: 12),
                Expanded(child: _payChip('📱  Online', PaymentMode.online)),
              ])),

              const SizedBox(height: 24),
              PrimaryButton(
                label: isEdit ? 'Update Booking' : 'Save & Generate QR',
                icon: isEdit ? Icons.save_outlined : Icons.qr_code_2,
                loading: _loading,
                onTap: _save,
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pkgBanner(PackageModel pkg) => Container(
    margin: const EdgeInsets.only(bottom: 14),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
          colors: [AppColors.primaryDark, AppColors.primary],
          begin: Alignment.topLeft, end: Alignment.bottomRight),
      borderRadius: BorderRadius.circular(14)),
    child: Row(children: [
      const Icon(Icons.category_outlined, color: Colors.white, size: 22),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Selected Package', style: GoogleFonts.poppins(fontSize: 10, color: Colors.white70)),
        Text(pkg.name, style: GoogleFonts.poppins(fontSize: 13,
            fontWeight: FontWeight.w700, color: Colors.white)),
        if (pkg.timeSlot.isNotEmpty)
          Text(pkg.timeSlot, style: GoogleFonts.poppins(fontSize: 10, color: Colors.white70)),
      ])),
    ]),
  );

  Widget _amtRow(String label, double amt, {String calc = '', Color color = AppColors.primary}) =>
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(10)),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textMedium)),
          if (calc.isNotEmpty)
            Text(calc, style: GoogleFonts.poppins(fontSize: 10, color: AppColors.textLight)),
        ])),
        Text('Rs.${amt.toStringAsFixed(0)}', style: GoogleFonts.poppins(
            fontSize: 18, fontWeight: FontWeight.w700, color: color)),
      ]));

  Widget _deductRow(String label, double amt) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: GoogleFonts.poppins(fontSize: 12, color: AppColors.error)),
      Text('- Rs.${amt.toStringAsFixed(0)}', style: GoogleFonts.poppins(
          fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.error)),
    ]);

  Widget _foodRow(String label, TextEditingController ctrl, int rate) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(children: [
      Expanded(flex: 3, child: Text(label,
          style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textDark))),
      Expanded(flex: 2, child: TextFormField(
        controller: ctrl,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: const InputDecoration(labelText: 'Guests'),
        onChanged: (_) => setState(() {}),
      )),
      const SizedBox(width: 8),
      Text('-Rs.$rate/g', style: GoogleFonts.poppins(fontSize: 11, color: AppColors.error)),
    ]));

  Widget _summaryCard() => Container(
    margin: const EdgeInsets.only(bottom: 14),
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
          colors: [Color(0xFF1B4332), Color(0xFF2D6A4F)],
          begin: Alignment.topLeft, end: Alignment.bottomRight),
      borderRadius: BorderRadius.circular(16),
      boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.35),
          blurRadius: 12, offset: const Offset(0, 6))]),
    child: Column(children: [
      _sRow('Total Guests',   '$_tot'),
      _sRow('Adults Amount',  'Rs.${_aA.toStringAsFixed(0)}'),
      _sRow('Children Amount','Rs.${_cA.toStringAsFixed(0)}'),
      const Divider(color: Colors.white30, height: 14),
      _sRow('Sub Total',      'Rs.${_base.toStringAsFixed(0)}'),
      if (_foodDed > 0) _sRow('Food Deduction', '- Rs.${_foodDed.toStringAsFixed(0)}',
          valueColor: const Color(0xFFFFB3B3)),
      if (_adv > 0)    _sRow('Advance',        '- Rs.${_adv.toStringAsFixed(0)}',
          valueColor: const Color(0xFFFFB3B3)),
      const Divider(color: Colors.white30, height: 14),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('PAY TOTAL', style: GoogleFonts.poppins(fontSize: 14,
            fontWeight: FontWeight.w700, color: Colors.white70)),
        Text('Rs.${_payTotal.toStringAsFixed(0)}', style: GoogleFonts.poppins(
            fontSize: 28, fontWeight: FontWeight.w700, color: Colors.white)),
      ]),
    ]));

  Widget _sRow(String l, String v, {Color? valueColor}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(l, style: GoogleFonts.poppins(fontSize: 13, color: Colors.white70)),
      Text(v, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600,
          color: valueColor ?? Colors.white)),
    ]));

  Widget _tf(TextEditingController c, String label, IconData icon,
      {TextInputType? type, bool req = false}) =>
    TextFormField(controller: c, keyboardType: type,
      decoration: InputDecoration(labelText: label,
          prefixIcon: Icon(icon, color: AppColors.primary, size: 20)),
      validator: req ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null : null);

  Widget _nf(TextEditingController c, String label, {void Function(String)? onChange}) =>
    TextFormField(controller: c,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
      decoration: InputDecoration(labelText: label),
      onChanged: onChange);

  Widget _datePicker({
    required String label,
    required IconData icon,
    required DateTime? date,
    required VoidCallback onPick,
  }) {
    final fmt = DateFormat('dd MMM yyyy');
    return GestureDetector(
      onTap: onPick,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: date != null
                ? AppColors.primary.withOpacity(0.5)
                : Colors.grey.shade300),
        ),
        child: Row(children: [
          Icon(icon,
              color: date != null ? AppColors.primary : AppColors.textLight,
              size: 20),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: GoogleFonts.poppins(
                fontSize: 11, color: AppColors.textLight)),
            const SizedBox(height: 2),
            Text(
              date != null ? fmt.format(date) : 'Tap to select date',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: date != null ? FontWeight.w600 : FontWeight.w400,
                color: date != null ? AppColors.textDark : AppColors.textLight),
            ),
          ])),
          Icon(Icons.calendar_today,
              size: 16,
              color: date != null ? AppColors.primary : Colors.grey.shade400),
        ]),
      ),
    );
  }

  Widget _payChip(String label, PaymentMode val) {
    final sel = _pay == val;
    return GestureDetector(
      onTap: () => setState(() => _pay = val),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: sel ? AppColors.primary : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: sel ? AppColors.primary : Colors.grey.shade300)),
        child: Center(child: Text(label, style: GoogleFonts.poppins(
            fontSize: 14, fontWeight: FontWeight.w600,
            color: sel ? Colors.white : AppColors.textMedium)))));
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// QR Confirm Screen
// ══════════════════════════════════════════════════════════════════════════════
class QrConfirmScreen extends StatelessWidget {
  final CustomerModel customer;
  const QrConfirmScreen({super.key, required this.customer});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Booking Confirmed'),
        leading: IconButton(
          icon: const Icon(Icons.home_outlined, color: Colors.white),
          onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          // Success banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.success.withOpacity(0.4))),
            child: Row(children: [
              Container(width: 44, height: 44,
                decoration: BoxDecoration(color: AppColors.success,
                    borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.check, color: Colors.white, size: 26)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Booking Confirmed!', style: GoogleFonts.poppins(fontSize: 15,
                    fontWeight: FontWeight.w700, color: AppColors.success)),
                Text('QR code generated for canteen – valid today only',
                    style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textMedium)),
              ])),
            ])),
          const SizedBox(height: 20),

          // QR
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07),
                    blurRadius: 12, offset: const Offset(0, 4))]),
            child: Column(children: [
              Text('Canteen Food QR Code', style: GoogleFonts.poppins(
                  fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textMedium)),
              Text('Valid today only  •  Single use',
                  style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textLight)),
              const SizedBox(height: 16),
              QrWidget(data: customer.qrCode, size: 180),
              const SizedBox(height: 12),
              Text(customer.qrCode, style: GoogleFonts.poppins(
                  fontSize: 13, fontWeight: FontWeight.w600,
                  letterSpacing: 1.2, color: AppColors.textDark)),
            ])),
          const SizedBox(height: 20),

          // Breakdown
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05),
                    blurRadius: 8, offset: const Offset(0, 3))]),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Booking Summary', style: GoogleFonts.poppins(
                  fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark)),
              const SizedBox(height: 14),
              _ir('Name',    customer.name),
              _ir('City',    customer.city),
              _ir('Phone',   customer.phone),
              _ir('Package', customer.packageName),
              const Divider(height: 16),
              _ir('Adults',   '${customer.adultsCount} x Rs.${customer.adultRate.toStringAsFixed(0)} = Rs.${customer.adultAmount.toStringAsFixed(0)}'),
              _ir('Children', '${customer.childrenCount} x Rs.${customer.childRate.toStringAsFixed(0)} = Rs.${customer.childAmount.toStringAsFixed(0)}'),
                  if (customer.checkInDate != null) ...[
                    const Divider(height: 14),
                    _ir('Check-In',  DateFormat('dd MMM yyyy').format(customer.checkInDate!)),
                    if (customer.checkOutDate != null)
                      _ir('Check-Out', DateFormat('dd MMM yyyy').format(customer.checkOutDate!)),
                    _ir('Stay', '\${customer.stayNights} Night(s)'),
                  ],
              const Divider(height: 12),
              _ir('Sub Total', 'Rs.${customer.baseAmount.toStringAsFixed(0)}'),
              if (customer.foodDeductionAmt > 0)
                _ir('Food Deduction', '- Rs.${customer.foodDeductionAmt.toStringAsFixed(0)}',
                    valueColor: AppColors.error),
              if (customer.advance > 0)
                _ir('Advance', '- Rs.${customer.advance.toStringAsFixed(0)}',
                    valueColor: AppColors.error),
              const Divider(height: 12),
              // PAY TOTAL highlighted
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10)),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('PAY TOTAL', style: GoogleFonts.poppins(
                      fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary)),
                  Text('Rs.${customer.totalAmount.toStringAsFixed(0)}',
                      style: GoogleFonts.poppins(fontSize: 24,
                          fontWeight: FontWeight.w700, color: AppColors.primary)),
                ])),
              const SizedBox(height: 8),
              _ir('Payment', customer.paymentMode == PaymentMode.cash ? 'Cash' : 'Online'),
              _ir('Manager', customer.managerName),
            ])),
          const SizedBox(height: 24),

          Row(children: [
            Expanded(child: OutlinedButton.icon(
              onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
              icon: const Icon(Icons.dashboard_outlined),
              label: const Text('Dashboard'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            )),
            const SizedBox(width: 12),
            Expanded(child: ElevatedButton.icon(
              onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
              icon: const Icon(Icons.person_add_outlined, color: Colors.white, size: 18),
              label: Text('Add Another', style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            )),
          ]),
          const SizedBox(height: 30),
        ]),
      ),
    );
  }

  Widget _ir(String label, String value, {Color? valueColor}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(width: 110, child: Text(label,
          style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textLight))),
      Expanded(child: Text(value, style: GoogleFonts.poppins(
          fontSize: 12, fontWeight: FontWeight.w600,
          color: valueColor ?? AppColors.textDark))),
    ]));
}
