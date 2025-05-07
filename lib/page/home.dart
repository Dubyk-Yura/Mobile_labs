import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mobile_labs/page/sensor.dart';
import 'package:mobile_labs/page/sensor_data.dart';
import 'package:mobile_labs/services/network_monitor.dart';
import 'package:mobile_labs/storage/storage.dart';
import 'package:mobile_labs/storage/storage_impl.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

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

  final List<String> topics = [
    'sensor/lux',
    'sensor/temperature',
    'sensor/pressure',
    'sensor/humidity',
  ];

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

    for (var sensor in sensors) {
      final topic = 'sensor/${sensor.title}';
      _mqttClient.subscribe(topic, MqttQos.atMostOnce);
    }

    _mqttClient.updates
        ?.listen((List<MqttReceivedMessage<MqttMessage>> events) {
      for (final event in events) {
        final rec = event.payload as MqttPublishMessage;
        final msg =
            MqttPublishPayload.bytesToStringAsString(rec.payload.message);
        final topic = event.topic;

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

          final updated = List<Map<String, dynamic>>.from(newValues);

          sensors[idx] = SensorData(title: sensors[idx].title, values: updated);
        });

        _saveSensors();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isOffline ? 'Offline' : 'Online'),
        centerTitle: true,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 36,
          fontWeight: FontWeight.bold,
        ),
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
        ],
      ),
    );
  }
}
