import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:timeago/timeago.dart' as timeago;

class PersonsScreen extends StatelessWidget {
  const PersonsScreen({super.key});

  Future<void> _exportQRToImageAndShare(String qrData) async {
    try {
      // Request storage permission if necessary
      var status = await Permission.storage.request();
      if (!status.isGranted) {
        return;
      }

      // Generate the QR code
      final qrPainter = QrPainter(
        data: qrData,
        version: QrVersions.auto,
        gapless: false,
      );

      // Get the directory to save the file
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/qr_code.png';
      final file = File(filePath);

      // Create an image from the QR code
      final picture = await qrPainter.toImage(300); // 300 is the image size
      final byteData = await picture.toByteData(format: ImageByteFormat.png);
      await file.writeAsBytes(byteData!.buffer.asUint8List());

      // Share the file
      await Share.shareXFiles([XFile(filePath)], text: 'Here is your QR code!');
    } catch (e) {
      print('Error generating or sharing QR code: $e');
    }
  }


  @override
  Widget build(BuildContext context) {
    return Container(
      color: Color(0xff1F2936),
      padding: EdgeInsets.all(8),
      child: ListView(
        children: [
          GestureDetector(
            onTap: () {
              showDialog(context: context, builder: (context) => Container(
                color: Color(0xff1F2936),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: Color(0xff4277FF),
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0xff4277FF).withOpacity(0.75),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              padding: EdgeInsets.all(12),
                              child: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xffFFFFFE),),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              _exportQRToImageAndShare('1');
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: Color(0xff4277FF),
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0xff4277FF).withOpacity(0.75),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              padding: EdgeInsets.all(12),
                              child: const Icon(Icons.share_rounded, color: Color(0xffFFFFFE),),
                            ),
                          )
                        ],
                      ),
                      SizedBox(height: 32,),
                      Align(
                        alignment: Alignment.center,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Color(0xffFFFFFE),
                            boxShadow: [
                              BoxShadow(color: Color(0xffFFFFFE).withOpacity(0.75), blurRadius: 8,)
                            ]
                          ),
                          child: QrImageView(
                            data: '1',
                            version: QrVersions.auto,
                            padding: EdgeInsets.all(5),
                            size: MediaQuery.of(context).size.width * 0.9,
                          ),
                        ),
                      ),
                      SizedBox(height: 32,),
                      Text(
                        'John Doe',
                        style: TextStyle(color: Color(0xffFFFFFE), fontSize: 22, fontWeight: FontWeight.bold, shadows: [BoxShadow(color: Color(0xffFFFFFE).withOpacity(0.75), blurRadius: 4,)]),
                      ),
                      SizedBox(height: 4,),
                      Row(
                        children: [
                          Text(
                            'Birth Date: ',
                            style: TextStyle(color: Color(0xff4277FF), fontSize: 18, fontWeight: FontWeight.w400),
                          ),
                          SizedBox(width: 4,),
                          Text(
                            '12/03/2006',
                            style: TextStyle(color: Color(0xffFFFFFE), fontSize: 18, fontWeight: FontWeight.w400),
                          ),
                        ],
                      ),
                      SizedBox(height: 4,),
                      Row(
                        children: [
                          Text(
                            'Address: ',
                            style: TextStyle(color: Color(0xff4277FF), fontSize: 18, fontWeight: FontWeight.w400),
                          ),
                          SizedBox(width: 4,),
                          Text(
                            '17 ش ترعة الجبل حدائق القبة',
                            style: TextStyle(color: Color(0xffFFFFFE), fontSize: 18, fontWeight: FontWeight.w400),
                          ),
                        ],
                      ),
                      SizedBox(height: 4,),
                      Row(
                        children: [
                          Text(
                            'Last Attendance: ',
                            style: TextStyle(color: Color(0xff4277FF), fontSize: 18, fontWeight: FontWeight.w400),
                          ),
                          SizedBox(width: 4,),
                          Text(
                            '12/03/2006',
                            style: TextStyle(color: Color(0xffFFFFFE), fontSize: 18, fontWeight: FontWeight.w400),
                          ),
                          Expanded(child: SizedBox()),
                          Text(
                            '${timeago.format(DateTime.now().subtract(Duration(days: 77)), locale: 'en_short')} ago',
                            style: TextStyle(color: Color(0xffFFFFFE), fontSize: 18, fontWeight: FontWeight.w400),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),);
            },
            child: Container(
              height: (MediaQuery.of(context).size.width * 0.2) + 16,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Color(0xff4277FF), width: 1),
                color: Color(0xff101826),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xff4277FF).withOpacity(0.75),
                    blurRadius: 8,
                  )
                ],
              ),
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      showDialog(context: context, builder: (context) => Container(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              Expanded(
                                child: Row(
                                  mainAxisSize: MainAxisSize.max,
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.pop(context);
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(8),
                                          color: Color(0xff4277FF),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Color(0xff4277FF).withOpacity(0.75),
                                              blurRadius: 8,
                                            ),
                                          ],
                                        ),
                                        padding: EdgeInsets.all(12),
                                        child: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xffFFFFFE),),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        _exportQRToImageAndShare('1');
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(8),
                                          color: Color(0xff4277FF),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Color(0xff4277FF).withOpacity(0.75),
                                              blurRadius: 8,
                                            ),
                                          ],
                                        ),
                                        padding: EdgeInsets.all(12),
                                        child: const Icon(Icons.share_rounded, color: Color(0xffFFFFFE),),
                                      ),
                                    )
                                  ],
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: Color(0xffFFFFFE),
                                ),
                                child: QrImageView(
                                  data: '1',
                                  version: QrVersions.auto,
                                  padding: EdgeInsets.all(5),
                                  size: MediaQuery.of(context).size.width * 0.9,
                                ),
                              ),
                              Expanded(child: SizedBox())
                            ],
                          ),
                        ),
                        color: Colors.black.withOpacity(0.75),
                      ),);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Color(0xffFFFFFE),
                        boxShadow: [
                            BoxShadow(color: Color(0xffFFFFFE).withOpacity(0.75), blurRadius: 8,)
                          ],
                      ),
                      child: QrImageView(
                        data: '1234567890',
                        version: QrVersions.auto,
                        padding: EdgeInsets.all(5),
                        size: MediaQuery.of(context).size.width * 0.2,
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Text(
                        'John Doe',
                        style: TextStyle(color: Color(0xffFFFFFE), fontSize: 22, fontWeight: FontWeight.bold, shadows: [BoxShadow(color: Color(0xffFFFFFE).withOpacity(0.75), blurRadius: 4,)]),
                      ),
                      Text(
                        timeago.format(DateTime.now().subtract(Duration(days: 77)), locale: 'en_short'),
                        style: TextStyle(color: Color(0xffFFFFFE), fontSize: 18, fontWeight: FontWeight.w400),
                      ),
                    ],
                  ),
                  Expanded(child: SizedBox()),
                  GestureDetector(
                    onTap: () {
                      showDialog(context: context, builder: (context) => Material(
                        child: Container(
                          color: Color(0xff1F2936),
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.max,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.max,
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () {
                                          Navigator.pop(context);
                                        },
                                        child: Row(
                                          children: [
                                            Container(
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(8),
                                                color: Color(0xff4277FF),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Color(0xff4277FF).withOpacity(0.75),
                                                    blurRadius: 8,
                                                  ),
                                                ],
                                              ),
                                              padding: EdgeInsets.all(12),
                                              child: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xffFFFFFE),),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Text(
                                      'Edit',
                                      style: TextStyle(color: Color(0xffFFFFFE), fontSize: 22, fontWeight: FontWeight.bold, shadows: [BoxShadow(color: Color(0xffFFFFFE).withOpacity(0.75), blurRadius: 4,)]),
                                    ),
                                    Expanded(
                                      child: SizedBox(),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 32,),
                                TextFormField(
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(color: Color(0xff4277FF))
                                    ),
                                    hintText: 'Name',
                                    focusColor: Color(0xff4277FF),
                                    hintStyle: TextStyle(
                                      color: Color(0xffFFFFFE).withOpacity(0.75),
                                      fontSize: 18,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                  style: TextStyle(
                                    color: Color(0xffFFFFFE),
                                    fontSize: 18,
                                    fontWeight: FontWeight.w400,
                                  ),
                                  keyboardType: TextInputType.name,
                                ),
                                SizedBox(height: 8,),
                                TextFormField(
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(color: Color(0xff4277FF))
                                    ),
                                    hintText: 'Birth Date',
                                    focusColor: Color(0xff4277FF),
                                    hintStyle: TextStyle(
                                      color: Color(0xffFFFFFE).withOpacity(0.75),
                                      fontSize: 18,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                  style: TextStyle(
                                    color: Color(0xffFFFFFE),
                                    fontSize: 18,
                                    fontWeight: FontWeight.w400,
                                  ),
                                  keyboardType: TextInputType.datetime,
                                ),
                                SizedBox(height: 8,),
                                TextFormField(
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(color: Color(0xff4277FF))
                                    ),
                                    hintText: 'Address',
                                    focusColor: Color(0xff4277FF),
                                    hintStyle: TextStyle(
                                      color: Color(0xffFFFFFE).withOpacity(0.75),
                                      fontSize: 18,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                  style: TextStyle(
                                    color: Color(0xffFFFFFE),
                                    fontSize: 18,
                                    fontWeight: FontWeight.w400,
                                  ),
                                  keyboardType: TextInputType.streetAddress,
                                ),
                                Expanded(child: SizedBox()),
                                Align(
                                  alignment: Alignment.bottomRight,
                                  child: GestureDetector(
                                    onTap: () {

                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        color: Color(0xff4277FF),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Color(0xff4277FF).withOpacity(0.75),
                                            blurRadius: 8,
                                          ),
                                        ],
                                      ),
                                      padding: EdgeInsets.all(8),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'Save',
                                            style: TextStyle(color: Color(0xffFFFFFE), fontSize: 22, fontWeight: FontWeight.bold, shadows: [BoxShadow(color: Color(0xffFFFFFE).withOpacity(0.75), blurRadius: 4,)]),
                                          ),
                                          SizedBox(width: 64,),
                                          Icon(
                                            Icons.done_outline_rounded,
                                            color: Color(0xffFFFFFE),
                                            shadows: [
                                              BoxShadow(
                                                color: Color(0xffFFFFFE).withOpacity(0.75),
                                                blurRadius: 4,
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                      ),);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Color(0xff4277FF),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xff4277FF).withOpacity(0.75),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      padding: EdgeInsets.all(12),
                      child: Icon(
                        Icons.edit_rounded,
                        color: Color(0xffFFFFFE),
                        shadows: [
                          BoxShadow(
                            color: Color(0xffFFFFFE).withOpacity(0.75),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
