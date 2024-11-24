import 'package:flutter/material.dart';

class Medicine {
  final String name;
  final String dose;
  final int hour;
  final int minute;

  Medicine({
    required this.name,
    required this.dose,
    required this.hour,
    required this.minute,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'dose': dose,
        'hour': hour,
        'minute': minute,
      };

  factory Medicine.fromJson(Map<String, dynamic> json) {
    return Medicine(
      name: json['name'] as String,
      dose: json['dose'] as String,
      hour: json['hour'] as int,
      minute: json['minute'] as int,
    );
  }

  TimeOfDay get time => TimeOfDay(hour: hour, minute: minute);
}
