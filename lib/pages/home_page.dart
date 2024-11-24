import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';

class HomePageWidget extends StatefulWidget {
  const HomePageWidget({super.key});

  @override
  State<HomePageWidget> createState() => _HomePageWidgetState();
}

class _HomePageWidgetState extends State<HomePageWidget> {
  int _steps = 0;
  final int _dailyGoal = 10000;
  late String _dailyTip;
  String _username = '';
  bool _isLoading = true;
  
  final List<String> _healthTips = [
    'Beba pelo menos 8 copos de água por dia para manter-se hidratado.',
    'Pratique 30 minutos de atividade física moderada diariamente.',
    'Mantenha uma rotina regular de sono de 7-8 horas por noite.',
    'Inclua frutas e vegetais em todas as refeições principais.',
    'Faça pausas regulares durante o trabalho para alongar-se.',
    'Pratique técnicas de respiração para reduzir o estresse.',
    'Mantenha uma postura adequada ao usar dispositivos eletrônicos.',
    'Coma devagar e mastigue bem os alimentos.',
    'Estabeleça limites saudáveis entre trabalho e descanso.',
    'Proteja sua pele usando protetor solar diariamente.',
    'Pratique mindfulness por alguns minutos todos os dias.',
    'Mantenha um diário de gratidão para bem-estar mental.',
    'Faça exercícios de alongamento ao acordar.',
    'Evite usar eletrônicos uma hora antes de dormir.',
    'Mantenha uma alimentação colorida e variada.',
  ];

  @override
  void initState() {
    super.initState();
    _selectRandomTip();
    _loadUserData();
  }

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
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  void _selectRandomTip() {
    final random = Random();
    setState(() {
      _dailyTip = _healthTips[random.nextInt(_healthTips.length)];
    });
  }

  void _addSteps(int count) {
    setState(() {
      _steps = min(_steps + count, _dailyGoal);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Header
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  'PureLife',
                  style: TextStyle(
                    fontSize: 24,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pushNamed(context, '/profile'),
                  icon: const Icon(Icons.account_circle, color: Colors.white),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                    const SizedBox(height: 24),

                    // Chat button
                    FilledButton.icon(
                      onPressed: () => Navigator.pushNamed(context, '/chatbot'),
                      icon: const Icon(Icons.chat),
                      label: const Text('Chat with MindBot'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(56),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // News section
                    const Text(
                      'Health News',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 200,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _buildNewsCard(
                            'The Benefits of Mediterranean Diet',
                            'New study reveals long-term health benefits',
                          ),
                          const SizedBox(width: 16),
                          _buildNewsCard(
                            'Mindfulness and Stress Reduction',
                            'How daily meditation can improve mental health',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Daily Tip
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.lightbulb_outline),
                                    SizedBox(width: 8),
                                    Text(
                                      'Dica do Dia',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w500,
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
                            const SizedBox(height: 16),
                            Text(_dailyTip),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Progress Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Daily Step Goal',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  '$_steps / $_dailyGoal',
                                  style: TextStyle(
                                    color: _steps >= _dailyGoal ? Colors.green : null,
                                    fontWeight: _steps >= _dailyGoal ? FontWeight.bold : null,
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
                                backgroundColor: Colors.grey.shade200,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildStepButton(1000),
                                _buildStepButton(2000),
                                _buildStepButton(5000),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewsCard(String title, String subtitle) {
    return Card(
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
    );
  }

  Widget _buildStepButton(int steps) {
    return FilledButton.tonal(
      onPressed: () => _addSteps(steps),
      child: Text('+$steps'),
    );
  }
}
