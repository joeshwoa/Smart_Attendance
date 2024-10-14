import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:smart_attendance/cubit/app_cubit.dart';
import 'package:smart_attendance/model/person.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:intl/intl.dart';

class PersonsScreen extends StatefulWidget {
  const PersonsScreen({super.key});

  @override
  State<PersonsScreen> createState() => _PersonsScreenState();
}

class _PersonsScreenState extends State<PersonsScreen> {

  bool loadingGetting = false;
  bool loadingSharing = false;
  

  getData() async {
    setState(() {
      loadingGetting = true;
    });
    final supabase = Supabase.instance.client;
    final data = await supabase
        .from('people')
        .select();
    if(mounted) {
      context.read<AppCubit>().persons.clear();
      for (var element in data) {
        context.read<AppCubit>().persons.add(Person.fromJson(element));
      }
    }
    setState(() {
      loadingGetting = false;
    });
  }

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _birthDateController = TextEditingController();
  final RegExp dateRegExp = RegExp(r'^\d{2}-\d{2}-\d{4}$');

  String? _validateDate(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }

    // Check if the input matches dd-mm-yyyy format
    if (!dateRegExp.hasMatch(value)) {
      return 'Enter date in dd-mm-yyyy format';
    }

    final parts = value.split('-');
    final day = int.tryParse(parts[0]) ?? 0;
    final month = int.tryParse(parts[1]) ?? 0;
    final year = int.tryParse(parts[2]) ?? 0;

    if (day < 1 || day > 31) {
      return 'Invalid day';
    }
    if (month < 1 || month > 12) {
      return 'Invalid month';
    }
    if (year < 1900 || year > DateTime.now().year) {
      return 'Invalid year';
    }

