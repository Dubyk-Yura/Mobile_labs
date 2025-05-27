import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class SensorState {
  final String sensorName;
  final List<Map<String, dynamic>> values;
  final List<TextEditingController> xControllers;
  final List<TextEditingController> yControllers;
  final TextEditingController nameController;

  SensorState({
    required this.sensorName,
    required this.values,
    required this.xControllers,
    required this.yControllers,
    required this.nameController,
  });

  SensorState copyWith({
    String? sensorName,
    List<Map<String, dynamic>>? values,
    List<TextEditingController>? xControllers,
    List<TextEditingController>? yControllers,
    TextEditingController? nameController,
  }) {
    return SensorState(
      sensorName: sensorName ?? this.sensorName,
      values: values ?? this.values,
      xControllers: xControllers ?? this.xControllers,
      yControllers: yControllers ?? this.yControllers,
      nameController: nameController ?? this.nameController,
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
            nameController: TextEditingController(text: sensorName),
            xControllers: values
                .map(
                  (e) => TextEditingController(text: e['timestamp'].toString()),
                )
                .toList(),
            yControllers: values
                .map((e) => TextEditingController(text: e['value'].toString()))
                .toList(),
          ),
        );

  void updateValues(List<Map<String, dynamic>> newValues) {
    for (var controller in state.xControllers) {
      controller.dispose();
    }
    for (var controller in state.yControllers) {
      controller.dispose();
    }

    final newXControllers = newValues
        .map((e) => TextEditingController(text: e['timestamp'].toString()))
        .toList();
    final newYControllers = newValues
        .map((e) => TextEditingController(text: e['value'].toString()))
        .toList();

    emit(
      state.copyWith(
        values: newValues,
        xControllers: newXControllers,
        yControllers: newYControllers,
      ),
    );
  }

  void saveChanges() {
    final updatedValues = <Map<String, dynamic>>[];

    for (int i = 0; i < state.xControllers.length; i++) {
      final timeString = state.xControllers[i].text;
      final value = int.tryParse(state.yControllers[i].text);

      updatedValues.add({
        'timestamp': timeString,
        'value': value,
      });
    }

    onUpdate(state.sensorName, updatedValues);
    emit(state.copyWith(values: updatedValues));
  }

  @override
  Future<void> close() {
    state.nameController.dispose();
    for (var controller in state.xControllers) {
      controller.dispose();
    }
    for (var controller in state.yControllers) {
      controller.dispose();
    }
    return super.close();
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

class _SensorWidgetView extends StatelessWidget {
  final List<Map<String, dynamic>> values;

  const _SensorWidgetView({
    required this.values,
  });

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

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cubit = context.read<SensorCubit>();
      if (!_listsEqual(values, cubit.state.values)) {
        cubit.updateValues(values);
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
      },
    );
  }
}
