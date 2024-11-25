import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'dart:convert';

class HomePageWidget extends StatefulWidget {
  const HomePageWidget({super.key});

  @override
  State<HomePageWidget> createState() => _HomePageWidgetState();
}

class _HomePageWidgetState extends State<HomePageWidget> with SingleTickerProviderStateMixin {
  late Stream<StepCount> _stepCountStream;
  int _steps = 0;
  int _dailyGoal = 10000;  // Remove final
  late String _dailyTip;
  String _username = '';
  bool _isLoading = true;
  late AnimationController _progressController;
  int _waterGlasses = 0;
  String _currentMood = '';
  DateTime _lastMoodUpdate = DateTime.now();
  bool _canUpdateMood = true;
  String _currentDate = DateTime.now().toIso8601String().split('T')[0];
  
  final List<String> _healthTips = [
    'Drink at least 8 glasses of water a day to stay hydrated.',
    'Practice 30 minutes of moderate physical activity daily.',
    'Maintain a regular sleep routine of 7-8 hours per night.',
    'Include fruits and vegetables in all main meals.',
    'Take regular breaks during work to stretch.',
    'Practice breathing techniques to reduce stress.',
    'Maintain proper posture when using electronic devices.',
    'Eat slowly and chew food well.',
    'Establish healthy boundaries between work and rest.',
    'Protect your skin by using sunscreen daily.',
    'Practice mindfulness for a few minutes every day.',
    'Keep a gratitude journal for mental well-being.',
    'Do stretching exercises when you wake up.',
    'Avoid using electronics one hour before bed.',
    'Maintain a colorful and varied diet.',
  ];

  final Map<String, Map<String, dynamic>> _moods = {
    'happy': {'emoji': '😊', 'text': 'Happy', 'color': Colors.yellow},
    'neutral': {'emoji': '😐', 'text': 'Neutral', 'color': Colors.blue},
    'sad': {'emoji': '😔', 'text': 'Sad', 'color': Colors.purple},
    'tired': {'emoji': '😫', 'text': 'Tired', 'color': Colors.grey},
    'stressed': {'emoji': '😤', 'text': 'Stressed', 'color': Colors.red},
  };

