import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/booking_model.dart';

class DataService {
  static const String _customersKey = 'customers_list_v2';
  static const String _workersKey   = 'workers_list';

  // ── Customers ──────────────────────────────────────────────

  Future<List<CustomerModel>> getCustomers() async {
    final prefs = await SharedPreferences.getInstance();
    final json  = prefs.getString(_customersKey);
    if (json == null) return [];
    final List<dynamic> list = jsonDecode(json);
    return list.map((e) => CustomerModel.fromJson(e)).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> saveAllCustomers(List<CustomerModel> customers) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _customersKey, jsonEncode(customers.map((c) => c.toJson()).toList()));
  }

  Future<void> addCustomer(CustomerModel customer) async {
    final list = await getCustomers();
    list.insert(0, customer);
    await saveAllCustomers(list);
  }

  Future<void> updateCustomer(CustomerModel updated) async {
    final list = await getCustomers();
    final idx  = list.indexWhere((c) => c.id == updated.id);
    if (idx != -1) list[idx] = updated;
    await saveAllCustomers(list);
  }

  Future<void> deleteCustomer(String id) async {
    final list = await getCustomers();
    list.removeWhere((c) => c.id == id);
    await saveAllCustomers(list);
  }

  Future<void> markQrUsed(String customerId) async {
    final list = await getCustomers();
    final idx  = list.indexWhere((c) => c.id == customerId);
    if (idx != -1) list[idx] = list[idx].copyWith(qrUsed: true);
    await saveAllCustomers(list);
  }

  Future<List<CustomerModel>> getTodaysCustomers() async {
    final all   = await getCustomers();
    final today = DateTime.now();
    return all.where((c) =>
        c.visitDate.year  == today.year &&
        c.visitDate.month == today.month &&
        c.visitDate.day   == today.day).toList();
  }

  Future<DashboardStats> getDashboardStats() async {
    final today = await getTodaysCustomers();
    int    guests = 0;
    double cash   = 0, online = 0;
    for (final c in today) {
      guests += c.totalGuests;
      if (c.paymentMethod == PaymentMethod.cash) cash   += c.totalAmount;
      else                                        online += c.totalAmount;
    }
    return DashboardStats(
      totalBookings: today.length,
      totalGuests:   guests,
      totalRevenue:  cash + online,
      cashPayment:   cash,
      onlinePayment: online,
      date: DateTime.now(),
    );
  }

  // ── Workers ────────────────────────────────────────────────

  static final List<Map<String, dynamic>> _seedWorkers = [
    {'id':'w1','name':'Mohan Lal','phone':'9876543230','role':'Guide','isPresent':true,'joiningDate':'2022-01-15T00:00:00.000'},
    {'id':'w2','name':'Sita Devi','phone':'9876543231','role':'Cook','isPresent':true,'joiningDate':'2021-06-10T00:00:00.000'},
    {'id':'w3','name':'Raju Yadav','phone':'9876543232','role':'Security','isPresent':false,'joiningDate':'2023-03-20T00:00:00.000'},
    {'id':'w4','name':'Kavita Joshi','phone':'9876543233','role':'Receptionist','isPresent':true,'joiningDate':'2022-09-05T00:00:00.000'},
    {'id':'w5','name':'Deepak Tiwari','phone':'9876543234','role':'Gardener','isPresent':true,'joiningDate':'2020-11-01T00:00:00.000'},
  ];

  Future<List<WorkerModel>> getWorkers() async {
    final prefs = await SharedPreferences.getInstance();
    final json  = prefs.getString(_workersKey);
    if (json == null) return _seedWorkers.map(WorkerModel.fromJson).toList();
    final List<dynamic> list = jsonDecode(json);
    return list.map((e) => WorkerModel.fromJson(e)).toList();
  }

  Future<void> _saveWorkers(List<WorkerModel> workers) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_workersKey, jsonEncode(workers.map((w) => w.toJson()).toList()));
  }

  Future<void> addWorker(WorkerModel worker) async {
    final list = await getWorkers();
    list.add(worker);
    await _saveWorkers(list);
  }

  Future<void> updateWorkerAttendance(String id, bool isPresent) async {
    final list = await getWorkers();
    final idx  = list.indexWhere((w) => w.id == id);
    if (idx != -1) {
      list[idx] = WorkerModel(
        id: list[idx].id, name: list[idx].name, phone: list[idx].phone,
        role: list[idx].role, isPresent: isPresent, joiningDate: list[idx].joiningDate,
      );
    }
    await _saveWorkers(list);
  }
}
