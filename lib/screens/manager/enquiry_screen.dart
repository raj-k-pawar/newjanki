import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../models/models.dart';
import '../../services/storage_service.dart';
import '../../utils/app_theme.dart';
import '../shared/widgets.dart';

class EnquiryScreen extends StatefulWidget {
  const EnquiryScreen({super.key});
  @override State<EnquiryScreen> createState() => _EnquiryScreenState();
}
class _EnquiryScreenState extends State<EnquiryScreen> {
  final _nameC  = TextEditingController();
  final _cityC  = TextEditingController();
  final _phoneC = TextEditingController();
  DateTime _enquiryDate = DateTime.now();
  DateTime _filterDate  = DateTime.now();
  List<EnquiryModel> _list = [];
  bool _saving = false;

  @override void initState(){ super.initState(); _load(); }

  Future<void> _load() async {
    final list = await StorageService.instance.getEnquiriesByDate(_filterDate);
    setState(()=> _list = list);
  }

  Future<void> _save() async {
    if(_nameC.text.trim().isEmpty){
      showSnack(context,'Enter name',error:true); return;
    }
    setState(()=>_saving=true);
    final e = EnquiryModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameC.text.trim(), city: _cityC.text.trim(),
      phone: _phoneC.text.trim(), date: _enquiryDate,
      createdAt: DateTime.now(),
    );
    await StorageService.instance.addEnquiry(e);
    _nameC.clear(); _cityC.clear(); _phoneC.clear();
    setState(()=>_saving=false);
    _load();
    showSnack(context,'Enquiry saved!');
  }

  Future<void> _pickDate(bool isEnquiryDate) async {
    final picked = await showDatePickerDialog(context,
        initial: isEnquiryDate ? _enquiryDate : _filterDate);
    if (picked != null) {
      setState(() {
        if (isEnquiryDate) _enquiryDate = picked;
        else { _filterDate = picked; _load(); }
      });
    }
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      backgroundColor:AppColors.background,
      appBar:AppBar(
        title:const Text('Enquiries'),
        leading:IconButton(icon:const Icon(Icons.arrow_back_ios,color:Colors.white,size:18),
            onPressed:()=>Navigator.pop(context)),
      ),
      body:SingleChildScrollView(
        padding:const EdgeInsets.all(16),
        child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          const SectionHeader('Add Enquiry',icon:Icons.person_search_outlined),
          WhiteCard(child:Column(children:[
            TextField(controller:_nameC,decoration:const InputDecoration(
                labelText:'Name *',prefixIcon:Icon(Icons.person_outline,color:AppColors.primary,size:18))),
            const SizedBox(height:10),
            TextField(controller:_cityC,decoration:const InputDecoration(
                labelText:'City (optional)',prefixIcon:Icon(Icons.location_city_outlined,color:AppColors.primary,size:18))),
            const SizedBox(height:10),
            TextField(controller:_phoneC,keyboardType:TextInputType.phone,
                decoration:const InputDecoration(
                    labelText:'Mobile (optional)',prefixIcon:Icon(Icons.phone_outlined,color:AppColors.primary,size:18))),
            const SizedBox(height:10),
            GestureDetector(onTap:()=>_pickDate(true),
              child:Container(padding:const EdgeInsets.all(12),
                decoration:BoxDecoration(
                    border:Border.all(color:Colors.grey.shade300),
                    borderRadius:BorderRadius.circular(10)),
                child:Row(children:[
                  const Icon(Icons.calendar_today,color:AppColors.primary,size:16),
                  const SizedBox(width:8),
                  Text(DateFormat('dd MMM yyyy').format(_enquiryDate),
                      style:GoogleFonts.poppins(fontSize:13)),
                  const Spacer(),
                  Text('Tap to change',style:GoogleFonts.poppins(fontSize:11,color:AppColors.textLight)),
                ]))),
            const SizedBox(height:14),
            PrimaryButton(label:'Save Enquiry',icon:Icons.save_outlined,
                loading:_saving,onTap:_save),
          ])),

          const SizedBox(height:6),
          Row(children:[
            const SectionHeader('Enquiries for'),
            const SizedBox(width:8),
            GestureDetector(onTap:()=>_pickDate(false),
              child:Container(
                padding:const EdgeInsets.symmetric(horizontal:10,vertical:4),
                decoration:BoxDecoration(
                    color:AppColors.primary,borderRadius:BorderRadius.circular(8)),
                child:Row(children:[
                  Text(DateFormat('dd MMM').format(_filterDate),
                      style:GoogleFonts.poppins(fontSize:12,color:Colors.white,fontWeight:FontWeight.w600)),
                  const SizedBox(width:4),
                  const Icon(Icons.edit_calendar_outlined,color:Colors.white,size:13),
                ]))),
          ]),
          const SizedBox(height:10),

          if(_list.isEmpty)
            Container(
              padding:const EdgeInsets.all(20),
              decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(12)),
              child:Center(child:Text('No enquiries for this date',
                  style:GoogleFonts.poppins(color:AppColors.textLight))))
          else
            ..._list.map((e)=>Container(
              margin:const EdgeInsets.only(bottom:8),
              padding:const EdgeInsets.all(12),
              decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(10),
                  boxShadow:[BoxShadow(color:Colors.black.withOpacity(0.05),blurRadius:5)]),
              child:Row(children:[
                CircleAvatar(radius:18,backgroundColor:AppColors.accent.withOpacity(0.15),
                  child:Text(e.name[0].toUpperCase(),style:GoogleFonts.poppins(
                      fontSize:14,fontWeight:FontWeight.w700,color:AppColors.accent))),
                const SizedBox(width:10),
                Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                  Text(e.name,style:GoogleFonts.poppins(fontSize:13,fontWeight:FontWeight.w600)),
                  if(e.city.isNotEmpty||e.phone.isNotEmpty)
                    Text('${e.city}${e.city.isNotEmpty&&e.phone.isNotEmpty?" • ":""}${e.phone}',
                        style:GoogleFonts.poppins(fontSize:11,color:AppColors.textLight)),
                ])),
                Text(DateFormat('hh:mm a').format(e.createdAt),
                    style:GoogleFonts.poppins(fontSize:11,color:AppColors.textLight)),
              ]),
            )),
          const SizedBox(height:30),
        ]),
      ),
    );
  }
}
