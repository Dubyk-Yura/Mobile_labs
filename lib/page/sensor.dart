import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class SensorState {
  final String sensorName;
  final List<Map<String, dynamic>> values;
  final bool isEditing;

  const SensorState({
    required this.sensorName,
    required this.values,
    required this.isEditing,
  });

  SensorState copyWith({
    String? sensorName,
    List<Map<String, dynamic>>? values,
    bool? isEditing,
  }) {
    return SensorState(
      sensorName: sensorName ?? this.sensorName,
      values: values ?? this.values,
      isEditing: isEditing ?? this.isEditing,
    );
  }
}

class SensorCubit extends Cubit<SensorState> {
  final void Function(String, List<Map<String, dynamic>>) onUpdate;

  SensorCubit({
    required String sensorName,
    required List<Map<String, dynamic>> values,
    required this.onUpdate,
  }) : super(
          SensorState(
            sensorName: sensorName,
            values: values,
            isEditing: false,
          ),
        );

  void updateValues(List<Map<String, dynamic>> newValues) {
    emit(state.copyWith(values: newValues));
  }

  void toggleEditing() {
    emit(state.copyWith(isEditing: !state.isEditing));
  }

  void saveChanges(List<Map<String, dynamic>> updatedValues) {
    final cleanedValues = updatedValues.map((item) {
      final timestamp = item['timestamp']?.toString() ?? '';
      final value = item['value'] as int?;

      return {
        'timestamp': timestamp,
        'value': value ?? 0,
      };
    }).toList();

    onUpdate(state.sensorName, cleanedValues);
    emit(
      state.copyWith(
        values: cleanedValues,
        isEditing: false,
      ),
    );
  }
}

class SensorWidget extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return BlocProvider(
      key: ValueKey(sensorName),
      create: (context) => SensorCubit(
        sensorName: sensorName,
        values: values,
        onUpdate: onUpdate,
      ),
      child: _SensorWidgetView(
        values: values,
      ),
    );
  }
}

class _SensorWidgetView extends StatefulWidget {
  final List<Map<String, dynamic>> values;

  const _SensorWidgetView({
    required this.values,
  });

  @override
  State<_SensorWidgetView> createState() => _SensorWidgetViewState();
}

class _SensorWidgetViewState extends State<_SensorWidgetView> {
  late List<TextEditingController> _xControllers;
  late List<TextEditingController> _yControllers;
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _nameController = TextEditingController();
    _xControllers = [];
    _yControllers = [];
    _updateControllers(widget.values);
  }

  void _updateControllers(List<Map<String, dynamic>> values) {
    _disposeControllers();

    _xControllers = values
        .map(
          (e) => TextEditingController(text: e['timestamp']?.toString() ?? ''),
        )
        .toList();
    _yControllers = values
        .map(
          (e) => TextEditingController(
            text: (e['value'] as int?)?.toString() ?? '0',
          ),
        )
        .toList();
  }

  void _disposeControllers() {
    for (var controller in _xControllers) {
      controller.dispose();
    }
    for (var controller in _yControllers) {
      controller.dispose();
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
    _nameController.dispose();
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

  void _saveChanges(SensorCubit cubit) {
    final updatedValues = <Map<String, dynamic>>[];

    for (int i = 0; i < _xControllers.length; i++) {
      final timeString = _xControllers[i].text;
      final valueText = _yControllers[i].text;
      final value = int.tryParse(valueText);

      updatedValues.add({
        'timestamp': timeString,
        'value': value,
      });
    }

    cubit.saveChanges(updatedValues);
  }

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
      builder: (context, state) {
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
          decoration: BoxDecoration(
            color: const Color(0x88939bae),
            borderRadius: BorderRadius.circular(15),
          ),
          child: ExpansionTile(
            title: Text(
              state.sensorName,
              style: const TextStyle(color: Colors.white),
            ),
            trailing: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.expand_more, color: Colors.white),
              ],
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
                      dataSource: state.values,
                      xValueMapper: (data, _) {
                        final timestamp = data['timestamp']?.toString();
                        if (timestamp == null || timestamp.isEmpty) {
                          return DateTime.now();
                        }
                        try {
                          return DateTime.parse(timestamp);
                        } catch (e) {
                          return DateTime.now();
                        }
                      },
                      yValueMapper: (data, _) {
                        final value = data['value'] as int?;
                        return value ?? 0;
                      },
                    ),
                  ],
                ),
              ),
              if (state.isEditing) ...[
                const Padding(
                  padding: EdgeInsets.all(8),
                  child: Text(
                    'Edit Values:',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _xControllers.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _xControllers[index],
                              decoration: const InputDecoration(
                                labelText: 'Timestamp',
                                labelStyle: TextStyle(color: Colors.white70),
                              ),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _yControllers[index],
                              decoration: const InputDecoration(
                                labelText: 'Value',
                                labelStyle: TextStyle(color: Colors.white70),
                              ),
                              style: const TextStyle(color: Colors.white),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
              ],
            ],
          ),
        );
      },
    );
  }
}
