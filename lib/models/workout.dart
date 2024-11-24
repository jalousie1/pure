import 'package:flutter/material.dart';

class Workout {
  final String name;
  final String duration;
  final int calories;
  final IconData icon;

  Workout({
    required this.name,
    required this.duration,
    required this.calories,
    required this.icon,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'duration': duration,
        'calories': calories,
        'iconIndex': icon.codePoint,
      };

  factory Workout.fromJson(Map<String, dynamic> json) {
    return Workout(
      name: json['name'] as String,
      duration: json['duration'] as String,
      calories: json['calories'] as int,
      icon: IconData(json['iconIndex'] as int, fontFamily: 'MaterialIcons'),
    );
  }
}
