import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/models.dart';
import '../../services/storage_service.dart';
import '../../utils/app_theme.dart';
import '../manager/manager_dashboard.dart';
import '../owner/owner_dashboard.dart';
import '../canteen/canteen_dashboard.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  Future<void> _login() async {
    final u = _userCtrl.text.trim();
    final p = _passCtrl.text;
    if (u.isEmpty || p.isEmpty) {
      _snack('Please enter username and password', error: true);
      return;
    }
    setState(() => _loading = true);
    final user = await StorageService.instance.login(u, p);
    setState(() => _loading = false);
    if (!mounted) return;
    if (user == null) {
      _snack('Invalid username or password', error: true);
      return;
    }
    Widget dest;
    if (user.role == UserRole.owner || user.role == UserRole.admin) {
      dest = OwnerDashboard(user: user);
    } else if (user.role == UserRole.canteen) {
      dest = CanteenDashboard(user: user);
    } else {
      dest = ManagerDashboard(user: user);
    }
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => dest));
  }

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.poppins()),
      backgroundColor: error ? AppColors.error : AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primaryDark, AppColors.primary, Color(0xFF52B788)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 50),
                Container(
                  width: 86, height: 86,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 20)],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: Image.asset('logo_512.png', width: 86, height: 86,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const Center(child: Text('🌿',
                                style: TextStyle(fontSize: 46)))),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Janki Agro Tourism',
                    style: GoogleFonts.poppins(
                        fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white)),
                Text('Management Portal',
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: Colors.white70, letterSpacing: 1.5)),
                const SizedBox(height: 36),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 20)],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Welcome Back!',
                          style: GoogleFonts.poppins(
                              fontSize: 20, fontWeight: FontWeight.w700,
                              color: AppColors.textDark)),
                      Text('Sign in to your account',
                          style: GoogleFonts.poppins(
                              fontSize: 12, color: AppColors.textLight)),
                      const SizedBox(height: 22),
                      TextFormField(
                        controller: _userCtrl,
                        decoration: InputDecoration(
                          labelText: 'Username',
                          prefixIcon: const Icon(Icons.person_outline,
                              color: AppColors.primary, size: 20),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _passCtrl,
                        obscureText: _obscure,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline,
                              color: AppColors.primary, size: 20),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscure ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: AppColors.textLight, size: 20,
                            ),
                            onPressed: () => setState(() => _obscure = !_obscure),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _login,
                          child: _loading
                              ? const SizedBox(
                                  width: 22, height: 22,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2.5))
                              : Text('Sign In',
                                  style: GoogleFonts.poppins(
                                      fontSize: 15, fontWeight: FontWeight.w600,
                                      color: Colors.white)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Text("Don't have an account? ",
                            style: GoogleFonts.poppins(
                                fontSize: 13, color: AppColors.textLight)),
                        GestureDetector(
                          onTap: () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const RegisterScreen())),
                          child: Text('Register',
                              style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary)),
                        ),
                      ]),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white30),
                  ),
                  child: Column(children: [
                    Text('Demo Credentials',
                        style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13)),
                    const SizedBox(height: 8),
                    _cred('Manager', 'manager1', 'manager123'),
                    _cred('Owner',   'owner1',   'owner123'),
                  ]),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _cred(String role, String u, String p) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Text('$role: $u / $p',
        style: GoogleFonts.poppins(color: Colors.white, fontSize: 11)),
  );
}
