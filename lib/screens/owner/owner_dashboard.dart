import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../models/models.dart';
import '../../services/storage_service.dart';
import '../../utils/app_theme.dart';
import '../auth/login_screen.dart';
import '../shared/widgets.dart';
import '../manager/all_customers_screen.dart';
import '../manager/manage_workers_screen.dart';
import 'manage_packages_screen.dart';
import '../manager/manage_canteen_screen.dart';

class OwnerDashboard extends StatefulWidget {
  final UserModel user;
  const OwnerDashboard({super.key, required this.user});
  @override State<OwnerDashboard> createState() => _OwnerDashboardState();
}

class _OwnerDashboardState extends State<OwnerDashboard> {
  DateTime _date = DateTime.now();
  List<CustomerModel> _customers = [];
  List<UserModel> _managers = [];
  bool _loading = true, _calOpen = false;

  @override void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    _customers = await StorageService.instance.getCustomersByDate(_date);
    _managers  = await StorageService.instance.getAllManagers();
    setState(() => _loading = false);
  }

  double get _cash   => _customers.where((c)=>c.paymentMode==PaymentMode.cash).fold(0.0,(s,c)=>s+c.totalAmount);
  double get _online => _customers.where((c)=>c.paymentMode==PaymentMode.online).fold(0.0,(s,c)=>s+c.totalAmount);
  double get _total  => _cash + _online;
  int    get _guests => _customers.fold(0,(s,c)=>s+c.totalGuests);

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##,###', 'en_IN');
    final dateLabel = sameDay(_date, DateTime.now())
        ? 'Today – ${DateFormat('dd MMM yyyy').format(_date)}'
        : DateFormat('EEE, dd MMM yyyy').format(_date);

    return Scaffold(
      backgroundColor: const Color(0xFFF3EFF8),
      body: RefreshIndicator(
        onRefresh: _load, color: const Color(0xFF7B2D8B),
        child: CustomScrollView(slivers: [
          // ── Purple header ──────────────────────────────────────────
          SliverToBoxAdapter(child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF4A0060), Color(0xFF7B2D8B), Color(0xFFAB5CC4)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(bottom: false, child: Column(children: [
              Padding(padding: const EdgeInsets.fromLTRB(20,16,20,0),
                child: Row(children: [
                  Container(width:48,height:48,
                    decoration: BoxDecoration(color:Colors.white24,
                        borderRadius:BorderRadius.circular(14)),
                    child: Center(child: Text(widget.user.fullName[0].toUpperCase(),
                        style: GoogleFonts.poppins(fontSize:20,
                            fontWeight:FontWeight.w700,color:Colors.white)))),
                  const SizedBox(width:12),
                  Expanded(child: Column(crossAxisAlignment:CrossAxisAlignment.start,
                    children: [
                      Text('Owner Dashboard', style:GoogleFonts.poppins(
                          fontSize:11,color:Colors.white70)),
                      Text(widget.user.fullName, style:GoogleFonts.poppins(
                          fontSize:16,fontWeight:FontWeight.w700,color:Colors.white)),
                    ])),
                  GestureDetector(
                    onTap: () async {
                      await StorageService.instance.logout();
                      if (!mounted) return;
                      Navigator.pushAndRemoveUntil(context,
                          MaterialPageRoute(builder:(_)=>const LoginScreen()),(_)=>false);
                    },
                    child: Container(padding:const EdgeInsets.all(8),
                      decoration:BoxDecoration(color:Colors.white24,
                          borderRadius:BorderRadius.circular(10)),
                      child:const Icon(Icons.logout,color:Colors.white,size:20))),
                ])),
              const SizedBox(height:12),
              Padding(padding:const EdgeInsets.symmetric(horizontal:20),
                child: Row(children: [
                  Container(padding:const EdgeInsets.symmetric(horizontal:12,vertical:4),
                    decoration:BoxDecoration(color:Colors.white24,
                        borderRadius:BorderRadius.circular(20)),
                    child:Text('👑 ${widget.user.roleLabel}',style:GoogleFonts.poppins(
                        fontSize:11,fontWeight:FontWeight.w600,color:Colors.white))),
                ])),
              const SizedBox(height:14),
              // Date selector
              GestureDetector(
                onTap:()=>setState(()=>_calOpen=!_calOpen),
                child:Container(margin:const EdgeInsets.fromLTRB(16,0,16,16),
                  padding:const EdgeInsets.symmetric(horizontal:16,vertical:12),
                  decoration:BoxDecoration(color:Colors.white.withOpacity(0.15),
                      borderRadius:BorderRadius.circular(12),
                      border:Border.all(color:Colors.white30)),
                  child:Row(children:[
                    const Icon(Icons.calendar_today,color:Colors.white,size:18),
                    const SizedBox(width:10),
                    Expanded(child:Text(dateLabel,style:GoogleFonts.poppins(
                        fontSize:13,fontWeight:FontWeight.w600,color:Colors.white))),
                    Icon(_calOpen?Icons.expand_less:Icons.expand_more,color:Colors.white),
                  ]))),
            ])),
          )),

          // ── Calendar ───────────────────────────────────────────────
          if (_calOpen) SliverToBoxAdapter(child: Container(
            margin:const EdgeInsets.fromLTRB(16,0,16,8),
            decoration:BoxDecoration(color:Colors.white,
                borderRadius:BorderRadius.circular(16),
                boxShadow:[BoxShadow(color:Colors.black.withOpacity(0.08),blurRadius:12)]),
            child:TableCalendar(
              firstDay:DateTime(2020), lastDay:DateTime(2030), focusedDay:_date,
              selectedDayPredicate:(d)=>sameDay(d,_date),
              calendarFormat:CalendarFormat.month,
              headerStyle:HeaderStyle(formatButtonVisible:false,titleCentered:true,
                  titleTextStyle:GoogleFonts.poppins(fontWeight:FontWeight.w700,fontSize:14)),
              calendarStyle:const CalendarStyle(
                selectedDecoration:BoxDecoration(color:Color(0xFF7B2D8B),shape:BoxShape.circle),
                todayDecoration:BoxDecoration(color:Color(0x55AB5CC4),shape:BoxShape.circle)),
              onDaySelected:(sel,_){setState((){_date=sel;_calOpen=false;});_load();},
            ))),

          // ── Body ───────────────────────────────────────────────────
          SliverToBoxAdapter(child: Padding(
            padding:const EdgeInsets.all(16),
            child: _loading
              ? const Center(child:CircularProgressIndicator(color:Color(0xFF7B2D8B)))
              : Column(crossAxisAlignment:CrossAxisAlignment.start, children:[

              // Stats Grid
              Text('Transaction Details', style:GoogleFonts.poppins(
                  fontSize:15,fontWeight:FontWeight.w700,color:AppColors.textDark)),
              const SizedBox(height:10),
              // Total revenue wide card
              Container(
                padding:const EdgeInsets.all(18),
                decoration:BoxDecoration(
                  gradient:const LinearGradient(
                    colors:[Color(0xFF4A0060),Color(0xFF7B2D8B)],
                    begin:Alignment.topLeft,end:Alignment.bottomRight),
                  borderRadius:BorderRadius.circular(16),
                  boxShadow:[BoxShadow(color:const Color(0xFF7B2D8B).withOpacity(0.4),
                      blurRadius:12,offset:const Offset(0,6))]),
                child:Row(children:[
                  Container(width:52,height:52,
                    decoration:BoxDecoration(color:Colors.white24,
                        borderRadius:BorderRadius.circular(14)),
                    child:const Icon(Icons.currency_rupee,color:Colors.white,size:28)),
                  const SizedBox(width:14),
                  Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                    Text('Total Revenue',style:GoogleFonts.poppins(
                        fontSize:12,color:Colors.white70)),
                    Text('Rs.${fmt.format(_total)}',style:GoogleFonts.poppins(
                        fontSize:24,fontWeight:FontWeight.w700,color:Colors.white)),
                  ])),
                  Column(crossAxisAlignment:CrossAxisAlignment.end,children:[
                    Text('${_customers.length} bookings',style:GoogleFonts.poppins(
                        fontSize:11,color:Colors.white70)),
                    Text('$_guests guests',style:GoogleFonts.poppins(
                        fontSize:11,color:Colors.white70)),
                  ]),
                ])),
              const SizedBox(height:10),
              Row(children:[
                Expanded(child:_miniCard('Cash','Rs.${fmt.format(_cash)}',
                    Icons.money_outlined,const Color(0xFF40916C))),
                const SizedBox(width:10),
                Expanded(child:_miniCard('Online','Rs.${fmt.format(_online)}',
                    Icons.phone_android_outlined,const Color(0xFF4361EE))),
              ]),
              const SizedBox(height:20),

              // Batch Wise
              Text('Batch Wise', style:GoogleFonts.poppins(
                  fontSize:15,fontWeight:FontWeight.w700,color:AppColors.textDark)),
              const SizedBox(height:10),
              Container(
                decoration:BoxDecoration(color:Colors.white,
                    borderRadius:BorderRadius.circular(14),
                    boxShadow:[BoxShadow(color:Colors.black.withOpacity(0.05),blurRadius:8,offset:const Offset(0,3))]),
                child:Column(children:[
                  _bRow('Morning Batch', _count((c)=>c.packageName.contains('सकाळी')&&!c.packageName.contains('निवासी')), const Color(0xFFF4A261)),
                  _bRow('Evening Batch', _count((c)=>c.packageName.contains('सायंकाळी')&&!c.packageName.contains('निवासी')), const Color(0xFF7B2D8B)),
                  _bRow('Full Day',      _count((c)=>c.packageName.contains('फुल डे')), const Color(0xFF4361EE)),
                  _bRow('Stay',          _count((c)=>c.packageName.contains('निवासी')), const Color(0xFF0A9396)),
                ])),
              const SizedBox(height:20),

              // Manager Wise
              Text('Manager Wise', style:GoogleFonts.poppins(
                  fontSize:15,fontWeight:FontWeight.w700,color:AppColors.textDark)),
              const SizedBox(height:10),
              Container(
                decoration:BoxDecoration(color:Colors.white,
                    borderRadius:BorderRadius.circular(14),
                    boxShadow:[BoxShadow(color:Colors.black.withOpacity(0.05),blurRadius:8)]),
                child:_managers.isEmpty
                  ? Padding(padding:const EdgeInsets.all(16),
                      child:Text('No managers',style:GoogleFonts.poppins(color:AppColors.textLight)))
                  : Column(children:_managers.map((m){
                      final manCust=_customers.where((c)=>c.managerId==m.id).toList();
                      final guests=manCust.fold(0,(s,c)=>s+c.totalGuests);
                      final amt=manCust.fold(0.0,(s,c)=>s+c.totalAmount);
                      return _bRow(m.fullName,guests,const Color(0xFF40916C),
                          sub:'Rs.${fmt.format(amt)}');
                    }).toList())),
              const SizedBox(height:20),

              // Actions
              Text('Quick Actions', style:GoogleFonts.poppins(
                  fontSize:15,fontWeight:FontWeight.w700,color:AppColors.textDark)),
              const SizedBox(height:10),
              _act('View All Customers','All bookings',Icons.people_outline,const Color(0xFF4361EE),
                  ()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const AllCustomersScreen()))),
              _act('Manage Workers','Add staff, salary, attendance',Icons.badge_outlined,const Color(0xFF0A9396),
                  ()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const ManageWorkersScreen(ownerMode:true)))),
              _act('Manage Packages','Add / edit packages',Icons.category_outlined,const Color(0xFF7B2D8B),
                  ()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const ManagePackagesScreen()))),
              _act('Manage Canteen','Guest served, payments',Icons.restaurant_menu_outlined,const Color(0xFF0A9396),
                  ()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const ManageCanteenScreen()))),
              const SizedBox(height:30),
            ]),
          )),
        ]),
      ),
    );
  }

  int _count(bool Function(CustomerModel) f) =>
      _customers.where(f).fold(0,(s,c)=>s+c.totalGuests);

  Widget _miniCard(String label, String value, IconData icon, Color color) =>
    Container(
      padding:const EdgeInsets.all(14),
      decoration:BoxDecoration(
        gradient:LinearGradient(colors:[color,color.withOpacity(0.75)],
            begin:Alignment.topLeft,end:Alignment.bottomRight),
        borderRadius:BorderRadius.circular(14),
        boxShadow:[BoxShadow(color:color.withOpacity(0.3),blurRadius:8,offset:const Offset(0,4))]),
      child:Row(children:[
        Icon(icon,color:Colors.white,size:22),
        const SizedBox(width:10),
        Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text(label,style:GoogleFonts.poppins(fontSize:11,color:Colors.white70)),
          Text(value,style:GoogleFonts.poppins(fontSize:14,fontWeight:FontWeight.w700,color:Colors.white)),
        ]),
      ]));

  Widget _bRow(String label, int guests, Color color, {String? sub}) =>
    Container(
      padding:const EdgeInsets.symmetric(horizontal:16,vertical:12),
      decoration:BoxDecoration(border:Border(bottom:BorderSide(color:Colors.grey.shade100))),
      child:Row(children:[
        Container(width:34,height:34,
          decoration:BoxDecoration(color:color.withOpacity(0.1),borderRadius:BorderRadius.circular(9)),
          child:Icon(Icons.groups_outlined,color:color,size:18)),
        const SizedBox(width:12),
        Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text(label,style:GoogleFonts.poppins(fontSize:13,color:AppColors.textDark)),
          if(sub!=null) Text(sub,style:GoogleFonts.poppins(fontSize:11,color:AppColors.textLight)),
        ])),
        Container(
          padding:const EdgeInsets.symmetric(horizontal:12,vertical:4),
          decoration:BoxDecoration(color:color.withOpacity(0.1),borderRadius:BorderRadius.circular(20)),
          child:Text('$guests guests',style:GoogleFonts.poppins(
              fontSize:12,fontWeight:FontWeight.w700,color:color))),
      ]));

  Widget _act(String label, String sub, IconData icon, Color color, VoidCallback onTap) =>
    GestureDetector(
      onTap:onTap,
      child:Container(
        margin:const EdgeInsets.only(bottom:10),
        padding:const EdgeInsets.symmetric(horizontal:16,vertical:14),
        decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(14),
            boxShadow:[BoxShadow(color:Colors.black.withOpacity(0.05),blurRadius:8,offset:const Offset(0,3))]),
        child:Row(children:[
          Container(width:48,height:48,
            decoration:BoxDecoration(color:color.withOpacity(0.12),borderRadius:BorderRadius.circular(12)),
            child:Icon(icon,color:color,size:24)),
          const SizedBox(width:14),
          Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Text(label,style:GoogleFonts.poppins(fontSize:14,fontWeight:FontWeight.w600,color:AppColors.textDark)),
            Text(sub,style:GoogleFonts.poppins(fontSize:11,color:AppColors.textLight)),
          ])),
          Icon(Icons.chevron_right,color:color),
        ])));
}
