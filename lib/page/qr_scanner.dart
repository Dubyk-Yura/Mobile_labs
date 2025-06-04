import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QrScannerState {
  final MobileScannerController controller;

  QrScannerState({required this.controller});
}

class QrScannerCubit extends Cubit<QrScannerState> {
  QrScannerCubit()
      : super(QrScannerState(controller: MobileScannerController()));

  void handleBarcode(String rawValue, BuildContext context) {
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

  void onDetect(BarcodeCapture capture, BuildContext context) {
    final barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final rawValue = barcode.rawValue;
      if (rawValue != null) {
        handleBarcode(rawValue, context);
        state.controller.stop();
        break;
      }
    }
  }

  @override
  Future<void> close() {
    state.controller.dispose();
    return super.close();
  }
}

class QrScannerPage extends StatelessWidget {
  const QrScannerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => QrScannerCubit(),
      child: BlocBuilder<QrScannerCubit, QrScannerState>(
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(title: const Text('Scan QR Code')),
            body: MobileScanner(
              controller: state.controller,
              onDetect: (capture) =>
                  context.read<QrScannerCubit>().onDetect(capture, context),
            ),
          );
        },
      ),
    );
  }
}
