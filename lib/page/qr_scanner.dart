import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QrScannerPage extends StatefulWidget {
  const QrScannerPage({super.key});

  @override
  QrScannerPageState createState() => QrScannerPageState();
}

class QrScannerPageState extends State<QrScannerPage> {
  MobileScannerController controller = MobileScannerController();

  void handleBarcode(String rawValue) {
    try {
      final data = json.decode(rawValue);
      final login = data['login'];
      final password = data['password'];
      if (login != null && password != null) {
        Navigator.pop(context, {'login': login, 'password': password});
      }
    } catch (e) {
      // ignore errors from invalid QR codes
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan QR Code')),
      body: MobileScanner(
        controller: controller,
        onDetect: (capture) {
          final barcodes = capture.barcodes;
          for (final barcode in barcodes) {
            final rawValue = barcode.rawValue;
            if (rawValue != null) {
              handleBarcode(rawValue);
              controller.stop();
              break;
            }
          }
        },
      ),
    );
  }
}
