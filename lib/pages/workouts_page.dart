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

class _WorkoutsPageState extends State<WorkoutsPage> with SingleTickerProviderStateMixin {
  List<Workout> _workouts = [];
  bool _isLoading = true;

  final List<Map<String, dynamic>> _workoutTypes = [
    {'name': 'Running', 'icon': Icons.directions_run},
    {'name': 'Weight Training', 'icon': Icons.fitness_center},
    {'name': 'Yoga', 'icon': Icons.self_improvement},
    {'name': 'Swimming', 'icon': Icons.pool},
    {'name': 'Cycling', 'icon': Icons.directions_bike},
    {'name': 'Walking', 'icon': Icons.directions_walk},
  ];

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final _scrollController = ScrollController();

  // Carrega os treinos do usuário quando a tela é iniciada
  @override
  void initState() {
    super.initState();
    _loadWorkouts();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Busca os treinos salvos no Firebase e atualiza a tela
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

  // Salva os treinos do usuário no Firebase
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

  // Abre o diálogo para adicionar um novo treino
  Future<void> _addWorkout() async {
    await showDialog(
      context: context,
      builder: (context) => _buildWorkoutDialog(),
    );
  }

  // Cria o diálogo para adicionar ou editar um treino
  Widget _buildWorkoutDialog({Workout? workout}) {
    String selectedType = workout?.name ?? _workoutTypes[0]['name'];
    final durationController = TextEditingController(text: workout?.duration);
    final caloriesController = TextEditingController(text: workout?.calories.toString());
    final formKey = GlobalKey<FormState>();

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            workout == null ? Icons.add_circle : Icons.edit,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(workout == null ? 'Add Workout' : 'Edit Workout'),
        ],
      ),
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                value: selectedType,
                decoration: InputDecoration(
                  labelText: 'Workout Type',
                  border: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  prefixIcon: Icon(
                    _getIconForWorkoutType(selectedType),
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                items: _workoutTypes.map<DropdownMenuItem<String>>((type) => DropdownMenuItem(
                  value: type['name'] as String,
                  child: Row(
                    children: [
                      Icon(type['icon'] as IconData),
                      const SizedBox(width: 12),
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
              const SizedBox(height: 20),
              TextFormField(
                controller: durationController,
                decoration: InputDecoration(
                  labelText: 'Duration',
                  hintText: 'e.g., 30 minutes',
                  border: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  prefixIcon: Icon(
                    Icons.timer_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter duration';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: caloriesController,
                decoration: InputDecoration(
                  labelText: 'Calories Burned',
                  hintText: 'e.g., 250',
                  border: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  prefixIcon: Icon(
                    Icons.local_fire_department,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter calories';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: TextStyle(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        ),
        FilledButton.icon(
          onPressed: () async {
            if (formKey.currentState?.validate() ?? false) {
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
            }
          },
          icon: Icon(workout == null ? Icons.add : Icons.save),
          label: Text(workout == null ? 'Add Workout' : 'Save Changes'),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  // Retorna o ícone correspondente ao tipo de treino selecionado
  IconData _getIconForWorkoutType(String type) {
    final workoutType = _workoutTypes.firstWhere(
      (element) => element['name'] == type,
      orElse: () => {'name': '', 'icon': Icons.fitness_center},
    );
    return workoutType['icon'];
  }

  // Adicione este novo método para criar o card de resumo
  Widget _buildWorkoutSummaryCard() {
    final totalWorkouts = _workouts.length;
    final totalCalories = _workouts.fold(0, (sum, workout) => sum + workout.calories);
    final avgCalories = totalWorkouts > 0 ? totalCalories ~/ totalWorkouts : 0;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              'Workout Summary',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem(
                  icon: Icons.fitness_center,
                  label: 'Total Workouts',
                  value: totalWorkouts.toString(),
                ),
                _buildSummaryItem(
                  icon: Icons.local_fire_department,
                  label: 'Total Calories',
                  value: '$totalCalories kcal',
                ),
                _buildSummaryItem(
                  icon: Icons.analytics,
                  label: 'Average/Workout',
                  value: '$avgCalories kcal',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
          size: 24,
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // Constrói a interface principal da tela de treinos
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Workouts'),
        centerTitle: true,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : FadeTransition(
              opacity: _fadeAnimation,
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                children: [
                  _buildWorkoutSummaryCard(),
                  const SizedBox(height: 24),
                  if (_workouts.isEmpty)
                    Center(
                      child: Text(
                        'No workouts registered',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  else
                    ..._workouts.reversed.map((workout) {
                      int index = _workouts.indexOf(workout);
                      return SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(1, 0),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                          parent: _animationController,
                          curve: Interval(
                            index / _workouts.length,
                            (index + 1) / _workouts.length,
                            curve: Curves.easeOut,
                          ),
                        )),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: _buildWorkoutCard(workout, index),
                        ),
                      );
                    }).toList(),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addWorkout,
        icon: const Icon(Icons.add),
        label: const Text('New workout'),
      ),
    );
  }

  Widget _buildWorkoutCard(Workout workout, int index) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => showDialog(
          context: context,
          builder: (context) => _buildWorkoutDialog(workout: workout),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        workout.icon,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        workout.name,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
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
                          builder: (context) => _buildWorkoutDialog(workout: workout),
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
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.timer_outlined,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(workout.duration),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.local_fire_department,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Text('${workout.calories} kcal'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
