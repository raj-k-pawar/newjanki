import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/booking_model.dart';
import '../../services/data_service.dart';
import '../../utils/app_theme.dart';
import 'qr_screen.dart';

class AddCustomerScreen extends StatefulWidget {
  final CustomerModel? existing; // non-null = edit mode
  const AddCustomerScreen({super.key, this.existing});

  @override
  State<AddCustomerScreen> createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends State<AddCustomerScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nameCtrl   = TextEditingController();
  final _cityCtrl   = TextEditingController();
  final _phoneCtrl  = TextEditingController();
  final _above10Ctrl       = TextEditingController(text: '0');
  final _amtAbove10Ctrl    = TextEditingController();
  final _between3Ctrl      = TextEditingController(text: '0');
  final _amtBetween3Ctrl   = TextEditingController();
  final _lunchGuestsCtrl   = TextEditingController(text: '0');
  final _breakfastGuestsCtrl = TextEditingController(text: '0');

  BatchType _batch   = BatchType.fullDay;
  PaymentMethod _pay = PaymentMethod.cash;
  bool _lunchDinner  = false;
  bool _breakfast    = false;
  bool _isLoading    = false;

  final DataService _ds = DataService();

  // Derived
  int    get _totalGuests  => (_intVal(_above10Ctrl) + _intVal(_between3Ctrl));
  double get _amtAbove10   => _intVal(_above10Ctrl) * _dblVal(_amtAbove10Ctrl);
  double get _amtBetween3  => _intVal(_between3Ctrl) * _dblVal(_amtBetween3Ctrl);
  double get _totalAmount  => _amtAbove10 + _amtBetween3;

