import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mobile_labs/page/qr_scanner.dart';
import 'package:mobile_labs/page/sensor.dart';
import 'package:mobile_labs/page/sensor_data.dart';
import 'package:mobile_labs/services/network_monitor.dart';
import 'package:mobile_labs/storage/storage.dart';
import 'package:mobile_labs/storage/storage_impl.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:typed_data/typed_data.dart';

final Storage localStorage = StorageImpl();
const _mqttBroker = 'broker.hivemq.com';
const _mqttPort = 1883;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late MqttServerClient _mqttClient;
  List<SensorData> sensors = [];
  String? userEmail;
  bool isOffline = false;
  Timer? _networkCheckTimer;
  bool isOnline = false;
  String? key_;

  final List<String> topics = [
    'sensor/lux',
    'sensor/temperature',
    'sensor/pressure',
    'sensor/humidity',
  ];

  void sendDisconnectRequest() {
    final buffer = Uint8Buffer();
    final disconnectPayload = jsonEncode({'key': 'none'});

    buffer.addAll(utf8.encode(disconnectPayload));

    try {
      _mqttClient.publishMessage(
        'sensor/disconnect',
        MqttQos.atLeastOnce,
        buffer,
      );
      setState(() {
        serverStatus = 'Offline';
      });
    } catch (e) {
      //
    }
  }

  void sendConnectRequest(String login, String password) {
    final buffer = Uint8Buffer();

    final connectPayload =
        '{"action":"connect_request","login":"$login","password":"$password"}';
    buffer.addAll(utf8.encode(connectPayload));

    _mqttClient.publishMessage(
      'sensor/connect',
      MqttQos.atLeastOnce,
      buffer,
    );
  }

  Future<void> scanQrCode() async {
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
        if (_mqttClient.connectionStatus!.state ==
            MqttConnectionState.connected) {
          sendConnectRequest(login.toString(), password.toString());
        } else {}
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _init();
    _startNetworkMonitor();
  }

  @override
  void dispose() {
    _mqttClient.disconnect();
    _networkCheckTimer?.cancel();
    super.dispose();
  }

  void _startNetworkMonitor() {
    _networkCheckTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      final hasConnection = await NetworkMonitor.checkConnection();
      if (hasConnection != !isOffline) {
        setState(() => isOffline = !hasConnection);
        if (!mounted) return;
        if (!hasConnection) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('You are offline')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Back online')),
          );
        }
      }
    });
  }

  Future<void> _init() async {
    userEmail = await localStorage.getCurrentUserEmail();
    await _loadSensors();

    if (sensors.isEmpty) {
      sensors = [
        SensorData(title: 'lux', values: []),
        SensorData(title: 'temperature', values: []),
        SensorData(title: 'pressure', values: []),
        SensorData(title: 'humidity', values: []),
      ];
      await _saveSensors();
    }

    setState(() {});
    await _setupMqtt();
  }

  Future<void> _loadSensors() async {
    sensors.clear();
    for (final topic in topics) {
      final data = await localStorage.readTopicData(userEmail!, topic);

      if (data != null && data['data'] != null && data['data'] is List) {
        final list = (data['data'] as List)
            .map((item) => SensorData.fromJson(item as Map<String, dynamic>))
            .toList();
        sensors.addAll(list);
      }
    }
  }

  Future<void> _saveSensors() async {
    final Map<String, List<SensorData>> grouped = {};
    for (var sensor in sensors) {
      final topic = 'sensor/${sensor.title}';
      grouped.putIfAbsent(topic, () => []).add(sensor);
    }

    for (final entry in grouped.entries) {
      final topic = entry.key;
      final jsonData = {
        'data': entry.value.map((e) => e.toJson()).toList(),
      };
      await localStorage.writeTopicData(userEmail!, topic, jsonData);
    }
  }

  String serverStatus = 'Offline';

  Future<void> _setupMqtt() async {
    final clientId = 'flutter_${DateTime.now().millisecondsSinceEpoch}';
    _mqttClient = MqttServerClient(_mqttBroker, clientId);
    _mqttClient.port = _mqttPort;
    _mqttClient.logging(on: false);

    try {
      await _mqttClient.connect();
    } catch (e) {
      _mqttClient.disconnect();
      return;
    }

    if (_mqttClient.connectionStatus!.state != MqttConnectionState.connected) {
      _mqttClient.disconnect();
      return;
    }

    // Subscribe to data topics
    for (var sensor in sensors) {
      final topic = 'sensor/${sensor.title}';
      _mqttClient.subscribe(topic, MqttQos.atMostOnce);
    }

    // Subscribe to server status topic
    _mqttClient.subscribe('sensor/status', MqttQos.atLeastOnce);

    _mqttClient.updates
        ?.listen((List<MqttReceivedMessage<MqttMessage>> events) {
      for (final event in events) {
        final rec = event.payload as MqttPublishMessage;
        final msg =
            MqttPublishPayload.bytesToStringAsString(rec.payload.message);
        final topic = event.topic;

        if (topic == 'sensor/status') {
          final decoded = jsonDecode(msg);
          if (decoded['status'] == 'connected') {
            setState(() {
              serverStatus = 'Online';
            });
          } else {
            setState(() {
              serverStatus = 'Offline';
            });
          }
          return;
        }

        final decoded = jsonDecode(msg);
        if (decoded is! List) return;

        final List<dynamic> msgJson = decoded;
        final newValues = msgJson.map((e) {
          return {
            'timestamp': e['timestamp'],
            'value': e['value'],
          };
        }).toList();

        setState(() {
          final idx = sensors.indexWhere((s) => 'sensor/${s.title}' == topic);
          if (idx == -1) return;

          sensors[idx] = SensorData(
            title: sensors[idx].title,
            values: List<Map<String, dynamic>>.from(newValues),
          );
        });

        _saveSensors();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'WiFi Status: ${isOffline ? 'Offline' : 'Online'}',
              style: const TextStyle(fontSize: 18, color: Colors.white),
            ),
            Text(
              'Server Status: $serverStatus',
              style: const TextStyle(fontSize: 18, color: Colors.white),
            ),
          ],
        ),
        centerTitle: false,
        actions: [
          TextButton.icon(
            onPressed: scanQrCode,
            icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
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
              itemCount: sensors.length,
              itemBuilder: (context, i) {
                final sensor = sensors[i];
                return SensorWidget(
                  sensorName: sensor.title,
                  values: sensor.values,
                  onUpdate: (_, values) {
                    setState(
                      () => sensors[i] =
                          SensorData(title: sensor.title, values: values),
                    );
                    _saveSensors();
                  },
                  onDelete: () {
                    setState(() => sensors.removeAt(i));
                    _saveSensors();
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: sendDisconnectRequest,
              icon: const Icon(Icons.power_settings_new),
              label: const Text('Disconnect'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
