import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/user_model.dart';
import '../../models/booking_model.dart';
import '../../services/auth_service.dart';
import '../../services/data_service.dart';
import '../../utils/app_theme.dart';
import '../auth/login_screen.dart';
import '../manager/all_customers_screen.dart';
import '../manager/manage_workers_screen.dart';
import '../manager/add_customer_screen.dart';

// ========================
// OWNER DASHBOARD
// ========================
class OwnerDashboard extends StatefulWidget {
  final UserModel user;
  const OwnerDashboard({super.key, required this.user});

  @override
  State<OwnerDashboard> createState() => _OwnerDashboardState();
}

class _OwnerDashboardState extends State<OwnerDashboard> {
  final DataService _dataService = DataService();
  final AuthService _authService = AuthService();
  DashboardStats? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final stats = await _dataService.getDashboardStats();
    setState(() {
      _stats = stats;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return _buildBaseDashboard(
      context: context,
      roleColor: const Color(0xFF7B2D8B),
      emoji: '👑',
      extraActions: [
        _buildActionTile(
          icon: Icons.bar_chart_outlined,
          label: 'Revenue Reports',
          subtitle: 'Full financial overview',
          color: const Color(0xFF7B2D8B),
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const AllCustomersScreen())),
        ),
        _buildActionTile(
          icon: Icons.people_outline,
          label: 'View All Customers',
          subtitle: 'Browse all bookings',
          color: AppColors.cardBlue,
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const AllCustomersScreen())),
        ),
        _buildActionTile(
          icon: Icons.badge_outlined,
          label: 'Manage Workers',
          subtitle: 'Staff & attendance',
          color: AppColors.cardTeal,
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const ManageWorkersScreen())),
        ),
      ],
    );
  }

  Widget _buildBaseDashboard({
    required BuildContext context,
    required Color roleColor,
    required String emoji,
    required List<Widget> extraActions,
  }) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: roleColor,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [roleColor.withRed(30), roleColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$emoji ${widget.user.roleDisplayName} Dashboard',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  widget.user.fullName,
                                  style: GoogleFonts.playfairDisplay(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            GestureDetector(
                              onTap: () async {
                                await _authService.logout();
                                if (!context.mounted) return;
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const LoginScreen()),
                                  (r) => false,
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.logout,
                                        color: Colors.white, size: 14),
                                    const SizedBox(width: 4),
                                    Text('Logout',
                                        style: GoogleFonts.poppins(
                                            color: Colors.white, fontSize: 12)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            title: Text(
              'Janki Agro Tourism',
              style: GoogleFonts.playfairDisplay(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_isLoading)
                    const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.primary))
                  else
                    _buildStatsRow(),
                  const SizedBox(height: 24),
                  Text(
                    'Quick Actions',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 14),
                  ...extraActions,
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    final stats = _stats!;
    return Column(
      children: [
        Row(
          children: [
            _miniStat('Bookings', stats.totalBookings.toString(),
                Icons.book_online_outlined, AppColors.cardBlue),
            const SizedBox(width: 12),
            _miniStat('Guests', stats.totalGuests.toString(),
                Icons.groups_outlined, AppColors.cardGreen),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [AppColors.primaryDark, AppColors.primary]),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.currency_rupee, color: Colors.white, size: 28),
              const SizedBox(width: 10),
              Text(
                'Total Revenue: ₹${stats.totalRevenue.toStringAsFixed(0)}',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _miniStat(
      String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient:
              LinearGradient(colors: [color, color.withOpacity(0.7)]),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4))
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
                Text(label,
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: Colors.white70)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 3))
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark)),
                  Text(subtitle,
                      style: GoogleFonts.poppins(
                          fontSize: 12, color: AppColors.textLight)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: color, size: 16),
          ],
        ),
      ),
    );
  }
}

// ========================
// ADMIN DASHBOARD
// ========================
class AdminDashboard extends StatelessWidget {
  final UserModel user;
  const AdminDashboard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return _SimpleDashboard(
      user: user,
      roleColor: AppColors.cardBlue,
      emoji: '⚙️',
      actions: [
        _ActionItem('Add New Customer', Icons.person_add_outlined,
            AppColors.primary, () {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => const AddCustomerScreen()));
        }),
        _ActionItem(
            'View All Customers', Icons.people_outline, AppColors.cardBlue,
            () {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => const AllCustomersScreen()));
        }),
        _ActionItem(
            'Manage Workers', Icons.badge_outlined, AppColors.cardTeal, () {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => const ManageWorkersScreen()));
        }),
      ],
    );
  }
}

// ========================
// CANTEEN DASHBOARD
// ========================
class CanteenDashboard extends StatelessWidget {
  final UserModel user;
  const CanteenDashboard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return _SimpleDashboard(
      user: user,
      roleColor: AppColors.cardOrange,
      emoji: '🍽️',
      actions: [
        _ActionItem('View Today\'s Guests', Icons.groups_outlined,
            AppColors.cardOrange, () {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => const AllCustomersScreen()));
        }),
        _ActionItem(
            'All Bookings', Icons.book_online_outlined, AppColors.cardBlue,
            () {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => const AllCustomersScreen()));
        }),
      ],
    );
  }
}

class _ActionItem {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  _ActionItem(this.label, this.icon, this.color, this.onTap);
}

class _SimpleDashboard extends StatelessWidget {
  final UserModel user;
  final Color roleColor;
  final String emoji;
  final List<_ActionItem> actions;

  const _SimpleDashboard({
    required this.user,
    required this.roleColor,
    required this.emoji,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 20,
              left: 20,
              right: 20,
              bottom: 24,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [roleColor.withOpacity(0.85), roleColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$emoji Janki Agro Tourism',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    GestureDetector(
                      onTap: () async {
                        await AuthService().logout();
                        if (!context.mounted) return;
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                          (r) => false,
                        );
                      },
                      child: const Icon(Icons.logout,
                          color: Colors.white, size: 22),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Welcome, ${user.fullName}',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    user.roleDisplayName,
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quick Actions',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...actions.map((a) => _buildActionTile(a)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile(_ActionItem action) {
    return GestureDetector(
      onTap: action.onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: action.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(action.icon, color: action.color, size: 26),
            ),
            const SizedBox(width: 16),
            Text(
              action.label,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
            const Spacer(),
            Icon(Icons.arrow_forward_ios, color: action.color, size: 16),
          ],
        ),
      ),
    );
  }
}
