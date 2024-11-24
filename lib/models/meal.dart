import 'package:flutter/material.dart';

class Meal {
  final String type;
  final String description;
  final int calories;
  final IconData icon;

  Meal({
    required this.type,
    required this.description,
    required this.calories,
    required this.icon,
  });

  Map<String, dynamic> toJson() => {
        'type': type,
        'description': description,
        'calories': calories,
        'iconIndex': icon.codePoint,
      };

  factory Meal.fromJson(Map<String, dynamic> json) {
    return Meal(
      type: json['type'] as String,
      description: json['description'] as String,
      calories: json['calories'] as int,
      icon: IconData(json['iconIndex'] as int, fontFamily: 'MaterialIcons'),
    );
  }
}