  int    _intVal(TextEditingController c) => int.tryParse(c.text.trim()) ?? 0;
  double _dblVal(TextEditingController c) => double.tryParse(c.text.trim()) ?? 0;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) _populate(widget.existing!);
    _above10Ctrl.addListener(_recalc);
    _amtAbove10Ctrl.addListener(_recalc);
    _between3Ctrl.addListener(_recalc);
    _amtBetween3Ctrl.addListener(_recalc);
  }

  void _populate(CustomerModel c) {
    _nameCtrl.text  = c.name;
    _cityCtrl.text  = c.city;
    _phoneCtrl.text = c.phone;
    _batch = c.batchType;
    _above10Ctrl.text      = c.guestsAbove10.toString();
    _amtAbove10Ctrl.text   = c.amountPerPersonAbove10.toStringAsFixed(0);
    _between3Ctrl.text     = c.guestsBetween3to10.toString();
    _amtBetween3Ctrl.text  = c.amountPerPersonBetween3to10.toStringAsFixed(0);
    _lunchDinner  = c.foodOption.lunchDinner;
    _breakfast    = c.foodOption.breakfast;
    _lunchGuestsCtrl.text    = c.foodOption.lunchDinnerGuests.toString();
    _breakfastGuestsCtrl.text = c.foodOption.breakfastGuests.toString();
    _pay = c.paymentMethod;
  }

  void _recalc() => setState(() {});

  void _onBatchChanged(BatchType b) {
    setState(() {
      _batch = b;
      _amtAbove10Ctrl.text  = BatchPricing.getAdultPrice(b).toStringAsFixed(0);
      _amtBetween3Ctrl.text = BatchPricing.getChildPrice(b).toStringAsFixed(0);
    });
  }

  @override
  void dispose() {
    for (final c in [_nameCtrl, _cityCtrl, _phoneCtrl, _above10Ctrl,
        _amtAbove10Ctrl, _between3Ctrl, _amtBetween3Ctrl,
        _lunchGuestsCtrl, _breakfastGuestsCtrl]) c.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final isEdit = widget.existing != null;
    final id     = isEdit ? widget.existing!.id
                           : DateTime.now().millisecondsSinceEpoch.toString();
    final qrCode = isEdit ? widget.existing!.qrCode
                           : 'JAT-$id';

    final customer = CustomerModel(
      id: id,
      name:  _nameCtrl.text.trim(),
      city:  _cityCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      batchType: _batch,
      guestsAbove10:          _intVal(_above10Ctrl),
      amountPerPersonAbove10: _dblVal(_amtAbove10Ctrl),
      guestsBetween3to10:          _intVal(_between3Ctrl),
      amountPerPersonBetween3to10: _dblVal(_amtBetween3Ctrl),
      foodOption: FoodOption(
        lunchDinner:  _lunchDinner,
        breakfast:    _breakfast,
        lunchDinnerGuests:  _intVal(_lunchGuestsCtrl),
        breakfastGuests:    _intVal(_breakfastGuestsCtrl),
      ),
      totalGuests: _totalGuests,
      totalAmount: _totalAmount,
      paymentMethod: _pay,
      status: BookingStatus.confirmed,
      qrCode: qrCode,
      qrUsed: isEdit ? widget.existing!.qrUsed : false,
      visitDate:  DateTime.now(),
      createdAt: isEdit ? widget.existing!.createdAt : DateTime.now(),
    );

    if (isEdit) {
      await _ds.updateCustomer(customer);
    } else {
      await _ds.addCustomer(customer);
    }

    setState(() => _isLoading = false);
    if (!mounted) return;

    if (!isEdit) {
      // Show QR screen after save
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => QrScreen(customer: customer)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('✅ Customer updated!'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ));
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isEdit ? 'Edit Customer' : 'New Customer Booking',
          style: GoogleFonts.playfairDisplay(
              fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _section('Customer Details', Icons.person_outline),
              const SizedBox(height: 10),
              _card([
                _field(_nameCtrl,  'Customer Name', Icons.person_outline,
                    validator: _required),
                const SizedBox(height: 12),
                _field(_cityCtrl,  'City', Icons.location_city_outlined,
                    validator: _required),
                const SizedBox(height: 12),
                _field(_phoneCtrl, 'Mobile No', Icons.phone_outlined,
                    type: TextInputType.phone, validator: _required),
              ]),

              const SizedBox(height: 18),
              _section('Select Batch / Package', Icons.calendar_month_outlined),
              const SizedBox(height: 10),
              _batchSelector(),

              const SizedBox(height: 18),
              _section('Guest Count & Amount', Icons.groups_outlined),
              const SizedBox(height: 10),
              _card([
                // Above 10
                _subHead('👶 Children (3–10 yrs)'),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(child: _numField(_between3Ctrl,   'No. of Guests',    validator: _required)),
                  const SizedBox(width: 10),
                  Expanded(child: _numField(_amtBetween3Ctrl, 'Amount / Person ₹', validator: _required)),
                ]),
                const SizedBox(height: 6),
                _amountDisplay('Amount (3–10 yrs)', _amtBetween3),

                const Divider(height: 20),

                _subHead('🧑 Adults (10+ yrs)'),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(child: _numField(_above10Ctrl,    'No. of Guests',    validator: _required)),
                  const SizedBox(width: 10),
                  Expanded(child: _numField(_amtAbove10Ctrl, 'Amount / Person ₹', validator: _required)),
                ]),
                const SizedBox(height: 6),
                _amountDisplay('Amount (10+ yrs)', _amtAbove10),
              ]),

              const SizedBox(height: 18),
              _section('Food Options', Icons.restaurant_outlined),
              const SizedBox(height: 10),
              _card([
                CheckboxListTile(
                  value: _lunchDinner,
                  activeColor: AppColors.primary,
                  title: Text('🍛 Lunch / Dinner',
                      style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500)),
                  subtitle: _lunchDinner
                      ? Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: _numField(_lunchGuestsCtrl, 'No. of guests', validator: _required),
                        )
                      : null,
                  onChanged: (v) {
                    setState(() {
                      _lunchDinner = v!;
                      if (_lunchDinner) {
                        _lunchGuestsCtrl.text = _totalGuests.toString();
                      }
                    });
                  },
                  contentPadding: EdgeInsets.zero,
                ),
                CheckboxListTile(
                  value: _breakfast,
                  activeColor: AppColors.primary,
                  title: Text('🍽️ Breakfast',
                      style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500)),
                  subtitle: _breakfast
                      ? Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: _numField(_breakfastGuestsCtrl, 'No. of guests', validator: _required),
                        )
                      : null,
                  onChanged: (v) {
                    setState(() {
                      _breakfast = v!;
                      if (_breakfast) {
                        _breakfastGuestsCtrl.text = _totalGuests.toString();
                      }
                    });
                  },
                  contentPadding: EdgeInsets.zero,
                ),
              ]),

              const SizedBox(height: 18),
              _section('Summary', Icons.receipt_long_outlined),
              const SizedBox(height: 10),
              _summaryCard(),

              const SizedBox(height: 18),
              _section('Payment Mode', Icons.payment_outlined),
              const SizedBox(height: 10),
              _card([
                Row(children: [
                  Expanded(child: _payChip('💵  Cash',   PaymentMethod.cash)),
                  const SizedBox(width: 10),
                  Expanded(child: _payChip('📱  Online', PaymentMethod.online)),
                ]),
              ]),

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 4,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)
                      : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(isEdit ? Icons.save_outlined : Icons.qr_code_2,
                              color: Colors.white, size: 22),
                          const SizedBox(width: 10),
                          Text(
                            isEdit ? 'Update Customer' : 'Save & Generate QR',
                            style: GoogleFonts.poppins(
                                fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                          ),
                        ]),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // ── Batch Selector ─────────────────────────────────────────
  Widget _batchSelector() {
    return Column(
      children: BatchType.values.map((b) {
        final isSelected = _batch == b;
        return GestureDetector(
          onTap: () => _onBatchChanged(b),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? AppColors.primary : Colors.grey.shade200,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected ? [BoxShadow(
                color: AppColors.primary.withOpacity(0.25),
                blurRadius: 10, offset: const Offset(0, 4),
              )] : [BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 6, offset: const Offset(0, 2),
              )],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _batchTitle(b),
                  style: GoogleFonts.poppins(
                    fontSize: 13, fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _batchDetail(b),
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: isSelected ? Colors.white70 : AppColors.textLight,
                  ),
                ),
                const SizedBox(height: 6),
                Row(children: [
                  _priceChip('👶 ₹${BatchPricing.getChildPrice(b).toStringAsFixed(0)}',
                      isSelected),
                  const SizedBox(width: 8),
                  _priceChip('🧑 ₹${BatchPricing.getAdultPrice(b).toStringAsFixed(0)}',
                      isSelected),
                ]),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _priceChip(String label, bool selected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: selected ? Colors.white.withOpacity(0.2) : AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: GoogleFonts.poppins(
            fontSize: 11, fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.primary,
          )),
    );
  }

  String _batchTitle(BatchType b) {
    switch (b) {
      case BatchType.halfDayMorning: return '🌞 सकाळी हाफ डे पॅकेज';
      case BatchType.halfDayEvening: return '🌅 सायंकाळी हाफ डे पॅकेज';
      case BatchType.fullDay:        return '🌟 फुल डे पॅकेज';
      case BatchType.acDeluxeRoom:   return '🏨 AC डिलक्स रूम पॅकेज ❄️';
      case BatchType.nonAcRoom:      return '🏠 Non AC रूम पॅकेज 🌿';
    }
  }

  String _batchDetail(BatchType b) {
    switch (b) {
      case BatchType.halfDayMorning:
        return '🕙 10:00 ते 15:00  •  ☕ चहा  •  🍽️ नाश्ता  •  🍛 जेवण';
      case BatchType.halfDayEvening:
        return '🕒 15:00 ते 20:00  •  ☕ चहा  •  🍽️ नाश्ता  •  🍛 जेवण';
      case BatchType.fullDay:
        return '🕙 10:00 ते 18:00  •  ☕ चहा  •  🍽️ नाश्ता  •  🍛 जेवण';
      case BatchType.acDeluxeRoom:
        return '🕙 10:00 – दुसऱ्या दिवशी 09:30  •  🍽️ 2 वेळ जेवण  •  🥪 3 वेळ चहा व नाश्ता';
      case BatchType.nonAcRoom:
        return '🕙 10:00 – दुसऱ्या दिवशी 09:30  •  🍽️ 2 वेळ जेवण  •  🥪 3 वेळ चहा व नाश्ता';
    }
  }

  // ── Summary Card ───────────────────────────────────────────
  Widget _summaryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryDark, AppColors.primary],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(
          color: AppColors.primary.withOpacity(0.35),
          blurRadius: 12, offset: const Offset(0, 6),
        )],
      ),
      child: Column(children: [
        _sumRow('Total Guests',  _totalGuests.toString(),  isBig: true),
        const SizedBox(height: 6),
        _sumRow('Amount (10+ yrs)',  '₹${_amtAbove10.toStringAsFixed(0)}'),
        _sumRow('Amount (3–10 yrs)', '₹${_amtBetween3.toStringAsFixed(0)}'),
        const Divider(color: Colors.white30, height: 16),
        _sumRow('Pay Total Amount',  '₹${_totalAmount.toStringAsFixed(0)}', isBig: true),
      ]),
    );
  }

  Widget _sumRow(String label, String value, {bool isBig = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: GoogleFonts.poppins(
                fontSize: isBig ? 14 : 12,
                fontWeight: isBig ? FontWeight.w600 : FontWeight.w400,
                color: Colors.white70)),
        Text(value,
            style: GoogleFonts.poppins(
                fontSize: isBig ? 20 : 14,
                fontWeight: FontWeight.w700,
                color: Colors.white)),
      ],
    );
  }

  Widget _amountDisplay(String label, double amount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 12, color: AppColors.textMedium, fontWeight: FontWeight.w500)),
          Text('₹${amount.toStringAsFixed(0)}',
              style: GoogleFonts.poppins(
                  fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary)),
        ],
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────
  Widget _section(String title, IconData icon) => Row(children: [
        Icon(icon, color: AppColors.primary, size: 18),
        const SizedBox(width: 8),
        Text(title,
            style: GoogleFonts.poppins(
                fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark)),
      ]);

  Widget _card(List<Widget> children) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: children),
      );

  Widget _subHead(String t) => Text(t,
      style: GoogleFonts.poppins(
          fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textDark));

  Widget _field(TextEditingController ctrl, String label, IconData icon,
      {TextInputType? type, String? Function(String?)? validator}) =>
      TextFormField(
        controller: ctrl,
        keyboardType: type,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
        ),
        validator: validator,
      );

  Widget _numField(TextEditingController ctrl, String label,
      {String? Function(String?)? validator}) =>
      TextFormField(
        controller: ctrl,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
        decoration: InputDecoration(labelText: label),
        validator: validator,
      );

  Widget _payChip(String label, PaymentMethod val) {
    final sel = _pay == val;
    return GestureDetector(
      onTap: () => setState(() => _pay = val),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: sel ? AppColors.primary : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: sel ? AppColors.primary : Colors.grey.shade300),
        ),
        child: Center(
          child: Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: sel ? Colors.white : AppColors.textMedium)),
        ),
      ),
    );
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Required' : null;
}
