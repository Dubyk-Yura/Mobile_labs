import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_labs/page/home_cubit.dart';
import 'package:mobile_labs/page/home_state.dart';
import 'package:mobile_labs/page/qr_scanner.dart';
import 'package:mobile_labs/page/sensor_widget.dart';
import 'package:mqtt_client/mqtt_client.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Future<void> _scanQrCode(BuildContext context) async {
    final cubit = context.read<HomeCubit>();
    final result = await Navigator.push<Map<String, dynamic>?>(
      context,
      MaterialPageRoute<Map<String, dynamic>?>(
        builder: (context) => const QrScannerPage(),
      ),
    );

    if (result != null) {
      final login = result['login'];
      final password = result['password'];
      if (login != null && password != null) {
        if (cubit.mqttClient.connectionStatus!.state ==
            MqttConnectionState.connected) {
          cubit.sendConnectRequest(login.toString(), password.toString());
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => HomeCubit(),
      child: BlocListener<HomeCubit, HomeState>(
        listenWhen: (previous, current) =>
            previous.isOffline != current.isOffline,
        listener: (context, state) {
          if (state.isOffline) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('You are offline')),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Back online')),
            );
          }
        },
        child: BlocBuilder<HomeCubit, HomeState>(
          builder: (context, state) {
            return Scaffold(
              appBar: AppBar(
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'WiFi Status: ${state.isOffline ? 'Offline' : 'Online'}',
                      style: const TextStyle(fontSize: 18, color: Colors.white),
                    ),
                    Text(
                      'Server Status: ${state.serverStatus}',
                      style: const TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ],
                ),
                centerTitle: false,
                actions: [
                  TextButton.icon(
                    onPressed: () => _scanQrCode(context),
                    icon:
                        const Icon(Icons.qr_code_scanner, color: Colors.white),
                    label: const Text(
                      'Connect',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
              body: Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: state.sensors.length,
                      itemBuilder: (context, i) {
                        final sensor = state.sensors[i];
                        return SensorWidget(
                          sensorName: sensor.title,
                          values: sensor.values,
                          onUpdate: (_, values) {
                            context.read<HomeCubit>().updateSensor(i, values);
                          },
                          onDelete: () {
                            context.read<HomeCubit>().deleteSensor(i);
                          },
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          context.read<HomeCubit>().sendDisconnectRequest(),
                      icon: const Icon(Icons.power_settings_new),
                      label: const Text('Disconnect'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
