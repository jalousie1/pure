import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/workout.dart';
import 'dart:convert';

class WorkoutsPage extends StatefulWidget {
  const WorkoutsPage({super.key});

  @override
  State<WorkoutsPage> createState() => _WorkoutsPageState();
}

class _WorkoutsPageState extends State<WorkoutsPage> {
  List<Workout> _workouts = [];
  bool _isLoading = true;

  final List<Map<String, dynamic>> _workoutTypes = [
    {'name': 'Corrida', 'icon': Icons.directions_run},
    {'name': 'Musculação', 'icon': Icons.fitness_center},
    {'name': 'Yoga', 'icon': Icons.self_improvement},
    {'name': 'Natação', 'icon': Icons.pool},
    {'name': 'Ciclismo', 'icon': Icons.directions_bike},
    {'name': 'Caminhada', 'icon': Icons.directions_walk},
  ];

  @override
  void initState() {
    super.initState();
    _loadWorkouts();
  }

  Future<void> _loadWorkouts() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists && doc.data()!.containsKey('workouts')) {
        final workoutsJson = doc.data()!['workouts'] as String;
        final workoutsList = jsonDecode(workoutsJson) as List;
        setState(() {
          _workouts = workoutsList
              .map((workout) => Workout.fromJson(Map<String, dynamic>.from(workout)))
              .toList();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load workouts')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveWorkouts() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final workoutsJson = jsonEncode(_workouts.map((w) => w.toJson()).toList());
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'workouts': workoutsJson});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save workouts')),
      );
    }
  }

  Future<void> _addWorkout() async {
    await showDialog(
      context: context,
      builder: (context) => _buildWorkoutDialog(),
    );
  }

  Widget _buildWorkoutDialog({Workout? workout}) {
    String selectedType = workout?.name ?? _workoutTypes[0]['name'];
    final durationController = TextEditingController(text: workout?.duration);
    final caloriesController = TextEditingController(
        text: workout?.calories.toString());

    return AlertDialog(
      title: Text(workout == null ? 'Add Workout' : 'Edit Workout'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            value: selectedType,
            decoration: const InputDecoration(labelText: 'Workout Type'),
            items: _workoutTypes.map<DropdownMenuItem<String>>((type) => DropdownMenuItem(
              value: type['name'] as String,
              child: Row(
                children: [
                  Icon(type['icon'] as IconData),
                  const SizedBox(width: 8),
                  Text(type['name'] as String),
                ],
              ),
            )).toList(),
            onChanged: (value) {
              if (value != null) {
                selectedType = value;
              }
            },
          ),
          TextField(
            controller: durationController,
            decoration: const InputDecoration(labelText: 'Duration (e.g., 30 min)'),
          ),
          TextField(
            controller: caloriesController,
            decoration: const InputDecoration(labelText: 'Calories Burned'),
            keyboardType: TextInputType.number,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () async {
            final newWorkout = Workout(
              name: selectedType,
              duration: durationController.text,
              calories: int.tryParse(caloriesController.text) ?? 0,
              icon: _getIconForWorkoutType(selectedType),
            );

            setState(() {
              if (workout == null) {
                _workouts.add(newWorkout);
              } else {
                final index = _workouts.indexOf(workout);
                _workouts[index] = newWorkout;
              }
            });
            await _saveWorkouts();
            if (mounted) Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }

  IconData _getIconForWorkoutType(String type) {
    final workoutType = _workoutTypes.firstWhere(
      (element) => element['name'] == type,
      orElse: () => {'name': '', 'icon': Icons.fitness_center},
    );
    return workoutType['icon'];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Workouts'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _workouts.length,
              itemBuilder: (context, index) {
                final workout = _workouts[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: ListTile(
                    leading: Icon(workout.icon),
                    title: Text(workout.name),
                    subtitle: Text(workout.duration),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${workout.calories} kcal'),
                        PopupMenuButton(
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Text('Edit'),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text('Delete'),
                            ),
                          ],
                          onSelected: (value) async {
                            if (value == 'edit') {
                              await showDialog(
                                context: context,
                                builder: (context) =>
                                    _buildWorkoutDialog(workout: workout),
                              );
                            } else if (value == 'delete') {
                              setState(() {
                                _workouts.removeAt(index);
                              });
                              await _saveWorkouts();
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addWorkout,
        child: const Icon(Icons.add),
      ),
    );
  }
}