    return null;
  }

  String _autoFormatDate(String value, bool isBackspace) {
    // Remove any non-digit characters from the input
    value = value.replaceAll(RegExp(r'\D'), '');

    // Apply formatting based on length
    if (value.length >= 2) {
      value = '${value.substring(0, 2)}-${value.substring(2)}';
    }
    if (value.length >= 5) {
      value = '${value.substring(0, 5)}-${value.substring(5)}';
    }

    // If backspace is pressed and there's a trailing hyphen, remove it
    if (isBackspace && value.endsWith('-')) {
      value = value.substring(0, value.length - 1);
    }

    // Limit the length to 10 characters (dd-mm-yyyy)
    if (value.length > 10) {
      value = value.substring(0, 10);
    }
    return value;
  }

  DateTime? convertToDateTime(String input) {
    // Check if the input matches the dd-mm-yyyy format using RegExp
    final RegExp dateRegExp = RegExp(r'^(\d{2})-(\d{2})-(\d{4})$');
    final match = dateRegExp.firstMatch(input);

    if (match != null) {
      // Extract day, month, and year from the input
      final day = int.tryParse(match.group(1)!);
      final month = int.tryParse(match.group(2)!);
      final year = int.tryParse(match.group(3)!);

      if (day != null && month != null && year != null) {
        // Create a DateTime object from the extracted values
        return DateTime(year, month, day);
      }
    }
    return null; // Return null if the input is invalid
  }

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool loadingSending = false;

  @override
  void initState() {
    getData();
    super.initState();
  }

  Future<void> _exportQRToImageAndShare(String qrData, bool popAfterFinish, Function calledAfterFinish) async {
    try {
      if(!loadingSharing) {
        setState(() {
          loadingSharing = true;
        });
        // Request storage permission if necessary
        var status1 = await Permission.storage.request();
        var status2 = await Permission.manageExternalStorage.request();
        if (!status1.isGranted && !status2.isGranted) {
          setState(() {
            loadingSharing = false;
          });
          calledAfterFinish();
          openAppSettings();
          //print("Storage permission not granted");
          return;
        }

        // Generate the QR code
        final qrPainter = QrPainter(
          data: qrData,
          version: QrVersions.auto,
          gapless: true,
          color: Colors.black,
          emptyColor: Colors.white,
        );

        // Get the directory to save the file
        final tempDir = await getTemporaryDirectory();
        final filePath = '${tempDir.path}/qr_code.png';
        final file = File(filePath);
        //print(file.path);

        // Create an image from the QR code
        final ui.Image picture = await qrPainter.toImage(300); // 300 is the image size

        // Add a border (padding) to the QR code image
        const borderSize = 20.0; // 20px border
        const borderColor = Color(0xff4277FF); // Border color other than black or white

        // Create a canvas to draw the QR code with the border
        final borderImage = await _addBorderToQRCode(picture, borderSize, borderColor);

        final byteData = await borderImage.toByteData(format: ui.ImageByteFormat.png);
        await file.writeAsBytes(byteData!.buffer.asUint8List());

        // Share the file
        await Share.shareXFiles([XFile(filePath)], text: 'Here is your QR code!');
        setState(() {
          loadingSharing = false;
        });
        calledAfterFinish();
        if(popAfterFinish) {
          if(mounted) {
            Navigator.pop(context);
          }
        }
      }
    } catch (e) {
      //print('Error generating or sharing QR code: $e');
      setState(() {
        loadingSharing = false;
      });
      calledAfterFinish();
    }
  }

  Future<ui.Image> _addBorderToQRCode(ui.Image qrImage, double borderSize, Color borderColor) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Define the size of the image with border
    final size = Size(
      qrImage.width.toDouble() + borderSize * 2,
      qrImage.height.toDouble() + borderSize * 2,
    );

    // Draw the border background
    final borderPaint = Paint()..color = borderColor;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), borderPaint);

    // Draw the QR code in the center
    canvas.drawImage(qrImage, Offset(borderSize, borderSize), Paint());

    final picture = recorder.endRecording();
    return picture.toImage(size.width.toInt(), size.height.toInt());
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AppCubit, AppState>(
      listener: (context, state) {
        // TODO: implement listener
      },
      builder: (context, state) {
        return Container(
          color: const Color(0xff1F2936),
          padding: const EdgeInsets.all(8),
          child: loadingGetting? const Center(child: CircularProgressIndicator(),) : ListView.builder(
            itemBuilder: (context, index) => GestureDetector(
              onTap: () {
                showDialog(context: context, builder: (context) => StatefulBuilder(
                  builder: (context, setState) => Container(
                    color: const Color(0xff1F2936),
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
                                    color: const Color(0xff4277FF),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xff4277FF).withOpacity(0.75),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                  padding: const EdgeInsets.all(12),
                                  child: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xffFFFFFE),),
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _exportQRToImageAndShare(context.read<AppCubit>().persons[index].id.toString(), false, () {setState(() {});});
                                  });
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
                                  padding: const EdgeInsets.all(12),
                                  height: 50,
                                  width: 50,
                                  child: loadingSharing ? const CircularProgressIndicator(color: Color(0xffFFFFFE),) : const Icon(Icons.share_rounded, color: Color(0xffFFFFFE),),
                                ),
                              )
                            ],
                          ),
                          const SizedBox(height: 32,),
                          Align(
                            alignment: Alignment.center,
                            child: Container(
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: const Color(0xffFFFFFE),
                                  boxShadow: [
                                    BoxShadow(color: const Color(0xffFFFFFE).withOpacity(0.75), blurRadius: 8,)
                                  ]
                              ),
                              child: QrImageView(
                                data: context.read<AppCubit>().persons[index].id.toString(),
                                version: QrVersions.auto,
                                padding: const EdgeInsets.all(5),
                                size: MediaQuery.of(context).size.width * 0.9,
                              ),
                            ),
                          ),
                          const SizedBox(height: 32,),
                          Text(
                            context.read<AppCubit>().persons[index].name??'',
                            style: TextStyle(color: const Color(0xffFFFFFE), fontSize: 22, fontWeight: FontWeight.bold, shadows: [BoxShadow(color: const Color(0xffFFFFFE).withOpacity(0.75), blurRadius: 4,)]),
                          ),
                          const SizedBox(height: 4,),
                          if(context.read<AppCubit>().persons[index].birthDate != null)Row(
                            children: [
                              const Text(
                                'Birth Date: ',
                                style: TextStyle(color: Color(0xff4277FF), fontSize: 18, fontWeight: FontWeight.w400),
                              ),
                              const SizedBox(width: 4,),
                              Text(
                                '${context.read<AppCubit>().persons[index].birthDate!.day.toString().padLeft(2, '0')}/${context.read<AppCubit>().persons[index].birthDate!.month.toString().padLeft(2, '0')}/${context.read<AppCubit>().persons[index].birthDate!.year.toString().padLeft(4, '0')}',
                                style: const TextStyle(color: Color(0xffFFFFFE), fontSize: 18, fontWeight: FontWeight.w400),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4,),
                          if(context.read<AppCubit>().persons[index].address != null && context.read<AppCubit>().persons[index].address!.isNotEmpty)Row(
                            children: [
                              const Text(
                                'Address: ',
                                style: TextStyle(color: Color(0xff4277FF), fontSize: 18, fontWeight: FontWeight.w400),
                              ),
                              const SizedBox(width: 4,),
                              Text(
                                context.read<AppCubit>().persons[index].address??'',
                                style: const TextStyle(color: Color(0xffFFFFFE), fontSize: 18, fontWeight: FontWeight.w400),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4,),
                          if(context.read<AppCubit>().persons[index].phone != null && context.read<AppCubit>().persons[index].phone!.isNotEmpty)Row(
                            children: [
                              const Text(
                                'Phone: ',
                                style: TextStyle(color: Color(0xff4277FF), fontSize: 18, fontWeight: FontWeight.w400),
                              ),
                              const SizedBox(width: 4,),
                              Text(
                                context.read<AppCubit>().persons[index].phone??'',
                                style: const TextStyle(color: Color(0xffFFFFFE), fontSize: 18, fontWeight: FontWeight.w400),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4,),
                          if(context.read<AppCubit>().persons[index].lastAttendDate != null)Row(
                            children: [
                              const Text(
                                'Last Attendance: ',
                                style: TextStyle(color: Color(0xff4277FF), fontSize: 18, fontWeight: FontWeight.w400),
                              ),
                              const SizedBox(width: 4,),
                              Text(
                                '${context.read<AppCubit>().persons[index].lastAttendDate!.day.toString().padLeft(2, '0')}/${context.read<AppCubit>().persons[index].lastAttendDate!.month.toString().padLeft(2, '0')}/${context.read<AppCubit>().persons[index].lastAttendDate!.year.toString().padLeft(4, '0')}',
                                style: const TextStyle(color: Color(0xffFFFFFE), fontSize: 18, fontWeight: FontWeight.w400),
                              ),
                              const Expanded(child: SizedBox()),
                              Text(
                                context.read<AppCubit>().persons[index].lastAttendDate!.day == (DateTime.now().subtract(const Duration(days: 1))).day ? 'yesterday' : timeago.format(context.read<AppCubit>().persons[index].lastAttendDate!, locale: 'en'),
                                style: const TextStyle(color: Color(0xffFFFFFE), fontSize: 18, fontWeight: FontWeight.w400),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),);
              },
              child: Container(
                height: (MediaQuery.of(context).size.width * 0.2) + 16,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xff4277FF), width: 1),
                  color: const Color(0xff101826),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xff4277FF).withOpacity(0.75),
                      blurRadius: 8,
                    )
                  ],
                ),
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        showDialog(context: context, builder: (context) => StatefulBuilder(
                            builder: (context, setState) {
                              return Container(
                                color: Colors.black.withOpacity(0.75),
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
                                                  color: const Color(0xff4277FF),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: const Color(0xff4277FF).withOpacity(0.75),
                                                      blurRadius: 8,
                                                    ),
                                                  ],
                                                ),
                                                height: 50,
                                                width: 50,
                                                padding: const EdgeInsets.all(12),
                                                child: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xffFFFFFE),),
                                              ),
                                            ),
                                            GestureDetector(
                                              onTap: () {
                                                setState(() {
                                                  _exportQRToImageAndShare(context.read<AppCubit>().persons[index].id.toString(), true, () {setState(() {});});
                                                });
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
                                                height: 50,
                                                width: 50,
                                                padding: const EdgeInsets.all(12),
                                                child: loadingSharing ? const CircularProgressIndicator(color: Color(0xffFFFFFE),) : const Icon(Icons.share_rounded, color: Color(0xffFFFFFE),),
                                              ),
                                            )
                                          ],
                                        ),
                                      ),
                                      Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(8),
                                          color: const Color(0xffFFFFFE),
                                        ),
                                        child: QrImageView(
                                          data: context.read<AppCubit>().persons[index].id.toString(),
                                          version: QrVersions.auto,
                                          padding: const EdgeInsets.all(5),
                                          size: MediaQuery.of(context).size.width * 0.9,
                                        ),
                                      ),
                                      const Expanded(child: SizedBox())
                                    ],
                                  ),
                                ),
                              );
                            }
                        ),);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: const Color(0xffFFFFFE),
                          boxShadow: [
                            BoxShadow(color: const Color(0xffFFFFFE).withOpacity(0.75), blurRadius: 8,)
                          ],
                        ),
                        child: QrImageView(
                          data: context.read<AppCubit>().persons[index].id.toString(),
                          version: QrVersions.auto,
                          padding: const EdgeInsets.all(5),
                          size: MediaQuery.of(context).size.width * 0.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Text(
                          context.read<AppCubit>().persons[index].name!,
                          style: TextStyle(color: const Color(0xffFFFFFE), fontSize: 22, fontWeight: FontWeight.bold, shadows: [BoxShadow(color: const Color(0xffFFFFFE).withOpacity(0.75), blurRadius: 4,)]),
                        ),
                        if(context.read<AppCubit>().persons[index].lastAttendDate != null)Text(
                          context.read<AppCubit>().persons[index].lastAttendDate!.day == (DateTime.now().subtract(const Duration(days: 1))).day ? 'yesterday' : timeago.format(context.read<AppCubit>().persons[index].lastAttendDate!, locale: 'en'),
                          style: const TextStyle(color: Color(0xffFFFFFE), fontSize: 18, fontWeight: FontWeight.w400),
                        ),
                      ],
                    ),
                    const Expanded(child: SizedBox()),
                    GestureDetector(
                      onTap: () {
                        _nameController.text = context.read<AppCubit>().persons[index].name??'';
                        _addressController.text = context.read<AppCubit>().persons[index].address??'';
                        _phoneController.text = context.read<AppCubit>().persons[index].phone??'';
                        _birthDateController.text = context.read<AppCubit>().persons[index].birthDate != null ? DateFormat('dd-MM-yyyy').format(context.read<AppCubit>().persons[index].birthDate!) : '';
                        showDialog(context: context, builder: (context) => StatefulBuilder(
                            builder: (context, innerSetState) {
                              return Material(
                                child: Container(
                                  color: const Color(0xff1F2936),
                                  child: Padding(
                                    padding: const EdgeInsets.all(24),
                                    child: Form(
                                      key: _formKey,
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
                                                          color: const Color(0xff4277FF),
                                                          boxShadow: [
                                                            BoxShadow(
                                                              color: const Color(0xff4277FF).withOpacity(0.75),
                                                              blurRadius: 8,
                                                            ),
                                                          ],
                                                        ),
                                                        padding: const EdgeInsets.all(12),
                                                        child: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xffFFFFFE),),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              Text(
                                                'Edit',
                                                style: TextStyle(color: const Color(0xffFFFFFE), fontSize: 22, fontWeight: FontWeight.bold, shadows: [BoxShadow(color: const Color(0xffFFFFFE).withOpacity(0.75), blurRadius: 4,)]),
                                              ),
                                              const Expanded(
                                                child: SizedBox(),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 32,),
                                          TextFormField(
                                            controller: _nameController,
                                            decoration: InputDecoration(
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(8),
                                                  borderSide: const BorderSide(color: Color(0xff4277FF))
                                              ),
                                              hintText: 'Name',
                                              focusColor: const Color(0xff4277FF),
                                              hintStyle: TextStyle(
                                                color: const Color(0xffFFFFFE).withOpacity(0.75),
                                                fontSize: 18,
                                                fontWeight: FontWeight.w400,
                                              ),
                                            ),
                                            style: const TextStyle(
                                              color: Color(0xffFFFFFE),
                                              fontSize: 18,
                                              fontWeight: FontWeight.w400,
                                            ),
                                            keyboardType: TextInputType.name,
                                            validator: (value) {
                                              if(value == null || value.isEmpty) {
                                                return 'Must Enter Name';
                                              }
                                              return null;
                                            },
                                          ),
                                          const SizedBox(height: 8,),
                                          TextFormField(
                                            controller: _birthDateController,
                                            decoration: InputDecoration(
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(8),
                                                borderSide: const BorderSide(color: Color(0xff4277FF)),
                                              ),
                                              hintText: 'Birth Date (dd-mm-yyyy)',
                                              focusColor: const Color(0xff4277FF),
                                              hintStyle: TextStyle(
                                                color: const Color(0xffFFFFFE).withOpacity(0.75),
                                                fontSize: 18,
                                                fontWeight: FontWeight.w400,
                                              ),
                                            ),
                                            style: const TextStyle(
                                              color: Color(0xffFFFFFE),
                                              fontSize: 18,
                                              fontWeight: FontWeight.w400,
                                            ),
                                            keyboardType: TextInputType.number,
                                            inputFormatters: [
                                              FilteringTextInputFormatter.digitsOnly,
                                              LengthLimitingTextInputFormatter(10), // Limit input to 10 digits
                                              TextInputFormatter.withFunction((oldValue, newValue) {
                                                final isBackspace = oldValue.text.length > newValue.text.length;

                                                // Call auto-formatting function with the backspace flag
                                                final formattedValue = _autoFormatDate(newValue.text, isBackspace);

                                                return TextEditingValue(
                                                  text: formattedValue,
                                                  selection: TextSelection.collapsed(offset: formattedValue.length),
                                                );
                                              }),
                                            ],
                                            validator: _validateDate,
                                          ),
                                          const SizedBox(height: 8,),
                                          TextFormField(
                                            controller: _addressController,
                                            decoration: InputDecoration(
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(8),
                                                  borderSide: const BorderSide(color: Color(0xff4277FF))
                                              ),
                                              hintText: 'Address',
                                              focusColor: const Color(0xff4277FF),
                                              hintStyle: TextStyle(
                                                color: const Color(0xffFFFFFE).withOpacity(0.75),
                                                fontSize: 18,
                                                fontWeight: FontWeight.w400,
                                              ),
                                            ),
                                            style: const TextStyle(
                                              color: Color(0xffFFFFFE),
                                              fontSize: 18,
                                              fontWeight: FontWeight.w400,
                                            ),
                                            keyboardType: TextInputType.streetAddress,
                                          ),
                                          const SizedBox(height: 8,),
                                          TextFormField(
                                            controller: _phoneController,
                                            decoration: InputDecoration(
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(8),
                                                  borderSide: const BorderSide(color: Color(0xff4277FF))
                                              ),
                                              hintText: 'Phone',
                                              focusColor: const Color(0xff4277FF),
                                              hintStyle: TextStyle(
                                                color: const Color(0xffFFFFFE).withOpacity(0.75),
                                                fontSize: 18,
                                                fontWeight: FontWeight.w400,
                                              ),
                                            ),
                                            style: const TextStyle(
                                              color: Color(0xffFFFFFE),
                                              fontSize: 18,
                                              fontWeight: FontWeight.w400,
                                            ),
                                            keyboardType: TextInputType.phone,
                                          ),
                                          const Expanded(child: SizedBox()),
                                          Align(
                                            alignment: Alignment.bottomRight,
                                            child: GestureDetector(
                                              onTap: () async {
                                                if (_formKey.currentState!.validate() && !loadingSending) {
                                                  innerSetState(() {
                                                    loadingSending = true;
                                                  });
                                                  final supabase = Supabase.instance.client;
                                                  context.read<AppCubit>().persons[index].name = _nameController.text;
                                                  context.read<AppCubit>().persons[index].birthDate = convertToDateTime(_birthDateController.text);
                                                  context.read<AppCubit>().persons[index].address = _addressController.text;
                                                  context.read<AppCubit>().persons[index].phone = _phoneController.text;
                                                  //print(context.read<AppCubit>().persons[index].toJsonWithoutID());
                                                  await supabase
                                                      .from('people')
                                                      .update(context.read<AppCubit>().persons[index].toJsonWithoutID())
                                                      .eq('id', context.read<AppCubit>().persons[index].id!);
                                                  _formKey.currentState!.reset();
                                                  innerSetState(() {
                                                    loadingSending = false;
                                                  });
                                                  if(context.mounted) {
                                                    Navigator.pop(context);
                                                  }
                                                  setState(() {});
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
                                                      'Save',
                                                      style: TextStyle(color: const Color(0xffFFFFFE), fontSize: 22, fontWeight: FontWeight.bold, shadows: [BoxShadow(color: const Color(0xffFFFFFE).withOpacity(0.75), blurRadius: 4,)]),
                                                    ),
                                                    const SizedBox(width: 64,),
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
                                            ),
                                          )
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }
                        ),);
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
                        padding: const EdgeInsets.all(12),
                        child: Icon(
                          Icons.edit_rounded,
                          color: const Color(0xffFFFFFE),
                          shadows: [
                            BoxShadow(
                              color: const Color(0xffFFFFFE).withOpacity(0.75),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
            itemCount: context.read<AppCubit>().persons.length,
          ),
        );
      },
    );
  }
}
