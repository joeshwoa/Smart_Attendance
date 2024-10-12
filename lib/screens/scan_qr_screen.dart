import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:smart_attendance/model/person.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ScanQrScreen extends StatefulWidget {
  const ScanQrScreen({super.key});

  @override
  State<ScanQrScreen> createState() => _ScanQrScreenState();
}

class _ScanQrScreenState extends State<ScanQrScreen> {

  Person? foundedPerson;

  bool loadingGetting = false;
  bool loadingSending = false;

  bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xff1F2936),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Expanded(child: SizedBox()),
          SizedBox(
            height: MediaQuery.of(context).size.width * 0.9,
            width: MediaQuery.of(context).size.width * 0.9,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xff4277FF), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xff4277FF).withOpacity(0.75),
                    blurRadius: 8,
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    MobileScanner(
                      onDetect: (capture) async {
                        final List<Barcode> barcodes = capture.barcodes;
                        for (final barcode in barcodes) {
                          if(!loadingGetting) {
                            //print(barcode.rawValue ?? "No Data found in QR");
                            final supabase = Supabase.instance.client;
                            setState(() {
                              loadingGetting = true;
                            });
                            final data = await supabase
                                .from('people')
                                .select()
                                .eq('id', barcode.rawValue?? '');
                            for (var element in data) {
                              foundedPerson = Person.fromJson(element);
                            }
                            setState(() {
                              loadingGetting = false;
                            });
                          }
                        }
                      },
                    ),
                    if(loadingGetting)const Center(child: CircularProgressIndicator(color: Color(0xff4277FF),),)
                  ],
                ),
              ),
            ),
          ),
          if(foundedPerson != null)Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                mainAxisSize: MainAxisSize.max,
                children: [
                  Text(
                    foundedPerson!.name??'',
                    style: TextStyle(color: const Color(0xffFFFFFE), fontSize: 22, fontWeight: FontWeight.bold, shadows: [BoxShadow(color: const Color(0xffFFFFFE).withOpacity(0.75), blurRadius: 4,)]),
                  ),
                  GestureDetector(
                    onTap: () async {
                      if(!loadingSending) {
                        setState(() {
                          loadingSending = true;
                        });
                        if (foundedPerson!.lastAttendDate == null || (foundedPerson!.lastAttendDate != null && !isSameDay(foundedPerson!.lastAttendDate!, DateTime.now())) ) {
                          foundedPerson!.lastAttendDate = DateTime.now();
                          foundedPerson!.attendance!.add(DateTime.now());
                          final supabase = Supabase.instance.client;
                          await supabase
                              .from('people')
                              .update(foundedPerson!.toJsonWithoutID())
                              .eq('id', foundedPerson!.id??'');
                        }
                        foundedPerson = null;
                        setState(() {
                          loadingSending = false;
                        });
                      }

                    },
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: const Color(0xff4277FF),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xff4277FF).withOpacity(0.75),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(8),
                      child: loadingSending ? const CircularProgressIndicator(color: Color(0xffFFFFFE),) : Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Mark As Attached',
                            style: TextStyle(color: const Color(0xffFFFFFE), fontSize: 18, fontWeight: FontWeight.bold, shadows: [BoxShadow(color: const Color(0xffFFFFFE).withOpacity(0.75), blurRadius: 4,)]),
                          ),
                          const SizedBox(width: 8,),
                          Icon(
                            Icons.done_outline_rounded,
                            color: const Color(0xffFFFFFE),
                            shadows: [
                              BoxShadow(
                                color: const Color(0xffFFFFFE).withOpacity(0.75),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
          if(foundedPerson == null)const Expanded(child: SizedBox()),
        ],
      ),
    );
  }
}
