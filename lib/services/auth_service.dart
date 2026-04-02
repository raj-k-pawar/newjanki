import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class AuthService {
  static const String _userKey = 'current_user';
  static const String _usersListKey = 'users_list';
  static const String _isLoggedInKey = 'is_logged_in';

  // Mock users database
  static final List<Map<String, dynamic>> _mockUsers = [
    {
      'id': '1',
      'username': 'manager1',
      'password': 'manager123',
      'fullName': 'Rajesh Patel',
      'email': 'rajesh@jankiagro.com',
      'phone': '9876543210',
      'role': 'manager',
      'createdAt': DateTime.now().toIso8601String(),
    },
    {
      'id': '2',
      'username': 'owner1',
      'password': 'owner123',
      'fullName': 'Janki Devi',
      'email': 'janki@jankiagro.com',
      'phone': '9876543211',
      'role': 'owner',
      'createdAt': DateTime.now().toIso8601String(),
    },
    {
      'id': '3',
      'username': 'admin1',
      'password': 'admin123',
      'fullName': 'Suresh Kumar',
      'email': 'suresh@jankiagro.com',
      'phone': '9876543212',
      'role': 'admin',
      'createdAt': DateTime.now().toIso8601String(),
    },
    {
      'id': '4',
      'username': 'canteen1',
      'password': 'canteen123',
      'fullName': 'Ramesh Singh',
      'email': 'ramesh@jankiagro.com',
      'phone': '9876543213',
      'role': 'canteen',
      'createdAt': DateTime.now().toIso8601String(),
    },
  ];

  Future<Map<String, dynamic>> login(String username, String password) async {
    await Future.delayed(const Duration(milliseconds: 800));

    final prefs = await SharedPreferences.getInstance();

    // Check mock users first
    Map<String, dynamic>? foundUser;
    for (var user in _mockUsers) {
      if (user['username'] == username && user['password'] == password) {
        foundUser = user;
        break;
      }
    }

    // Check registered users
    if (foundUser == null) {
      final usersJson = prefs.getString(_usersListKey);
      if (usersJson != null) {
        final List<dynamic> usersList = jsonDecode(usersJson);
        for (var user in usersList) {
          if (user['username'] == username && user['password'] == password) {
            foundUser = Map<String, dynamic>.from(user);
            break;
          }
        }
      }
    }

    if (foundUser == null) {
      return {'success': false, 'message': 'Invalid username or password'};
    }

    final userToSave = Map<String, dynamic>.from(foundUser)..remove('password');
    await prefs.setString(_userKey, jsonEncode(userToSave));
    await prefs.setBool(_isLoggedInKey, true);

    return {
      'success': true,
      'user': UserModel.fromJson(userToSave),
    };
  }

  Future<Map<String, dynamic>> register({
    required String username,
    required String password,
    required String fullName,
    required String email,
    required String phone,
    required UserRole role,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));

    final prefs = await SharedPreferences.getInstance();

    // Check if username exists
    for (var user in _mockUsers) {
      if (user['username'] == username) {
        return {'success': false, 'message': 'Username already exists'};
      }
    }

    final usersJson = prefs.getString(_usersListKey);
    List<dynamic> usersList = usersJson != null ? jsonDecode(usersJson) : [];

    for (var user in usersList) {
      if (user['username'] == username) {
        return {'success': false, 'message': 'Username already exists'};
      }
    }

    final newUser = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'username': username,
      'password': password,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'role': role.toString().split('.').last,
      'createdAt': DateTime.now().toIso8601String(),
    };

    usersList.add(newUser);
    await prefs.setString(_usersListKey, jsonEncode(usersList));

    return {'success': true, 'message': 'Account created successfully'};
  }

  Future<UserModel?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);
    if (userJson == null) return null;
    return UserModel.fromJson(jsonDecode(userJson));
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    await prefs.setBool(_isLoggedInKey, false);
  }
}