  // Inicializa o contador de passos e carrega os dados do usuário
  @override
  void initState() {
    super.initState();
    _selectRandomTip();
    _loadUserData();
    _initPlatformState();
    _loadCurrentMood();
    _loadWaterIntake();
    
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _progressController.forward();
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  // Solicita permissão e inicia contagem de passos
  void _initPlatformState() async {
    // Request permission
    if (await Permission.activityRecognition.request().isGranted) {
      _stepCountStream = Pedometer.stepCountStream;
      _stepCountStream.listen(
        onStepCount,
        onError: onStepCountError,
        cancelOnError: true,
      );
    } else {
      print('Permission denied');
    }
  }

  void onStepCount(StepCount event) {
    setState(() {
      _steps = event.steps;
    });
  }

  void onStepCountError(error) {
    print('Step count error: $error');
  }

  // Carrega os dados do usuário do Firebase (nome, meta de passos, etc)
  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userData = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        
        if (userData.exists) {
          setState(() {
            _username = userData.data()?['username'] ?? '';
            _dailyGoal = userData.data()?['stepGoal'] ?? 10000;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  // Atualiza a meta diária de passos no Firebase
  Future<void> _updateStepGoal(int newGoal) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'stepGoal': newGoal});
        
        setState(() {
          _dailyGoal = newGoal;
        });
      }
    } catch (e) {
      print('Error updating step goal: $e');
    }
  }

  // Mostra diálogo para alterar a meta de passos
  Future<void> _showGoalDialog() async {
    final controller = TextEditingController(text: _dailyGoal.toString());
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Daily Step Goal'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Steps',
            hintText: 'Enter your daily step goal',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final newGoal = int.tryParse(controller.text);
              if (newGoal != null && newGoal > 0) {
                _updateStepGoal(newGoal);
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // Seleciona uma dica de saúde aleatória da lista
  void _selectRandomTip() {
    final random = Random();
    setState(() {
      _dailyTip = _healthTips[random.nextInt(_healthTips.length)];
    });
  }

  // Carrega o humor atual do usuário do Firebase
  Future<void> _loadCurrentMood() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userData = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userData.exists && userData.data()?['moods'] != null) {
          final moodsData = userData.data()?['moods'];
          if (moodsData != null) {
            final Map<String, dynamic> moodMap = json.decode(moodsData);
            if (moodMap.isNotEmpty) {
              setState(() {
                _currentMood = moodMap['mood'] ?? '';
                _lastMoodUpdate = DateTime.fromMillisecondsSinceEpoch(moodMap['timestamp'] ?? 0);
                _canUpdateMood = DateTime.now().difference(_lastMoodUpdate).inHours >= 4;
              });
            }
          }
        }
      }
    } catch (e) {
      print('Error loading mood data: $e');
    }
  }

  // Atualiza o humor do usuário no Firebase (possível a cada 4 horas)
  Future<void> _updateMood(String mood) async {
    if (!_canUpdateMood) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You can update your mood again in ${4 - DateTime.now().difference(_lastMoodUpdate).inHours} hours'),
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final timestamp = DateTime.now();
        final moodData = {
          'mood': mood,
          'timestamp': timestamp.millisecondsSinceEpoch,
          'text': _moods[mood]!['text'],
        };

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
              'moods': json.encode(moodData),
            });

        setState(() {
          _currentMood = mood;
          _lastMoodUpdate = timestamp;
          _canUpdateMood = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Mood updated to ${_moods[mood]!['text']}'),
            backgroundColor: _moods[mood]!['color'] as Color,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error updating mood: $e');
    }
  }

  // Carrega o consumo de água do dia atual
  Future<void> _loadWaterIntake() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final today = DateTime.now().toIso8601String().split('T')[0];
        final userData = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userData.exists && userData.data()?['water'] != null) {
          final waterData = json.decode(userData.data()?['water']);
          if (waterData[today] != null) {
            setState(() {
              _waterGlasses = waterData[today]['glasses'] ?? 0;
            });
          } else {
            setState(() {
              _waterGlasses = 0;
            });
          }
        }
      }
    } catch (e) {
      print('Error loading water intake: $e');
    }
  }

  // Atualiza o número de copos de água consumidos no dia
  Future<void> _updateWaterIntake(int glasses) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final today = DateTime.now().toIso8601String().split('T')[0];
        
        // Check if date changed, if yes, reset glasses
        if (today != _currentDate) {
          setState(() {
            _waterGlasses = 0;
            _currentDate = today;
          });
        }

        // Get current water data
        final userData = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        Map<String, dynamic> waterData = {};
        if (userData.exists && userData.data()?['water'] != null) {
          waterData = json.decode(userData.data()?['water']);
        }

        // Update water data for today
        waterData[today] = {
          'glasses': glasses,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        };

        // Save to Firebase
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'water': json.encode(waterData),
        });

        setState(() {
          _waterGlasses = glasses;
        });
      }
    } catch (e) {
      print('Error updating water intake: $e');
    }
  }

  // Constrói o layout principal do aplicativo
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Enhanced Header
          Container(
            height: 140,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(24),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(16, 40, 16, 16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'PureLife',
                      style: TextStyle(
                        fontSize: 24,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pushNamed(context, '/profile'),
                          icon: const Icon(Icons.account_circle, color: Colors.white),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildQuickStat(Icons.directions_walk, '$_steps', 'Steps'),
                    _buildQuickStat(Icons.local_fire_department, '${(_steps * 0.04).round()}', 'Kcal'),
                    _buildQuickStat(Icons.water_drop, '$_waterGlasses/8', 'Water'),
                  ],
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await _loadUserData();
                _selectRandomTip();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Welcome Text
                      _isLoading
                          ? const SizedBox(
                              height: 32,
                              child: Center(
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : Text(
                              'Welcome back, $_username!',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                      const SizedBox(height: 28),

                      // MindBot Card moved to top
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: Theme.of(context).colorScheme.outlineVariant,
                            width: 1,
                          ),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => Navigator.pushNamed(context, '/chatbot'),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.psychology,
                                    size: 24,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Chat with MindBot',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        'Get help and support',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_forward_ios,
                                  size: 16,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Steps Progress Card
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: Theme.of(context).colorScheme.outlineVariant,
                            width: 1,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Daily Steps',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined),
                                    onPressed: _showGoalDialog,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '$_steps steps',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Goal: $_dailyGoal',
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: LinearProgressIndicator(
                                  value: _steps / _dailyGoal,
                                  minHeight: 8,
                                  backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16), // Changed from 28 to 16

                      // Quick Actions Grid
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 1.5,
                        children: [
                          _buildQuickActionCard(
                            'Medicines',
                            Icons.medication,
                            () => Navigator.pushNamed(context, '/medicines'),
                          ),
                          _buildQuickActionCard(
                            'Meals',
                            Icons.restaurant,
                            () => Navigator.pushNamed(context, '/meals'),
                          ),
                          _buildQuickActionCard(
                            'Workouts',
                            Icons.fitness_center,
                            () => Navigator.pushNamed(context, '/workouts'),
                          ),
                          _buildQuickActionCard(
                            'Sleep',
                            Icons.bed,
                            () => Navigator.pushNamed(context, '/sleep'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),

                      // Healthcare Professionals Chat Card
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: Theme.of(context).colorScheme.outlineVariant,
                            width: 1,
                          ),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => Navigator.pushNamed(context, '/health-chat'),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.secondaryContainer,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.health_and_safety,
                                    size: 24,
                                    color: Theme.of(context).colorScheme.secondary,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Healthcare Professionals',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        'Chat with specialists',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_forward_ios,
                                  size: 16,
                                  color: Theme.of(context).colorScheme.secondary,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Mood Tracker
                      _buildMoodTrackerCard(),
                      const SizedBox(height: 28),

                      // Water Tracker with improved design
                      _buildWaterTrackerCard(),
                      const SizedBox(height: 28),

                      // Daily Tip with new design
                      _buildDailyTipCard(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Constrói os cards de ação rápida (Medicamentos, Refeições, etc)
  Widget _buildQuickActionCard(String title, IconData icon, VoidCallback onTap) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Constrói o card de acompanhamento de água
  Widget _buildWaterTrackerCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.water_drop,
                      color: Theme.of(context).colorScheme.primary,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Water Intake',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                Text(
                  '$_waterGlasses/8 glasses',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: _waterGlasses / 8,
                minHeight: 10,
                backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton.filled(
                  onPressed: () {
                    if (_waterGlasses > 0) {
                      _updateWaterIntake(_waterGlasses - 1);
                    }
                  },
                  icon: const Icon(Icons.remove),
                  style: IconButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    foregroundColor: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 24),
                IconButton.filled(
                  onPressed: () {
                    if (_waterGlasses < 8) {
                      _updateWaterIntake(_waterGlasses + 1);
                    }
                  },
                  icon: const Icon(Icons.add),
                  style: IconButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    foregroundColor: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Constrói o card de dica diária de saúde
  Widget _buildDailyTipCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant,
          width: 1,
        ),
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
                      Icons.lightbulb_outline,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Daily Tip',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _selectRandomTip,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(_dailyTip),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStat(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  Widget _buildQuickAction(IconData icon, String label, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? Theme.of(context).primaryColor.withOpacity(0.3)
                  : Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? Theme.of(context).primaryColor.withOpacity(0.5)
                    : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Icon(
              icon,
              color: isDark
                  ? Colors.white
                  : Theme.of(context).primaryColor,
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodButton(String emoji, String mood) {
    final isSelected = _currentMood == mood;
    return InkWell(
      onTap: () => _updateMood(mood),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? _moods[mood]!['color'].withOpacity(0.2) : null,
          border: Border.all(
            color: isSelected ? _moods[mood]!['color'] : Colors.transparent,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 4),
            Text(
              _moods[mood]!['text'],
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? _moods[mood]!['color'] : Colors.grey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(String title, IconData icon, Color color) {
    return Card(
      margin: const EdgeInsets.only(right: 16),
      child: Container(
        width: 120,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewsCard(String title, String subtitle) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 800),
      builder: (context, double value, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Card(
        child: SizedBox(
          width: 300,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Constrói o card de acompanhamento do humor
  Card _buildMoodTrackerCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'How are you feeling today?',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                if (_currentMood.isNotEmpty)
                  Text(
                    'Last updated: ${_lastMoodUpdate.hour}:${_lastMoodUpdate.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: _moods.entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: _buildMoodButton(entry.value['emoji'], entry.key),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
