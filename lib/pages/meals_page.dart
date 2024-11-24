import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/meal.dart';
import 'dart:convert';

class MealsPage extends StatefulWidget {
  const MealsPage({super.key});

  @override
  State<MealsPage> createState() => _MealsPageState();
}

class _MealsPageState extends State<MealsPage> with SingleTickerProviderStateMixin {
  List<Meal> _meals = [];
  bool _isLoading = true;

  final List<Map<String, dynamic>> _mealTypes = [
    {'type': 'Breakfast', 'icon': Icons.breakfast_dining},
    {'type': 'Lunch', 'icon': Icons.lunch_dining},
    {'type': 'Snack', 'icon': Icons.coffee},
    {'type': 'Dinner', 'icon': Icons.dinner_dining},
  ];

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadMeals();
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

  // Carrega as refeições do usuário do Firestore
  Future<void> _loadMeals() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists && doc.data()!.containsKey('meals')) {
        final mealsJson = doc.data()!['meals'] as String;
        final mealsList = jsonDecode(mealsJson) as List;
        setState(() {
          _meals = mealsList
              .map((meal) => Meal.fromJson(Map<String, dynamic>.from(meal)))
              .toList();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load meals')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Salva as refeições do usuário no Firestore
  Future<void> _saveMeals() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final mealsJson = jsonEncode(_meals.map((m) => m.toJson()).toList());
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'meals': mealsJson});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save meals')),
      );
    }
  }

  // Abre o diálogo para adicionar uma nova refeição
  Future<void> _addMeal() async {
    await showDialog(
      context: context,
      builder: (context) => _buildMealDialog(),
    );
  }

  // Cria o diálogo para adicionar ou editar uma refeição
  Widget _buildMealDialog({Meal? meal}) {
    final descriptionController = TextEditingController(text: meal?.description);
    final caloriesController = TextEditingController(
      text: meal?.calories.toString(),
    );
    String selectedType = meal?.type ?? _mealTypes[0]['type'];

    return StatefulBuilder(
      builder: (context, setState) {
        return AlertDialog(
          title: Text(meal == null ? 'Add Meal' : 'Edit Meal'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Seletor de tipo de refeição com melhor UI
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Meal Type',
                    border: OutlineInputBorder(),
                  ),
                  items: _mealTypes.map<DropdownMenuItem<String>>((type) {
                    return DropdownMenuItem(
                      value: type['type'] as String,
                      child: Row(
                        children: [
                          Icon(type['icon'] as IconData),
                          const SizedBox(width: 8),
                          Text(type['type'] as String),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        selectedType = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                // Campo de texto para descrição com estilização
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: null,
                ),
                const SizedBox(height: 16),
                // Campo de texto para calorias com estilização
                TextField(
                  controller: caloriesController,
                  decoration: const InputDecoration(
                    labelText: 'Calories',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final newMeal = Meal(
                  type: selectedType,
                  description: descriptionController.text,
                  calories: int.tryParse(caloriesController.text) ?? 0,
                  icon: _getIconForMealType(selectedType),
                );

                setState(() {
                  if (meal == null) {
                    _meals.add(newMeal);
                  } else {
                    final index = _meals.indexOf(meal);
                    _meals[index] = newMeal;
                  }
                });
                await _saveMeals();
                if (mounted) Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  // Retorna o ícone correspondente ao tipo de refeição
  IconData _getIconForMealType(String type) {
    final mealType = _mealTypes.firstWhere(
      (element) => element['type'] == type,
      orElse: () => {'type': '', 'icon': Icons.restaurant},
    );
    return mealType['icon'];
  }

  // Cria o card com o resumo de todas as refeições
  Widget _buildMealsSummaryCard() {
    int totalCalories = _meals.fold(0, (sum, meal) => sum + meal.calories);
    int mealCount = _meals.length;
    double avgCalories = mealCount > 0 ? totalCalories / mealCount : 0;

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
              'Meals Summary',
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
                  icon: Icons.restaurant,
                  label: 'Total Meals',
                  value: mealCount.toString(),
                ),
                _buildSummaryItem(
                  icon: Icons.local_fire_department,
                  label: 'Total Calories',
                  value: '$totalCalories kcal',
                ),
                _buildSummaryItem(
                  icon: Icons.analytics,
                  label: 'Average/Meal',
                  value: '${avgCalories.toStringAsFixed(0)} kcal',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Cria um item do resumo (total, calorias, média)
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meals'),
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
                  _buildMealsSummaryCard(),
                  const SizedBox(height: 24),
                  if (_meals.isEmpty)
                    Center(
                      child: Text(
                        'No meals registered',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  else
                    ..._meals.reversed.map((meal) {
                      int index = _meals.indexOf(meal);
                      return SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(1, 0),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                          parent: _animationController,
                          curve: Interval(
                            index / _meals.length,
                            (index + 1) / _meals.length,
                            curve: Curves.easeOut,
                          ),
                        )),
                        child: _buildMealCard(meal, index),
                      );
                    }).toList(),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addMeal,
        icon: const Icon(Icons.add),
        label: const Text('New meal'),
      ),
    );
  }

  // Cria o card para exibir uma refeição individual
  Widget _buildMealCard(Meal meal, int index) {
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
        onTap: () => _editMeal(meal),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tipo de refeição e opções
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    meal.type,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
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
                        await _editMeal(meal);
                      } else if (value == 'delete') {
                        setState(() {
                          _meals.removeAt(index);
                        });
                        await _saveMeals();
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Descrição da refeição
              Text(
                meal.description,
                style: const TextStyle(
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              // Calorias
              Row(
                children: [
                  Icon(
                    Icons.local_fire_department,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${meal.calories} kcal',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Abre o diálogo para editar uma refeição existente
  Future<void> _editMeal(Meal meal) async {
    await showDialog(
      context: context,
      builder: (context) => _buildMealDialog(meal: meal),
    );
  }
}
