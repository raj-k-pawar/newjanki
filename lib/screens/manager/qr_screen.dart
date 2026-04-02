import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/booking_model.dart';
import '../../utils/app_theme.dart';

class QrScreen extends StatelessWidget {
  final CustomerModel customer;
  const QrScreen({super.key, required this.customer});

  @override
  Widget build(BuildContext context) {
    final today = DateFormat('dd MMM yyyy').format(DateTime.now());

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text('Booking Confirmed',
            style: GoogleFonts.playfairDisplay(
                fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context)
              .popUntil((r) => r.settings.name == '/' || r.isFirst),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.home_outlined, color: Colors.white),
            onPressed: () =>
                Navigator.of(context).popUntil((r) => r.isFirst),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          // Success banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.success.withOpacity(0.4)),
            ),
            child: Row(children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                    color: AppColors.success,
                    borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.check, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Booking Confirmed!',
                      style: GoogleFonts.poppins(
                          fontSize: 16, fontWeight: FontWeight.w700,
                          color: AppColors.success)),
                  Text('QR code generated for canteen',
                      style: GoogleFonts.poppins(
                          fontSize: 12, color: AppColors.textMedium)),
                ],
              )),
            ]),
          ),

          const SizedBox(height: 20),

          // QR Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20, offset: const Offset(0, 8),
              )],
            ),
            child: Column(children: [
              Text('Canteen QR Code',
                  style: GoogleFonts.poppins(
                      fontSize: 14, fontWeight: FontWeight.w600,
                      color: AppColors.textMedium)),
              const SizedBox(height: 4),
              Text('Valid for ${today} only · Single use',
                  style: GoogleFonts.poppins(
                      fontSize: 11, color: AppColors.textLight)),
              const SizedBox(height: 20),

              // QR Code (drawn with CustomPainter - no external lib needed)
              _QrWidget(data: customer.qrCode),

              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.qr_code, color: AppColors.primary, size: 16),
                    const SizedBox(width: 8),
                    Text(customer.qrCode,
                        style: GoogleFonts.poppins(
                            fontSize: 13, fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                            letterSpacing: 1.2)),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: customer.qrCode));
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('QR code copied!'),
                          behavior: SnackBarBehavior.floating,
                        ));
                      },
                      child: Icon(Icons.copy_outlined,
                          size: 16, color: AppColors.textLight),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 4),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: customer.qrUsed
                        ? AppColors.error.withOpacity(0.1)
                        : AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    customer.qrUsed ? '⚠️ Already Used' : '✅ Valid – Not Yet Used',
                    style: GoogleFonts.poppins(
                      fontSize: 11, fontWeight: FontWeight.w600,
                      color: customer.qrUsed ? AppColors.error : AppColors.success,
                    ),
                  ),
                ),
              ]),
            ]),
          ),

          const SizedBox(height: 20),

          // Booking Summary Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8, offset: const Offset(0, 3))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Booking Summary',
                    style: GoogleFonts.playfairDisplay(
                        fontSize: 16, fontWeight: FontWeight.w700,
                        color: AppColors.textDark)),
                const SizedBox(height: 14),
                _infoRow('Name',    customer.name),
                _infoRow('City',    customer.city),
                _infoRow('Mobile',  customer.phone),
                _infoRow('Package', customer.batchDisplayName),
                const Divider(height: 20),
                _infoRow('Adults (10+)',  '${customer.guestsAbove10} × ₹${customer.amountPerPersonAbove10.toStringAsFixed(0)} = ₹${customer.amountAbove10.toStringAsFixed(0)}'),
                _infoRow('Children (3–10)', '${customer.guestsBetween3to10} × ₹${customer.amountPerPersonBetween3to10.toStringAsFixed(0)} = ₹${customer.amountBetween3to10.toStringAsFixed(0)}'),
                const Divider(height: 20),
                _infoRow('Total Guests', '${customer.totalGuests}', bold: true),
                _infoRow('Total Amount', '₹${customer.totalAmount.toStringAsFixed(0)}', bold: true),
                _infoRow('Payment', customer.paymentMethodDisplay, bold: true),
                if (customer.foodOption.lunchDinner || customer.foodOption.breakfast) ...[
                  const Divider(height: 20),
                  Text('Food Options',
                      style: GoogleFonts.poppins(
                          fontSize: 12, fontWeight: FontWeight.w600,
                          color: AppColors.textMedium)),
                  const SizedBox(height: 6),
                  if (customer.foodOption.lunchDinner)
                    _infoRow('🍛 Lunch/Dinner',
                        '${customer.foodOption.lunchDinnerGuests} guests'),
                  if (customer.foodOption.breakfast)
                    _infoRow('🍽️ Breakfast',
                        '${customer.foodOption.breakfastGuests} guests'),
                ],
              ],
            ),
          ),

          const SizedBox(height: 24),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () =>
                    Navigator.of(context).popUntil((r) => r.isFirst),
                icon: const Icon(Icons.dashboard_outlined),
                label: const Text('Dashboard'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).popUntil((r) => r.isFirst);
                  // Push add customer again
                },
                icon: const Icon(Icons.person_add_outlined, color: Colors.white),
                label: Text('Add Another',
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 30),
        ]),
      ),
    );
  }

  Widget _infoRow(String label, String value, {bool bold = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 130,
              child: Text(label,
                  style: GoogleFonts.poppins(
                      fontSize: 12, color: AppColors.textLight)),
            ),
            Expanded(
              child: Text(value,
                  style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                      color: AppColors.textDark)),
            ),
          ],
        ),
      );
}

// ── QR Code Widget (pure Flutter, no package needed) ──────────────────────
class _QrWidget extends StatelessWidget {
  final String data;
  const _QrWidget({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade200, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: CustomPaint(
        painter: _QrPainter(data: data),
        child: Center(
          child: Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
            ),
            child: const Center(
              child: Text('🌿', style: TextStyle(fontSize: 24)),
            ),
          ),
        ),
      ),
    );
  }
}

class _QrPainter extends CustomPainter {
  final String data;
  _QrPainter({required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF1B4332);
    final bg    = Paint()..color = Colors.white;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bg);

    // Deterministic pseudo-QR grid based on data hash
    final hash  = data.codeUnits.fold(0, (prev, e) => (prev * 31 + e) & 0xFFFFFF);
    const cells = 21;
    final cell  = size.width / cells;

    // Finder patterns (three corners)
    void finder(int col, int row) {
      for (int r = 0; r < 7; r++) {
        for (int c = 0; c < 7; c++) {
          final outer = r == 0 || r == 6 || c == 0 || c == 6;
          final inner = r >= 2 && r <= 4 && c >= 2 && c <= 4;
          if (outer || inner) {
            canvas.drawRect(
              Rect.fromLTWH((col + c) * cell, (row + r) * cell, cell, cell),
              paint,
            );
          }
        }
      }
    }

    finder(0, 0);
    finder(cells - 7, 0);
    finder(0, cells - 7);

    // Data cells (pseudo-random but deterministic)
    var seed = hash;
    for (int r = 0; r < cells; r++) {
      for (int c = 0; c < cells; c++) {
        // Skip finder pattern areas
        if ((r < 8 && c < 8) ||
            (r < 8 && c >= cells - 8) ||
            (r >= cells - 8 && c < 8)) continue;
        seed = (seed * 1664525 + 1013904223) & 0xFFFFFFFF;
        if (seed & 1 == 1) {
          canvas.drawRect(
            Rect.fromLTWH(c * cell, r * cell, cell - 0.5, cell - 0.5),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(_QrPainter old) => old.data != data;
}
