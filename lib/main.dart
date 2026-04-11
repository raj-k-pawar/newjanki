import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'models/models.dart';
import 'services/storage_service.dart';
import 'utils/app_theme.dart';
import 'screens/auth/login_screen.dart';
import 'screens/manager/manager_dashboard.dart';
import 'screens/owner/owner_dashboard.dart';
import 'screens/canteen/canteen_dashboard.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light));
  runApp(const JankiAgroApp());
}

class JankiAgroApp extends StatelessWidget {
  const JankiAgroApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Janki Agro Tourism',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const _Splash(),
    );
  }
}

class _Splash extends StatefulWidget {
  const _Splash();
  @override State<_Splash> createState() => _SplashState();
}
class _SplashState extends State<_Splash> {
  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    await Future.delayed(const Duration(milliseconds: 1200));
    final user = await StorageService.instance.getSession();
    if (!mounted) return;
    if (user == null) {
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => const LoginScreen()));
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
        child: Center(child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(width:90,height:90,
              decoration: BoxDecoration(color:Colors.white,
                  borderRadius:BorderRadius.circular(22),
                  boxShadow:[BoxShadow(color:Colors.black26,blurRadius:16)]),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Image.asset('logo_512.png', width:90, height:90, fit:BoxFit.cover,
                  errorBuilder:(_,__,___) => const Center(
                      child:Text('🌿',style:TextStyle(fontSize:50)))))),
            const SizedBox(height:20),
            Text('Janki Agro Tourism',style:GoogleFonts.poppins(
                fontSize:24,fontWeight:FontWeight.w700,color:Colors.white)),
            Text('Management Portal',style:GoogleFonts.poppins(
                fontSize:12,color:Colors.white70,letterSpacing:2)),
            const SizedBox(height:50),
            const CircularProgressIndicator(color:Colors.white54,strokeWidth:2.5),
          ],
        )),
      ),
    );
  }
}
