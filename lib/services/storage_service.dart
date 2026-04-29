import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import 'api_service.dart';

/// StorageService — local-first with cloud sync.
/// Every write goes to SharedPreferences (instant) AND Supabase API (async).
/// Every read first tries API (fresh data), falls back to local cache.
class StorageService {
  static StorageService? _i;
  static StorageService get instance => _i ??= StorageService._();
  StorageService._();

  SharedPreferences? _prefs;
  Future<SharedPreferences> get prefs async =>
      _prefs ??= await SharedPreferences.getInstance();

  // ── Local helpers ─────────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> _getList(String key) async {
    final p = await prefs;
    final s = p.getString(key);
    if (s == null) return [];
    return List<Map<String, dynamic>>.from(jsonDecode(s));
  }

  Future<void> _setList(String key, List<Map<String, dynamic>> list) async {
    final p = await prefs;
    await p.setString(key, jsonEncode(list));
  }

  // ── Cloud sync helpers ────────────────────────────────────────────────────
  /// Pull entire table from cloud, merge into local cache.
  /// Cloud wins on conflict (latest updated_at).
  Future<List<Map<String, dynamic>>> _syncFromCloud(
      String table, String localKey) async {
    final remote = await ApiService.instance.fetchAll(table);
    if (remote == null) {
      // Offline — return local cache
      return _getList(localKey);
    }
    // Build map from remote
    final remoteMap = <String, Map<String, dynamic>>{};
    for (final row in remote) {
      final data = row['data'] as Map<String, dynamic>;
      remoteMap[row['id'] as String] = data;
    }
    // Load local
    final local = await _getList(localKey);
    final localMap = <String, Map<String, dynamic>>{};
    for (final item in local) {
      localMap[item['id'] as String] = item;
    }
    // Merge: remote overrides local
    localMap.addAll(remoteMap);
    final merged = localMap.values.toList();
    // Save merged back to local
    await _setList(localKey, merged);
    return merged;
  }

  /// Push a single item to cloud (fire-and-forget, won't block UI).
  void _pushToCloud(String table, String id, Map<String, dynamic> data) {
    ApiService.instance.upsert(table, id, data);
  }

  /// Delete from cloud (fire-and-forget).
  void _deleteFromCloud(String table, String id) {
    ApiService.instance.delete(table, id);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // AUTH
  // ═══════════════════════════════════════════════════════════════════════════
  static const _usersKey   = 'users_v2';
  static const _sessionKey = 'session_user';

  Future<void> _seedUsers() async {
    // First try to get users from cloud
    final remote = await ApiService.instance.fetchAll('app_users');
    if (remote != null && remote.isNotEmpty) {
      final list = remote.map((r) => r['data'] as Map<String, dynamic>).toList();
      await _setList(_usersKey, list);
      return;
    }
    // Check local
    final list = await _getList(_usersKey);
    if (list.isNotEmpty) return;
    // Seed defaults
    final seeds = [
      {'id':'u1','username':'manager1','password':'manager123','fullName':'Rajesh Patel',  'phone':'9876543210','role':'manager'},
      {'id':'u2','username':'manager2','password':'manager456','fullName':'Suresh Kumar',  'phone':'9876543211','role':'manager'},
      {'id':'u3','username':'owner1',  'password':'owner123',  'fullName':'Janki Devi',    'phone':'9876543212','role':'owner'},
      {'id':'u4','username':'admin1',  'password':'admin123',  'fullName':'Admin User',    'phone':'9876543213','role':'admin'},
      {'id':'u5','username':'canteen1','password':'canteen123','fullName':'Ramesh Singh',  'phone':'9876543214','role':'canteen'},
    ];
    await _setList(_usersKey, seeds);
    // Push seeds to cloud
    for (final s in seeds) { _pushToCloud('app_users', s['id']!, s); }
  }

  Future<UserModel?> login(String username, String password) async {
    await _seedUsers();
    await _seedPackages();
    final list = await _getList(_usersKey);
    for (final u in list) {
      if (u['username'] == username && u['password'] == password) {
        final user = UserModel.fromJson(u);
        final p = await prefs;
        await p.setString(_sessionKey, jsonEncode(u));
        return user;
      }
    }
    return null;
  }

  Future<bool> register({
    required String username, required String password,
    required String fullName, required String phone, required UserRole role,
  }) async {
    await _seedUsers();
    final list = await _getList(_usersKey);
    for (final u in list) { if (u['username'] == username) return false; }
    final newUser = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'username': username, 'password': password,
      'fullName': fullName, 'phone': phone, 'role': role.name,
    };
    list.add(newUser);
    await _setList(_usersKey, list);
    _pushToCloud('app_users', newUser['id']!, newUser);
    return true;
  }

  Future<UserModel?> getSession() async {
    final p = await prefs;
    final s = p.getString(_sessionKey);
    if (s == null) return null;
    return UserModel.fromJson(jsonDecode(s));
  }

  Future<void> logout() async {
    final p = await prefs;
    await p.remove(_sessionKey);
  }

  Future<List<UserModel>> getAllManagers() async {
    await _seedUsers();
    final list = await _getList(_usersKey);
    return list.where((u) => u['role'] == 'manager')
        .map((u) => UserModel.fromJson(u)).toList();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PACKAGES
  // ═══════════════════════════════════════════════════════════════════════════
  static const _packagesKey = 'packages_v2';

  Future<void> _seedPackages() async {
    final list = await _getList(_packagesKey);
    if (list.isNotEmpty) return;
    final seeds = [
      {'id':'p1','name':'सकाळी हाफ डे पॅकेज 🌅','timeSlot':'सकाळी 10:00 ते दुपारी 03:00','breakfast':true,'lunch':true,'snacks':false,'dinner':false,'adultPrice':500.0,'childPrice':400.0,'isStay':false},
      {'id':'p2','name':'सायंकाळी हाफ डे पॅकेज 🌅','timeSlot':'दुपारी 03:00 ते सायंकाळी 08:00','breakfast':false,'lunch':false,'snacks':true,'dinner':true,'adultPrice':500.0,'childPrice':400.0,'isStay':false},
      {'id':'p3','name':'🌟 फुल डे पॅकेज 🌟','timeSlot':'सकाळी 10:00 ते सायंकाळी 06:00','breakfast':true,'lunch':true,'snacks':false,'dinner':false,'adultPrice':650.0,'childPrice':500.0,'isStay':false},
      {'id':'p4','name':'निवासी AC डिलक्स रूम (सकाळी)','timeSlot':'सकाळी 10:00 ते दुसऱ्या दिवशी 09:30','breakfast':true,'lunch':true,'snacks':true,'dinner':true,'adultPrice':1800.0,'childPrice':1300.0,'isStay':true},
      {'id':'p5','name':'निवासी AC डिलक्स रूम (दुपारी)','timeSlot':'दुपारी 03:00 ते दुसऱ्या दिवशी 02:30','breakfast':true,'lunch':true,'snacks':true,'dinner':true,'adultPrice':1800.0,'childPrice':1300.0,'isStay':true},
      {'id':'p6','name':'🏠 निवासी Non AC रूम (सकाळी) 🌿','timeSlot':'सकाळी 10:00 ते दुसऱ्या दिवशी 09:30','breakfast':true,'lunch':true,'snacks':true,'dinner':true,'adultPrice':1500.0,'childPrice':1100.0,'isStay':true},
      {'id':'p7','name':'🏠 निवासी Non AC रूम (दुपारी) 🌿','timeSlot':'दुपारी 03:00 ते दुसऱ्या दिवशी 02:30','breakfast':true,'lunch':true,'snacks':true,'dinner':true,'adultPrice':1500.0,'childPrice':1100.0,'isStay':true},
    ];
    await _setList(_packagesKey, seeds);
    for (final s in seeds) { _pushToCloud('packages', s['id'] as String, s); }
  }

  Future<List<PackageModel>> getPackages() async {
    await _seedPackages();
    final list = await _syncFromCloud('packages', _packagesKey);
    return list.map((p) => PackageModel.fromJson(p)).toList();
  }

  Future<void> savePackage(PackageModel pkg) async {
    final list = await _getList(_packagesKey);
    final idx = list.indexWhere((p) => p['id'] == pkg.id);
    if (idx >= 0) list[idx] = pkg.toJson(); else list.add(pkg.toJson());
    await _setList(_packagesKey, list);
    _pushToCloud('packages', pkg.id, pkg.toJson());
  }

  Future<void> deletePackage(String id) async {
    final list = await _getList(_packagesKey);
    list.removeWhere((p) => p['id'] == id);
    await _setList(_packagesKey, list);
    _deleteFromCloud('packages', id);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CUSTOMERS
  // ═══════════════════════════════════════════════════════════════════════════
  static const _customersKey = 'customers_v3';

  Future<List<CustomerModel>> getCustomers() async {
    final list = await _syncFromCloud('customers', _customersKey);
    return list.map((c) => CustomerModel.fromJson(c)).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<List<CustomerModel>> getCustomersByDate(DateTime date) async {
    final all = await getCustomers();
    return all.where((c) =>
        c.visitDate.year  == date.year &&
        c.visitDate.month == date.month &&
        c.visitDate.day   == date.day).toList();
  }

  Future<void> saveCustomer(CustomerModel c) async {
    final list = await _getList(_customersKey);
    final idx = list.indexWhere((e) => e['id'] == c.id);
    if (idx >= 0) list[idx] = c.toJson(); else list.insert(0, c.toJson());
    await _setList(_customersKey, list);
    _pushToCloud('customers', c.id, c.toJson());
  }

  Future<void> deleteCustomer(String id) async {
    final list = await _getList(_customersKey);
    list.removeWhere((c) => c['id'] == id);
    await _setList(_customersKey, list);
    _deleteFromCloud('customers', id);
  }

  Future<void> markCanteenServed(String customerId) async {
    final list = await _getList(_customersKey);
    final idx = list.indexWhere((c) => c['id'] == customerId);
    if (idx >= 0) {
      list[idx]['canteenServed'] = true;
      list[idx]['qrUsed'] = true;
      await _setList(_customersKey, list);
      _pushToCloud('customers', customerId, list[idx]);
    }
  }

  Future<List<CustomerModel>> getCustomersByTaxYear(String taxYear) async {
    final parts = taxYear.split('-');
    if (parts.length != 2) return [];
    final startYear = int.tryParse(parts[0]) ?? 2025;
    final endYear   = 2000 + (int.tryParse(parts[1]) ?? 26);
    final start = DateTime(startYear, 4, 1);
    final end   = DateTime(endYear,   3, 31, 23, 59);
    final all = await getCustomers();
    return all.where((c) =>
        !c.visitDate.isBefore(start) && !c.visitDate.isAfter(end)).toList();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // WORKERS
  // ═══════════════════════════════════════════════════════════════════════════
  static const _workersKey = 'workers_v3';

  Future<List<WorkerModel>> getWorkers() async {
    final list = await _syncFromCloud('workers', _workersKey);
    return list.map((w) => WorkerModel.fromJson(w)).toList();
  }

  Future<void> saveWorker(WorkerModel w) async {
    final list = await _getList(_workersKey);
    final idx = list.indexWhere((e) => e['id'] == w.id);
    if (idx >= 0) list[idx] = w.toJson(); else list.add(w.toJson());
    await _setList(_workersKey, list);
    _pushToCloud('workers', w.id, w.toJson());
  }

  Future<void> deleteWorker(String id) async {
    final list = await _getList(_workersKey);
    list.removeWhere((w) => w['id'] == id);
    await _setList(_workersKey, list);
    _deleteFromCloud('workers', id);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ATTENDANCE
  // ═══════════════════════════════════════════════════════════════════════════
  static const _attendanceKey = 'attendance_v1';

  Future<List<AttendanceRecord>> getAttendance() async {
    final list = await _syncFromCloud('attendance', _attendanceKey);
    return list.map((a) => AttendanceRecord.fromJson(a)).toList();
  }

  Future<void> setAttendance(String workerId, DateTime date, String status) async {
    final list = await _getList(_attendanceKey);
    final ds = '${date.year}-${date.month}-${date.day}';
    final id = '${workerId}_$ds';
    list.removeWhere((a) {
      final d = DateTime.parse(a['date']);
      return a['workerId'] == workerId &&
          '${d.year}-${d.month}-${d.day}' == ds;
    });
    final rec = AttendanceRecord(workerId: workerId, date: date, status: status).toJson()
      ..['id'] = id;
    list.add(rec);
    await _setList(_attendanceKey, list);
    _pushToCloud('attendance', id, rec);
  }

  Future<String> getWorkerAttendanceStatus(String workerId, DateTime date) async {
    final all = await getAttendance();
    final ds = '${date.year}-${date.month}-${date.day}';
    final recs = all.where((a) {
      final d = a.date;
      return a.workerId == workerId && '${d.year}-${d.month}-${d.day}' == ds;
    });
    return recs.isEmpty ? 'absent' : recs.first.status;
  }

  Future<bool> getWorkerAttendance(String workerId, DateTime date) async {
    final s = await getWorkerAttendanceStatus(workerId, date);
    return s == 'present' || s == 'halfday';
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ADVANCE PAYMENTS
  // ═══════════════════════════════════════════════════════════════════════════
  static const _advanceKey = 'advances_v1';

  Future<List<AdvancePayment>> getAdvances() async {
    final list = await _syncFromCloud('advances', _advanceKey);
    return list.map((a) => AdvancePayment.fromJson(a)).toList();
  }

  Future<void> addAdvance(AdvancePayment a) async {
    final list = await _getList(_advanceKey);
    list.add(a.toJson());
    await _setList(_advanceKey, list);
    _pushToCloud('advances', a.id, a.toJson());
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SALARY PAYMENTS
  // ═══════════════════════════════════════════════════════════════════════════
  static const _salaryKey = 'salaries_v1';

  Future<List<SalaryPayment>> getSalaries() async {
    final list = await _syncFromCloud('salaries', _salaryKey);
    return list.map((s) => SalaryPayment.fromJson(s)).toList();
  }

  Future<bool> isSalaryPaid(String workerId, int month, int year) async {
    final list = await getSalaries();
    return list.any((s) => s.workerId == workerId && s.month == month && s.year == year);
  }

  Future<void> addSalary(SalaryPayment s) async {
    final list = await _getList(_salaryKey);
    list.add(s.toJson());
    await _setList(_salaryKey, list);
    _pushToCloud('salaries', s.id, s.toJson());
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ENQUIRIES
  // ═══════════════════════════════════════════════════════════════════════════
  static const _enquiryKey = 'enquiries_v1';

  Future<List<EnquiryModel>> getEnquiries() async {
    final list = await _syncFromCloud('enquiries', _enquiryKey);
    return list.map((e) => EnquiryModel.fromJson(e)).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<List<EnquiryModel>> getEnquiriesByDate(DateTime date) async {
    final all = await getEnquiries();
    return all.where((e) =>
        e.date.year == date.year &&
        e.date.month == date.month &&
        e.date.day == date.day).toList();
  }

  Future<void> addEnquiry(EnquiryModel e) async {
    final list = await _getList(_enquiryKey);
    list.insert(0, e.toJson());
    await _setList(_enquiryKey, list);
    _pushToCloud('enquiries', e.id, e.toJson());
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CANTEEN TRANSACTIONS
  // ═══════════════════════════════════════════════════════════════════════════
  static const _canteenKey = 'canteen_tx_v1';

  Future<List<CanteenTransaction>> getCanteenTransactions() async {
    final list = await _syncFromCloud('canteen_transactions', _canteenKey);
    return list.map((t) => CanteenTransaction.fromJson(t)).toList()
      ..sort((a, b) => b.paidDate.compareTo(a.paidDate));
  }

  Future<void> addCanteenTransaction(CanteenTransaction t) async {
    final list = await _getList(_canteenKey);
    list.insert(0, t.toJson());
    await _setList(_canteenKey, list);
    _pushToCloud('canteen_transactions', t.id, t.toJson());
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAX SETTINGS
  // ═══════════════════════════════════════════════════════════════════════════
  static const _taxKey = 'tax_settings_v1';

  Future<Map<String, dynamic>> getTaxSettings() async {
    // Try cloud first
    final remote = await ApiService.instance.fetchOne('tax_settings', 'main');
    if (remote != null) {
      final p = await prefs;
      await p.setString(_taxKey, jsonEncode(remote));
      return remote;
    }
    // Fall back to local
    final p = await prefs;
    final s = p.getString(_taxKey);
    if (s == null) return {};
    return Map<String, dynamic>.from(jsonDecode(s));
  }

  Future<void> saveTaxSettings(Map<String, dynamic> data) async {
    final p = await prefs;
    await p.setString(_taxKey, jsonEncode(data));
    _pushToCloud('tax_settings', 'main', data);
  }
}
