enum PaymentMethod { cash, online }
enum BookingStatus { confirmed, pending, cancelled, completed }

enum BatchType {
  halfDayMorning,
  halfDayEvening,
  fullDay,
  acDeluxeRoom,
  nonAcRoom,
}

class FoodOption {
  final bool lunchDinner;
  final bool breakfast;
  final int lunchDinnerGuests;
  final int breakfastGuests;

  FoodOption({
    this.lunchDinner = false,
    this.breakfast = false,
    this.lunchDinnerGuests = 0,
    this.breakfastGuests = 0,
  });

  factory FoodOption.fromJson(Map<String, dynamic> json) => FoodOption(
        lunchDinner: json['lunchDinner'] ?? false,
        breakfast: json['breakfast'] ?? false,
        lunchDinnerGuests: json['lunchDinnerGuests'] ?? 0,
        breakfastGuests: json['breakfastGuests'] ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'lunchDinner': lunchDinner,
        'breakfast': breakfast,
        'lunchDinnerGuests': lunchDinnerGuests,
        'breakfastGuests': breakfastGuests,
      };
}

class CustomerModel {
  final String id;
  final String name;
  final String city;
  final String phone;
  final String email;
  final BatchType batchType;
  // Guests above 10 yrs
  final int guestsAbove10;
  final double amountPerPersonAbove10;
  // Guests 3–10 yrs
  final int guestsBetween3to10;
  final double amountPerPersonBetween3to10;
  // Food
  final FoodOption foodOption;
  // Totals
  final int totalGuests;
  final double totalAmount;
  final PaymentMethod paymentMethod;
  final BookingStatus status;
  // QR
  final String qrCode;
  final bool qrUsed;
  final DateTime visitDate;
  final DateTime createdAt;

  CustomerModel({
    required this.id,
    required this.name,
    required this.city,
    required this.phone,
    this.email = '',
    required this.batchType,
    required this.guestsAbove10,
    required this.amountPerPersonAbove10,
    required this.guestsBetween3to10,
    required this.amountPerPersonBetween3to10,
    required this.foodOption,
    required this.totalGuests,
    required this.totalAmount,
    required this.paymentMethod,
    required this.status,
    required this.qrCode,
    this.qrUsed = false,
    required this.visitDate,
    required this.createdAt,
  });

  double get amountAbove10 => guestsAbove10 * amountPerPersonAbove10;
  double get amountBetween3to10 => guestsBetween3to10 * amountPerPersonBetween3to10;

  String get batchDisplayName {
    switch (batchType) {
      case BatchType.halfDayMorning:
        return '🌞 Half Day – Morning (10:00–15:00)';
      case BatchType.halfDayEvening:
        return '🌅 Half Day – Evening (15:00–20:00)';
      case BatchType.fullDay:
        return '🌟 Full Day (10:00–18:00)';
      case BatchType.acDeluxeRoom:
        return '🏨 AC Deluxe Room Package';
      case BatchType.nonAcRoom:
        return '🏠 Non AC Room Package';
    }
  }

  String get paymentMethodDisplay =>
      paymentMethod == PaymentMethod.cash ? 'Cash' : 'Online';

  String get statusDisplay {
    switch (status) {
      case BookingStatus.confirmed: return 'Confirmed';
      case BookingStatus.pending:   return 'Pending';
      case BookingStatus.cancelled: return 'Cancelled';
      case BookingStatus.completed: return 'Completed';
    }
  }

