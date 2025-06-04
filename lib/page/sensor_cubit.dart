import 'package:flutter_bloc/flutter_bloc.dart';

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
    final cleanedValues = updatedValues
        .map(
          (item) => {
            'timestamp': item['timestamp']?.toString() ?? '',
            'value': item['value'] as int? ?? 0,
          },
        )
        .toList();

    onUpdate(state.sensorName, cleanedValues);
    emit(state.copyWith(values: cleanedValues, isEditing: false));
  }
}
