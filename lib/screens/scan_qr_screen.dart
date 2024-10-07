import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScanQrScreen extends StatelessWidget {
  const ScanQrScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Color(0xff1F2936),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(child: SizedBox()),
          SizedBox(
            height: MediaQuery.of(context).size.width * 0.9,
            width: MediaQuery.of(context).size.width * 0.9,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Color(0xff4277FF), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xff4277FF).withOpacity(0.75),
                    blurRadius: 8,
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: MobileScanner(
                  onDetect: (capture) {
                    final List<Barcode> barcodes = capture.barcodes;
                    for (final barcode in barcodes) {
                      print(barcode.rawValue ?? "No Data found in QR");
                    }
                  },
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                mainAxisSize: MainAxisSize.max,
                children: [
                  Text(
                    'John Doe',
                    style: TextStyle(color: Color(0xffFFFFFE), fontSize: 22, fontWeight: FontWeight.bold, shadows: [BoxShadow(color: Color(0xffFFFFFE).withOpacity(0.75), blurRadius: 4,)]),
                  ),
                  GestureDetector(
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
                            'Mark As Attached',
                            style: TextStyle(color: Color(0xffFFFFFE), fontSize: 18, fontWeight: FontWeight.bold, shadows: [BoxShadow(color: Color(0xffFFFFFE).withOpacity(0.75), blurRadius: 4,)]),
                          ),
                          SizedBox(width: 8,),
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
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
