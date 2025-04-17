import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:mobile_labs/page/sensor.dart';
import 'package:mobile_labs/storage/storage.dart';
import 'package:mobile_labs/storage/storage_impl.dart';
import 'package:mobile_labs/widgets/custom_button.dart';

final Storage localStorage = StorageImpl();

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<SensorData> sensors = [];
  String? userEmail;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    userEmail = await localStorage.getCurrentUserEmail();
    await _loadSensors();
  }

  Future<void> _loadSensors() async {
    final raw = await localStorage.read(userEmail!);
    if (raw != null) {
      final decoded = jsonDecode(raw) as List<dynamic>;
      sensors = decoded
          .map((item) => SensorData.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    setState(() {});
  }

  Future<void> _saveSensors() async {
    final encoded = jsonEncode(sensors.map((e) => e.toJson()).toList());
    await localStorage.write(userEmail!, encoded);
  }

  void _addSensor() {
    setState(() {
      final newSensor = SensorData(
        title: 'Sensor ${sensors.length + 1}',
        values: List.generate(10, (index) {
          final random = Random();

          final value = random.nextDouble() * 50 - 10;

          final timestamp = DateTime.now().add(Duration(seconds: index * 5));
          final timeString =
              '${timestamp.hour}:${timestamp.minute}:${timestamp.second}';

          return {'timestamp': timeString, 'value': value};
        }),
      );

      sensors.add(newSensor);
    });

    _saveSensors();
  }

  void _updateSensor(
    int index,
    String newTitle,
    List<Map<String, dynamic>> newValues,
  ) {
    setState(() {
      sensors[index] = SensorData(title: newTitle, values: newValues);
    });
    _saveSensors();
  }

  void _deleteSensor(int index) {
    setState(() {
      sensors.removeAt(index);
    });
    _saveSensors();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: sensors.length,
              itemBuilder: (context, index) {
                final sensor = sensors[index];
                return SensorWidget(
                  sensorName: sensor.title,
                  values: sensor.values,
                  onUpdate: (name, values) {
                    _updateSensor(index, name, values);
                  },
                  onDelete: () => _deleteSensor(index),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: CustomButton(
              onPressed: _addSensor,
              text: 'Add Sensor',
              horizontalPadding: 60,
              verticalPadding: 4,
            ),
          ),
        ],
      ),
    );
  }
}

class SensorData {
  final String title;
  final List<Map<String, dynamic>> values;

  SensorData({required this.title, required this.values});

  Map<String, dynamic> toJson() => {
        'title': title,
        'values': values,
      };

  factory SensorData.fromJson(Map<String, dynamic> json) {
    return SensorData(
      title: json['title'].toString(),
      values: List<Map<String, dynamic>>.from(
        (json['values'] as List<dynamic>).map(
          (value) => Map<String, dynamic>.from(value as Map<String, dynamic>),
        ),
      ),
    );
  }
}
