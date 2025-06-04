class SensorData {
  final String title;
  final List<Map<String, dynamic>> values;

  SensorData({required this.title, required this.values});

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'values': values,
    };
  }

  factory SensorData.fromJson(Map<String, dynamic> json) {
    return SensorData(
      title: json['title'].toString(),
      values: List<Map<String, dynamic>>.from(
        (json['values'] as List<dynamic>).map(
          (v) => Map<String, dynamic>.from(v as Map<String, dynamic>),
        ),
      ),
    );
  }

  void addValue(Map<String, dynamic> newValue) {
    values.add(newValue);
  }
}
