import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/models.dart';
import '../../services/storage_service.dart';
import '../../utils/app_theme.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey  = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _cpCtrl   = TextEditingController();
  final _phCtrl   = TextEditingController();
  UserRole _role  = UserRole.manager;
  bool _obs1 = true, _obs2 = true, _loading = false;

  @override void dispose() {
    _nameCtrl.dispose(); _userCtrl.dispose();
    _passCtrl.dispose(); _cpCtrl.dispose(); _phCtrl.dispose();
    super.dispose();
  }

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.poppins()),
      backgroundColor: error ? AppColors.error : AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (_passCtrl.text != _cpCtrl.text) {
      _snack('Passwords do not match', error: true); return;
    }
    setState(() => _loading = true);
    final ok = await StorageService.instance.register(
      username: _userCtrl.text.trim(),
      password: _passCtrl.text,
      fullName: _nameCtrl.text.trim(),
      phone:    _phCtrl.text.trim(),
      role:     _role,
    );
    setState(() => _loading = false);
    if (!mounted) return;
    if (ok) { _snack('Account created! Please login.'); Navigator.pop(context); }
    else _snack('Username already exists', error: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primaryDark, AppColors.primary, Color(0xFF52B788)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(child: Column(children: [
          // Back header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(color: Colors.white24,
                      borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.arrow_back_ios_new,
                      color: Colors.white, size: 18),
                ),
              ),
              const SizedBox(width: 12),
              Text('Create Account', style: GoogleFonts.poppins(
                  fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
            ]),
          ),
          const SizedBox(height: 14),
          Expanded(child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: const BoxDecoration(color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24), topRight: Radius.circular(24))),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(key: _formKey, child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Join Janki Agro Tourism', style: GoogleFonts.poppins(
                      fontSize: 18, fontWeight: FontWeight.w700,
                      color: AppColors.textDark)),
                  Text('Fill details to create your account', style: GoogleFonts.poppins(
                      fontSize: 12, color: AppColors.textLight)),
                  const SizedBox(height: 22),
                  _lbl('Full Name'),
                  _tf(_nameCtrl, 'Full name', Icons.person_outline, req: true),
                  const SizedBox(height: 12),
                  _lbl('Username'),
                  TextFormField(controller: _userCtrl,
                    decoration: const InputDecoration(labelText: 'Choose a username',
                        prefixIcon: Icon(Icons.alternate_email,
                            color: AppColors.primary, size: 20)),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Required';
                      if (v.trim().length < 4) return 'Min 4 characters';
                      return null;
                    }),
                  const SizedBox(height: 12),
                  _lbl('Phone Number'),
                  _tf(_phCtrl, 'Mobile number', Icons.phone_outlined,
                      type: TextInputType.phone,
                      validator: (v) => (v == null || v.trim().length < 10)
                          ? 'Enter valid phone' : null),
                  const SizedBox(height: 12),
                  _lbl('Role'),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                    decoration: BoxDecoration(color: Colors.white,
                        border: Border.all(color: AppColors.textLight.withOpacity(0.4)),
                        borderRadius: BorderRadius.circular(10)),
                    child: DropdownButtonHideUnderline(child: DropdownButton<UserRole>(
                      value: _role, isExpanded: true,
                      icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.primary),
                      onChanged: (v) { if (v != null) setState(() => _role = v); },
                      items: UserRole.values.map((r) => DropdownMenuItem(
                          value: r,
                          child: Text(_roleName(r),
                              style: GoogleFonts.poppins(fontSize: 14)))).toList(),
                    )),
                  ),
                  const SizedBox(height: 12),
                  _lbl('Password'),
                  TextFormField(controller: _passCtrl, obscureText: _obs1,
                    decoration: InputDecoration(labelText: 'Create password',
                        prefixIcon: const Icon(Icons.lock_outline,
                            color: AppColors.primary, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(_obs1 ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                              color: AppColors.textLight, size: 20),
                          onPressed: () => setState(() => _obs1 = !_obs1))),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if (v.length < 6) return 'Min 6 characters';
                      return null;
                    }),
                  const SizedBox(height: 12),
                  _lbl('Confirm Password'),
                  TextFormField(controller: _cpCtrl, obscureText: _obs2,
                    decoration: InputDecoration(labelText: 'Confirm password',
                        prefixIcon: const Icon(Icons.lock_outline,
                            color: AppColors.primary, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(_obs2 ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                              color: AppColors.textLight, size: 20),
                          onPressed: () => setState(() => _obs2 = !_obs2))),
                    validator: (v) => (v == null || v.isEmpty) ? 'Required' : null),
                  const SizedBox(height: 26),
                  SizedBox(width: double.infinity, height: 50,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _register,
                      child: _loading
                          ? const SizedBox(width: 22, height: 22,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2.5))
                          : Text('Create Account', style: GoogleFonts.poppins(
                              fontSize: 15, fontWeight: FontWeight.w600,
                              color: Colors.white)))),
                  const SizedBox(height: 16),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text('Already have an account? ',
                        style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textLight)),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Text('Sign In', style: GoogleFonts.poppins(
                          fontSize: 13, fontWeight: FontWeight.w700,
                          color: AppColors.primary))),
                  ]),
                  const SizedBox(height: 20),
                ],
              )),
            ),
          )),
        ])),
      ),
    );
  }

  Widget _lbl(String t) => Padding(padding: const EdgeInsets.only(bottom: 6),
    child: Text(t, style: GoogleFonts.poppins(fontSize: 12,
        fontWeight: FontWeight.w600, color: AppColors.textDark)));

  Widget _tf(TextEditingController c, String label, IconData icon,
      {TextInputType? type, bool req = false, String? Function(String?)? validator}) =>
    TextFormField(controller: c, keyboardType: type,
      decoration: InputDecoration(labelText: label,
          prefixIcon: Icon(icon, color: AppColors.primary, size: 20)),
      validator: validator ?? (req
          ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
          : null));

  String _roleName(UserRole r) {
    switch (r) {
      case UserRole.manager: return 'Manager';
      case UserRole.owner:   return 'Owner';
      case UserRole.admin:   return 'Admin';
      case UserRole.canteen: return 'Canteen';
    }
  }
}
