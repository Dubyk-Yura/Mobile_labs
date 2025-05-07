import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class SensorWidget extends StatefulWidget {
  final String sensorName;
  final List<Map<String, dynamic>> values;
  final void Function(String, List<Map<String, dynamic>>) onUpdate;
  final VoidCallback onDelete;

  const SensorWidget({
    required this.sensorName,
    required this.values,
    required this.onUpdate,
    required this.onDelete,
    super.key,
  });

  @override
  State<SensorWidget> createState() => _SensorWidgetState();
}

class _SensorWidgetState extends State<SensorWidget> {
  late TextEditingController nameController;
  late List<TextEditingController> xControllers;
  late List<TextEditingController> yControllers;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.sensorName);
    xControllers = widget.values
        .map((e) => TextEditingController(text: e['timestamp'].toString()))
        .toList();
    yControllers = widget.values
        .map((e) => TextEditingController(text: e['value'].toString()))
        .toList();
  }

  void _saveChanges() {
    final updatedValues = <Map<String, dynamic>>[];

    for (int i = 0; i < xControllers.length; i++) {
      final timeString = xControllers[i].text;
      final value = int.tryParse(yControllers[i].text);

      updatedValues.add({
        'timestamp': timeString,
        'value': value,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0x88939bae),
        borderRadius: BorderRadius.circular(15),
      ),
      child: ExpansionTile(
        title: Text(
          widget.sensorName,
          style: const TextStyle(color: Colors.white),
        ),
        trailing: const Row(
          mainAxisSize: MainAxisSize.min,
        ),
        children: [
          SizedBox(
            height: 200,
            child: SfCartesianChart(
              primaryXAxis: DateTimeAxis(
                dateFormat: DateFormat('HH:mm:ss'),
              ),
              series: <CartesianSeries<Map<String, dynamic>, DateTime>>[
                LineSeries<Map<String, dynamic>, DateTime>(
                  dataSource: widget.values,
                  xValueMapper: (data, _) =>
                      DateTime.parse(data['timestamp'].toString()),
                  yValueMapper: (data, _) => data['value'] as int,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