  CustomerModel copyWith({
    String? name, String? city, String? phone, String? email,
    BatchType? batchType, int? guestsAbove10, double? amountPerPersonAbove10,
    int? guestsBetween3to10, double? amountPerPersonBetween3to10,
    FoodOption? foodOption, int? totalGuests, double? totalAmount,
    PaymentMethod? paymentMethod, BookingStatus? status,
    String? qrCode, bool? qrUsed, DateTime? visitDate,
  }) {
    return CustomerModel(
      id: id,
      name: name ?? this.name,
      city: city ?? this.city,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      batchType: batchType ?? this.batchType,
      guestsAbove10: guestsAbove10 ?? this.guestsAbove10,
      amountPerPersonAbove10: amountPerPersonAbove10 ?? this.amountPerPersonAbove10,
      guestsBetween3to10: guestsBetween3to10 ?? this.guestsBetween3to10,
      amountPerPersonBetween3to10: amountPerPersonBetween3to10 ?? this.amountPerPersonBetween3to10,
      foodOption: foodOption ?? this.foodOption,
      totalGuests: totalGuests ?? this.totalGuests,
      totalAmount: totalAmount ?? this.totalAmount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      status: status ?? this.status,
      qrCode: qrCode ?? this.qrCode,
      qrUsed: qrUsed ?? this.qrUsed,
      visitDate: visitDate ?? this.visitDate,
      createdAt: createdAt,
    );
  }

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      id: json['id'],
      name: json['name'],
      city: json['city'] ?? '',
      phone: json['phone'],
      email: json['email'] ?? '',
      batchType: BatchType.values.firstWhere(
        (e) => e.toString() == 'BatchType.${json['batchType']}',
        orElse: () => BatchType.fullDay,
      ),
      guestsAbove10: json['guestsAbove10'] ?? 0,
      amountPerPersonAbove10: (json['amountPerPersonAbove10'] ?? 0).toDouble(),
      guestsBetween3to10: json['guestsBetween3to10'] ?? 0,
      amountPerPersonBetween3to10: (json['amountPerPersonBetween3to10'] ?? 0).toDouble(),
      foodOption: json['foodOption'] != null
          ? FoodOption.fromJson(json['foodOption'])
          : FoodOption(),
      totalGuests: json['totalGuests'] ?? 0,
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      paymentMethod: PaymentMethod.values.firstWhere(
        (e) => e.toString() == 'PaymentMethod.${json['paymentMethod']}',
        orElse: () => PaymentMethod.cash,
      ),
      status: BookingStatus.values.firstWhere(
        (e) => e.toString() == 'BookingStatus.${json['status']}',
        orElse: () => BookingStatus.confirmed,
      ),
      qrCode: json['qrCode'] ?? '',
      qrUsed: json['qrUsed'] ?? false,
      visitDate: DateTime.parse(json['visitDate']),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'city': city,
        'phone': phone,
        'email': email,
        'batchType': batchType.toString().split('.').last,
        'guestsAbove10': guestsAbove10,
        'amountPerPersonAbove10': amountPerPersonAbove10,
        'guestsBetween3to10': guestsBetween3to10,
        'amountPerPersonBetween3to10': amountPerPersonBetween3to10,
        'foodOption': foodOption.toJson(),
        'totalGuests': totalGuests,
        'totalAmount': totalAmount,
        'paymentMethod': paymentMethod.toString().split('.').last,
        'status': status.toString().split('.').last,
        'qrCode': qrCode,
        'qrUsed': qrUsed,
        'visitDate': visitDate.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
      };
}

// Batch pricing table
class BatchPricing {
  static double getAdultPrice(BatchType type) {
    switch (type) {
      case BatchType.halfDayMorning:
      case BatchType.halfDayEvening: return 500;
      case BatchType.fullDay: return 650;
      case BatchType.acDeluxeRoom: return 1800;
      case BatchType.nonAcRoom: return 1500;
    }
  }
  static double getChildPrice(BatchType type) {
    switch (type) {
      case BatchType.halfDayMorning:
      case BatchType.halfDayEvening: return 400;
      case BatchType.fullDay: return 500;
      case BatchType.acDeluxeRoom: return 1300;
      case BatchType.nonAcRoom: return 1100;
    }
  }
}

class DashboardStats {
  final int totalBookings;
  final int totalGuests;
  final double totalRevenue;
  final double cashPayment;
  final double onlinePayment;
  final DateTime date;

  DashboardStats({
    required this.totalBookings,
    required this.totalGuests,
    required this.totalRevenue,
    required this.cashPayment,
    required this.onlinePayment,
    required this.date,
  });

  factory DashboardStats.empty() => DashboardStats(
        totalBookings: 0, totalGuests: 0, totalRevenue: 0,
        cashPayment: 0, onlinePayment: 0, date: DateTime.now(),
      );
}

class WorkerModel {
  final String id;
  final String name;
  final String phone;
  final String role;
  final bool isPresent;
  final DateTime joiningDate;

  WorkerModel({
    required this.id, required this.name, required this.phone,
    required this.role, required this.isPresent, required this.joiningDate,
  });

  factory WorkerModel.fromJson(Map<String, dynamic> json) => WorkerModel(
        id: json['id'], name: json['name'], phone: json['phone'],
        role: json['role'], isPresent: json['isPresent'],
        joiningDate: DateTime.parse(json['joiningDate']),
      );

  Map<String, dynamic> toJson() => {
        'id': id, 'name': name, 'phone': phone,
        'role': role, 'isPresent': isPresent,
        'joiningDate': joiningDate.toIso8601String(),
      };
}
