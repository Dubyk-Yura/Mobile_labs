import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:mobile_labs/page/sensor_cubit.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class SensorWidget extends StatelessWidget {
  final String sensorName;
  final List<Map<String, dynamic>> values;
  final void Function(String, List<Map<String, dynamic>>) onUpdate;
  final VoidCallback onDelete;

  const SensorWidget(
      {required this.sensorName,
      required this.values,
      required this.onUpdate,
      required this.onDelete,
      super.key,});

  @override
  Widget build(BuildContext context) => BlocProvider(
        key: ValueKey(sensorName),
        create: (context) => SensorCubit(
            sensorName: sensorName, values: values, onUpdate: onUpdate,),
        child: _SensorWidgetView(values: values),
      );
}

class _SensorWidgetView extends StatefulWidget {
  final List<Map<String, dynamic>> values;

  const _SensorWidgetView({required this.values});

  @override
  State<_SensorWidgetView> createState() => _SensorWidgetViewState();
}

class _SensorWidgetViewState extends State<_SensorWidgetView> {
  List<TextEditingController> _xControllers = [];
  List<TextEditingController> _yControllers = [];

  @override
  void initState() {
    super.initState();
    _updateControllers(widget.values);
  }

  void _updateControllers(List<Map<String, dynamic>> values) {
    _disposeControllers();
    _xControllers = values
        .map((e) =>
            TextEditingController(text: e['timestamp']?.toString() ?? ''),)
        .toList();
    _yControllers = values
        .map((e) => TextEditingController(
            text: (e['value'] as int?)?.toString() ?? '0',),)
        .toList();
  }

  void _disposeControllers() {
    for (var c in [..._xControllers, ..._yControllers]) {
      c.dispose();
    }
    _xControllers.clear();
    _yControllers.clear();
  }

  @override
  void didUpdateWidget(_SensorWidgetView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_listsEqual(widget.values, oldWidget.values)) {
      _updateControllers(widget.values);
    }
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  bool _listsEqual(List<Map<String, dynamic>> a, List<Map<String, dynamic>> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i]['timestamp'] != b[i]['timestamp'] ||
          a[i]['value'] != b[i]['value']) {
        return false;
      }
    }
    return true;
  }

  DateTime _parseTimestamp(String? timestamp) {
    if (timestamp?.isEmpty != false) return DateTime.now();
    try {
      return DateTime.parse(timestamp!);
    } catch (e) {
      return DateTime.now();
    }
  }

  Widget _buildTextField(TextEditingController controller, String label,
          [TextInputType? type,]) =>
      Expanded(
          child: TextField(
        controller: controller,
        decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(color: Colors.white70),),
        style: const TextStyle(color: Colors.white),
        keyboardType: type,
      ),);

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cubit = context.read<SensorCubit>();
      if (!_listsEqual(widget.values, cubit.state.values)) {
        cubit.updateValues(widget.values);
        _updateControllers(widget.values);
      }
    });

    return BlocBuilder<SensorCubit, SensorState>(
      builder: (context, state) => Container(
        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        decoration: BoxDecoration(
            color: const Color(0x88939bae),
            borderRadius: BorderRadius.circular(15),),
        child: ExpansionTile(
          title: Text(state.sensorName,
              style: const TextStyle(color: Colors.white),),
          trailing: const Icon(Icons.expand_more, color: Colors.white),
          children: [
            SizedBox(
                height: 200,
                child: SfCartesianChart(
                  primaryXAxis:
                      DateTimeAxis(dateFormat: DateFormat('HH:mm:ss')),
                  series: [
                    LineSeries<Map<String, dynamic>, DateTime>(
                      dataSource: state.values,
                      xValueMapper: (data, _) =>
                          _parseTimestamp(data['timestamp']?.toString()),
                      yValueMapper: (data, _) => data['value'] as int? ?? 0,
                    )
                  ,],
                ),),
            if (state.isEditing) ...[
              const Padding(
                  padding: EdgeInsets.all(8),
                  child: Text('Edit Values:',
                      style: TextStyle(color: Colors.white, fontSize: 16),),),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _xControllers.length,
                itemBuilder: (context, index) => Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(children: [
                    _buildTextField(_xControllers[index], 'Timestamp'),
                    const SizedBox(width: 10),
                    _buildTextField(
                        _yControllers[index], 'Value', TextInputType.number,),
                  ],),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }
}
