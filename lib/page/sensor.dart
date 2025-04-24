import 'package:flutter/material.dart';
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
  bool isEditing = false;
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
    final updatedName = nameController.text;
    final updatedValues = <Map<String, dynamic>>[];

    for (int i = 0; i < xControllers.length; i++) {
      final timeString = xControllers[i].text;
      final value = double.tryParse(yControllers[i].text) ?? 0.0;

      updatedValues.add({
        'timestamp': timeString,
        'value': value,
      });
    }

    widget.onUpdate(updatedName, updatedValues);
    setState(() {
      isEditing = false;
    });
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
        title: isEditing
            ? TextField(
                controller: nameController,
                style: const TextStyle(color: Colors.white),
              )
            : Text(
                widget.sensorName,
                style: const TextStyle(color: Colors.white),
              ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isEditing)
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.white),
                onPressed: () {
                  setState(() {
                    isEditing = true;
                  });
                },
              ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: widget.onDelete,
            ),
          ],
        ),
        children: [
          if (!isEditing)
            SizedBox(
              height: 200,
              child: SfCartesianChart(
                primaryXAxis: const DateTimeAxis(),
                series: <CartesianSeries<Map<String, dynamic>, DateTime>>[
                  LineSeries<Map<String, dynamic>, DateTime>(
                    dataSource: widget.values,
                    xValueMapper: (data, _) => DateTime.parse(data['timestamp'].toString()),
                    yValueMapper: (data, _) => data['value'] as double,
                  ),
                ],
              )
            )
          else
            Column(
              children: List.generate(xControllers.length, (index) {
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: xControllers[index],
                          decoration:
                              const InputDecoration(labelText: 'Timestamp'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: yControllers[index],
                          decoration: const InputDecoration(labelText: 'Value'),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          if (isEditing)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: ElevatedButton(
                onPressed: _saveChanges,
                child: const Text('Save'),
              ),
            ),
        ],
      ),
    );
  }
}
