import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/models.dart';
import '../../services/storage_service.dart';
import '../../utils/app_theme.dart';
import '../shared/widgets.dart';

class ManagePackagesScreen extends StatefulWidget {
  const ManagePackagesScreen({super.key});
  @override State<ManagePackagesScreen> createState() => _ManagePackagesScreenState();
}
class _ManagePackagesScreenState extends State<ManagePackagesScreen> {
  List<PackageModel> _packages = [];
  bool _loading = true;

  @override void initState(){ super.initState(); _load(); }
  Future<void> _load() async {
    setState(()=>_loading=true);
    _packages = await StorageService.instance.getPackages();
    setState(()=>_loading=false);
  }

  void _showForm({PackageModel? pkg}) {
    final nameC  = TextEditingController(text:pkg?.name??'');
    final timeC  = TextEditingController(text:pkg?.timeSlot??'');
    final adultC = TextEditingController(text:pkg?.adultPrice.toStringAsFixed(0)??'');
    final childC = TextEditingController(text:pkg?.childPrice.toStringAsFixed(0)??'');
    bool breakfast = pkg?.breakfast??false;
    bool lunch     = pkg?.lunch??false;
    bool snacks    = pkg?.snacks??false;
    bool dinner    = pkg?.dinner??false;
    bool isStay    = pkg?.isStay??false;

    showModalBottomSheet(context:context,isScrollControlled:true,
      backgroundColor:Colors.transparent,
      builder:(ctx)=>StatefulBuilder(builder:(ctx,setSt)=>Padding(
        padding:EdgeInsets.only(bottom:MediaQuery.of(ctx).viewInsets.bottom),
        child:Container(
          decoration:const BoxDecoration(color:Colors.white,
              borderRadius:BorderRadius.vertical(top:Radius.circular(20))),
          padding:const EdgeInsets.all(20),
          child:SingleChildScrollView(child:Column(
            mainAxisSize:MainAxisSize.min,
            crossAxisAlignment:CrossAxisAlignment.start,
            children:[
              Text(pkg==null?'Add Package':'Edit Package',
                  style:GoogleFonts.poppins(fontSize:18,fontWeight:FontWeight.w700)),
              const SizedBox(height:14),
              TextField(controller:nameC,
                  decoration:const InputDecoration(labelText:'Package Name')),
              const SizedBox(height:10),
              TextField(controller:timeC,
                  decoration:const InputDecoration(labelText:'Time Slot')),
              const SizedBox(height:10),
              Row(children:[
                Expanded(child:TextField(controller:adultC,
                    keyboardType:TextInputType.number,
                    decoration:const InputDecoration(labelText:'Adult Price ₹'))),
                const SizedBox(width:10),
                Expanded(child:TextField(controller:childC,
                    keyboardType:TextInputType.number,
                    decoration:const InputDecoration(labelText:'Child Price ₹'))),
              ]),
              const SizedBox(height:10),
              Text('Food Included:',style:GoogleFonts.poppins(
                  fontWeight:FontWeight.w600,fontSize:13,color:AppColors.textDark)),
              CheckboxListTile(value:breakfast,title:const Text('Breakfast'),
                  activeColor:AppColors.primary,contentPadding:EdgeInsets.zero,
                  onChanged:(v)=>setSt(()=>breakfast=v!)),
              CheckboxListTile(value:lunch,title:const Text('Lunch'),
                  activeColor:AppColors.primary,contentPadding:EdgeInsets.zero,
                  onChanged:(v)=>setSt(()=>lunch=v!)),
              CheckboxListTile(value:snacks,title:const Text('Snacks'),
                  activeColor:AppColors.primary,contentPadding:EdgeInsets.zero,
                  onChanged:(v)=>setSt(()=>snacks=v!)),
              CheckboxListTile(value:dinner,title:const Text('Dinner'),
                  activeColor:AppColors.primary,contentPadding:EdgeInsets.zero,
                  onChanged:(v)=>setSt(()=>dinner=v!)),
              CheckboxListTile(value:isStay,
                  title:const Text('Stay Package'),
                  activeColor:AppColors.primary,contentPadding:EdgeInsets.zero,
                  onChanged:(v)=>setSt(()=>isStay=v!)),
              const SizedBox(height:16),
              ElevatedButton(
                onPressed:() async {
                  if(nameC.text.isEmpty) return;
                  final p = PackageModel(
                    id: pkg?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                    name:nameC.text.trim(), timeSlot:timeC.text.trim(),
                    breakfast:breakfast, lunch:lunch, snacks:snacks, dinner:dinner,
                    adultPrice:double.tryParse(adultC.text)??0,
                    childPrice:double.tryParse(childC.text)??0,
                    isStay:isStay,
                  );
                  await StorageService.instance.savePackage(p);
                  if(ctx.mounted) Navigator.pop(ctx);
                  _load();
                },
                style:ElevatedButton.styleFrom(minimumSize:const Size(double.infinity,46)),
                child:Text(pkg==null?'Add Package':'Update Package'),
              ),
              const SizedBox(height:10),
            ],
          )),
        ),
      )));
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      backgroundColor:AppColors.background,
      appBar:AppBar(
        title:const Text('Manage Packages'),
        leading:IconButton(
            icon:const Icon(Icons.arrow_back_ios,color:Colors.white,size:18),
            onPressed:()=>Navigator.pop(context)),
        actions:[
          IconButton(icon:const Icon(Icons.refresh,color:Colors.white),onPressed:_load),
        ],
      ),
      floatingActionButton:FloatingActionButton.extended(
        onPressed:()=>_showForm(),
        backgroundColor:AppColors.primary,
        icon:const Icon(Icons.add,color:Colors.white),
        label:Text('Add Package',style:GoogleFonts.poppins(
            color:Colors.white,fontWeight:FontWeight.w600)),
      ),
      body:_loading
          ? const Center(child:CircularProgressIndicator(color:AppColors.primary))
          : _packages.isEmpty
              ? Center(child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[
                  Icon(Icons.category_outlined,size:56,color:Colors.grey.shade300),
                  const SizedBox(height:10),
                  Text('No packages yet',
                      style:GoogleFonts.poppins(color:AppColors.textLight)),
                ]))
              : ListView.builder(
                  padding:const EdgeInsets.fromLTRB(14,14,14,100),
                  itemCount:_packages.length,
                  itemBuilder:(_,i){
                    final p=_packages[i];
                    return Container(
                      margin:const EdgeInsets.only(bottom:10),
                      padding:const EdgeInsets.all(14),
                      decoration:BoxDecoration(
                        color:Colors.white,
                        borderRadius:BorderRadius.circular(14),
                        boxShadow:[BoxShadow(
                            color:Colors.black.withOpacity(0.05),
                            blurRadius:6,offset:const Offset(0,2))],
                      ),
                      child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                        Row(children:[
                          Expanded(child:Text(p.name,style:GoogleFonts.poppins(
                              fontSize:13,fontWeight:FontWeight.w700,
                              color:AppColors.textDark))),
                          IconButton(
                            icon:const Icon(Icons.edit_outlined,
                                color:AppColors.cardBlue,size:20),
                            padding:EdgeInsets.zero,
                            constraints:const BoxConstraints(),
                            onPressed:()=>_showForm(pkg:p)),
                          const SizedBox(width:8),
                          IconButton(
                            icon:const Icon(Icons.delete_outline,
                                color:AppColors.error,size:20),
                            padding:EdgeInsets.zero,
                            constraints:const BoxConstraints(),
                            onPressed:() async {
                              await StorageService.instance.deletePackage(p.id);
                              _load();
                            }),
                        ]),
                        const SizedBox(height:3),
                        Text('⏰ ${p.timeSlot}',style:GoogleFonts.poppins(
                            fontSize:11,color:AppColors.textLight)),
                        const SizedBox(height:6),
                        Wrap(spacing:6,children:[
                          if(p.breakfast) _tag('🍽️ Breakfast'),
                          if(p.lunch)     _tag('🍛 Lunch'),
                          if(p.snacks)    _tag('☕ Snacks'),
                          if(p.dinner)    _tag('🌙 Dinner'),
                          if(p.isStay)    _tag('🏨 Stay'),
                        ]),
                        const SizedBox(height:6),
                        Row(children:[
                          _price('👶 ₹${p.childPrice.toStringAsFixed(0)}'),
                          const SizedBox(width:8),
                          _price('🧑 ₹${p.adultPrice.toStringAsFixed(0)}'),
                        ]),
                      ]),
                    );
                  }),
    );
  }

  Widget _tag(String t) => Container(
    padding:const EdgeInsets.symmetric(horizontal:8,vertical:2),
    decoration:BoxDecoration(
        color:AppColors.primary.withOpacity(0.08),
        borderRadius:BorderRadius.circular(6)),
    child:Text(t,style:GoogleFonts.poppins(fontSize:10,color:AppColors.primary)),
  );

  Widget _price(String t) => Container(
    padding:const EdgeInsets.symmetric(horizontal:10,vertical:4),
    decoration:BoxDecoration(
        color:const Color(0xFFFAEEDA),
        borderRadius:BorderRadius.circular(20)),
    child:Text(t,style:GoogleFonts.poppins(
        fontSize:11,fontWeight:FontWeight.w600,
        color:const Color(0xFFB88B1A))),
  );
}
