import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/sleep_record.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

class SleepPage extends StatefulWidget {
  const SleepPage({super.key});

  @override
  State<SleepPage> createState() => _SleepPageState();
}

class _SleepDialogState {
  DateTime selectedDate;
  TimeOfDay bedtime;
  TimeOfDay wakeupTime;

  _SleepDialogState({
    required this.selectedDate,
    required this.bedtime,
    required this.wakeupTime,
  });
}

class _SleepPageState extends State<SleepPage> with SingleTickerProviderStateMixin {
  List<SleepRecord> _sleepRecords = [];
  bool _isLoading = true;
  int _sleepGoalInMinutes = 8 * 60; // 8 horas em minutos
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadSleepData();
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
    
    // Add this to scroll to the most recent record after loading
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToMostRecent();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadSleepData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists && doc.data()!.containsKey('sleepRecords')) {
        final sleepJson = doc.data()!['sleepRecords'] as String;
        final sleepList = jsonDecode(sleepJson) as List;
        setState(() {
          _sleepRecords = sleepList
              .map((record) => SleepRecord.fromJson(Map<String, dynamic>.from(record)))
              .toList();
        });
      }
      if (doc.exists && doc.data()!.containsKey('sleepGoalInMinutes')) {
        _sleepGoalInMinutes = doc.data()!['sleepGoalInMinutes'] as int;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load sleep data')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSleepData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final sleepJson = jsonEncode(_sleepRecords.map((s) => s.toJson()).toList());
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'sleepRecords': sleepJson,
        'sleepGoalInMinutes': _sleepGoalInMinutes,
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save sleep data')),
      );
    }
  }

  Future<void> _addSleepRecord() async {
    await showDialog(
      context: context,
      builder: (context) => _buildSleepDialog(),
    );
  }

  Widget _buildSleepDialog({SleepRecord? record}) {
    final dialogState = _SleepDialogState(
      selectedDate: record?.date ?? DateTime.now(),
      bedtime: record != null
          ? TimeOfDay.fromDateTime(record.bedtime)
          : const TimeOfDay(hour: 22, minute: 0),
      wakeupTime: record != null
          ? TimeOfDay.fromDateTime(record.wakeupTime)
          : const TimeOfDay(hour: 6, minute: 0),
    );

    return StatefulBuilder(
      builder: (context, setState) {
        return AlertDialog(
          title: Text(record == null ? 'Add Sleep Record' : 'Edit Sleep Record'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Seletor de Data
                _buildDateSelector(context, dialogState, setState),
                const SizedBox(height: 16),
                
                // Seletor de Hora de Dormir
                _buildTimeSelector(
                  context: context,
                  title: 'Bedtime',
                  icon: Icons.bedtime,
                  time: dialogState.bedtime,
                  onTimeSelected: (time) {
                    setState(() => dialogState.bedtime = time);
                  },
                ),
                const SizedBox(height: 16),
                
                // Seletor de Hora de Acordar
                _buildTimeSelector(
                  context: context,
                  title: 'Wake up time',
                  icon: Icons.alarm,
                  time: dialogState.wakeupTime,
                  onTimeSelected: (time) {
                    setState(() => dialogState.wakeupTime = time);
                  },
                ),
                const SizedBox(height: 16),
                
                // Duração do Sono
                _buildDurationDisplay(context, dialogState),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => _saveSleepRecord(context, dialogState, record),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDateSelector(BuildContext context, _SleepDialogState state, StateSetter setState) {
    return Card(
      child: InkWell(
        onTap: () async {
          final date = await showDatePicker(
            context: context,
            initialDate: state.selectedDate,
            firstDate: DateTime.now().subtract(const Duration(days: 365)),
            lastDate: DateTime.now(),
          );
          if (date != null) {
            setState(() => state.selectedDate = date);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.calendar_today),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Date',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Text(
                    DateFormat('dd/MM/yyyy').format(state.selectedDate),
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeSelector({
    required BuildContext context,
    required String title,
    required IconData icon,
    required TimeOfDay time,
    required Function(TimeOfDay) onTimeSelected,
  }) {
    return Card(
      child: InkWell(
        onTap: () async {
          final newTime = await showTimePicker(
            context: context,
            initialTime: time,
            helpText: title,
          );
          if (newTime != null) {
            onTimeSelected(newTime);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Text(
                    time.format(context),
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDurationDisplay(BuildContext context, _SleepDialogState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.access_time,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sleep duration',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              Text(
                _calculateDuration(state.bedtime, state.wakeupTime),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _saveSleepRecord(BuildContext context, _SleepDialogState state, SleepRecord? record) {
    final bedtimeDateTime = DateTime(
      state.selectedDate.year,
      state.selectedDate.month,
      state.selectedDate.day,
      state.bedtime.hour,
      state.bedtime.minute,
    );
    var wakeupDateTime = DateTime(
      state.selectedDate.year,
      state.selectedDate.month,
      state.selectedDate.day,
      state.wakeupTime.hour,
      state.wakeupTime.minute,
    );

    // Se a hora de acordar for antes da hora de dormir, adicionar um dia
    if (state.wakeupTime.hour < state.bedtime.hour ||
        (state.wakeupTime.hour == state.bedtime.hour &&
            state.wakeupTime.minute < state.bedtime.minute)) {
      wakeupDateTime = wakeupDateTime.add(const Duration(days: 1));
    }

    final newRecord = SleepRecord(
      date: state.selectedDate,
      bedtime: bedtimeDateTime,
      wakeupTime: wakeupDateTime,
    );

    setState(() {
      if (record == null) {
        _sleepRecords.add(newRecord);
      } else {
        final index = _sleepRecords.indexOf(record);
        _sleepRecords[index] = newRecord;
      }
    });

    _saveSleepData();
    Navigator.pop(context);
  }

  String _calculateDuration(TimeOfDay bedtime, TimeOfDay wakeup) {
    int bedMinutes = bedtime.hour * 60 + bedtime.minute;
    int wakeMinutes = wakeup.hour * 60 + wakeup.minute;
    
    if (wakeMinutes < bedMinutes) {
      wakeMinutes += 24 * 60; // Adiciona 24 horas se atravessar a meia-noite
    }
    
    int durationMinutes = wakeMinutes - bedMinutes;
    int hours = durationMinutes ~/ 60;
    int minutes = durationMinutes % 60;
    
    return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
  }

  SleepRecord? _getLatestRecordForCurrentDate() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    return _sleepRecords
        .where((record) => record.date.isAtSameMomentAs(today))
        .fold<SleepRecord?>(
          null,
          (latest, record) =>
              latest == null || record.date.isAfter(latest.date) ? record : latest,
        );
  }

  SleepRecord? _getMostRecentRecord() {
    if (_sleepRecords.isEmpty) return null;
    return _sleepRecords.reduce((a, b) => a.date.isAfter(b.date) ? a : b);
  }

  Widget _buildSleepGoalCard() {
    final latestRecord = _getMostRecentRecord();
    double totalSleepMinutes = latestRecord?.durationInMinutes.toDouble() ?? 0;
    // Cap the progress at 100%
    double progress = (totalSleepMinutes / _sleepGoalInMinutes).clamp(0.0, 1.0);

    return Hero(
      tag: 'sleepGoalCard',
      child: Card(
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
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Sleep Goal',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  if (latestRecord != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      '(${DateFormat('dd/MM').format(latestRecord.date)})',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 24),
              TweenAnimationBuilder(
                tween: Tween<double>(begin: 0, end: progress),
                duration: const Duration(milliseconds: 1500),
                builder: (context, double value, child) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        height: 120,
                        width: 120,
                        child: CircularProgressIndicator(
                          value: value,
                          strokeWidth: 8,
                          backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                      Column(
                        children: [
                          if (latestRecord != null) ...[
                            Text(
                              '${(totalSleepMinutes ~/ 60)}h ${(totalSleepMinutes % 60).toString().padLeft(2, '0')}m',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'of ${(_sleepGoalInMinutes ~/ 60)}h',
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ] else ...[
                            Text(
                              'No records',
                              style: TextStyle(
                                fontSize: 16,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                            Text(
                              'Goal: ${(_sleepGoalInMinutes ~/ 60)}h',
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSleepRecordCard(SleepRecord record) {
    String duration = '${record.durationInMinutes ~/ 60}h ${(record.durationInMinutes % 60).toString().padLeft(2, '0')}m';
    
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(1, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      )),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
            width: 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => showDialog(
            context: context,
            builder: (context) => _buildSleepDialog(record: record),
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
                      DateFormat('dd/MM/yyyy').format(record.date),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () async {
                        setState(() {
                          _sleepRecords.remove(record);
                        });
                        await _saveSleepData();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildTimeInfo(
                        context,
                        Icons.bedtime_outlined,
                        'Slept',
                        TimeOfDay.fromDateTime(record.bedtime).format(context),
                      ),
                    ),
                    Expanded(
                      child: _buildTimeInfo(
                        context,
                        Icons.wb_sunny_outlined,
                        'Woke up',
                        TimeOfDay.fromDateTime(record.wakeupTime).format(context),
                      ),
                    ),
                    Expanded(
                      child: _buildTimeInfo(
                        context,
                        Icons.timer_outlined,
                        'Duration',
                        duration,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeInfo(BuildContext context, IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
          size: 20,
        ),
        const SizedBox(height: 4),
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
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Future<void> _setSleepGoal() async {
    final controller = TextEditingController(
      text: (_sleepGoalInMinutes ~/ 60).toString()
    );

    bool? result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Sleep Goal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Sleep hours',
                helperText: 'Between 4 and 12 hours',
                suffixText: 'hours',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
              onSubmitted: (value) {
                _validateAndSaveGoal(controller.text, context);
              },
            ),
            const SizedBox(height: 8),
            Text(
              'Current: ${(_sleepGoalInMinutes ~/ 60)}h',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => _validateAndSaveGoal(controller.text, context),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sleep goal updated successfully!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _validateAndSaveGoal(String value, BuildContext context) async {
    final hours = int.tryParse(value);
    
    if (hours == null) {
      _showGoalError('Please enter a valid number');
      return;
    }

    if (hours < 4 || hours > 12) {
      _showGoalError('Goal must be between 4 and 12 hours');
      return;
    }

    final newGoalInMinutes = hours * 60;
    setState(() {
      _sleepGoalInMinutes = newGoalInMinutes;
    });

    try {
      await _saveSleepData();
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _showGoalError('Error saving goal');
    }
  }

  void _showGoalError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  double _calculateAverageSleep() {
    if (_sleepRecords.isEmpty) return 0;
    int totalMinutes = _sleepRecords.fold(
      0,
      (sum, record) => sum + record.durationInMinutes,
    );
    return totalMinutes / _sleepRecords.length;
  }

  Widget _buildAnalyticsCard() {
    final avgSleep = _calculateAverageSleep();
    final recentRecord = _getMostRecentRecord();
    
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Analytics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildAnalyticItem(
                    'Overall Average',
                    '${(avgSleep ~/ 60)}h ${(avgSleep % 60).toInt()}m',
                    Icons.analytics_outlined,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildAnalyticItem(
                    'Latest Record',
                    recentRecord != null
                        ? '${(recentRecord.durationInMinutes ~/ 60)}h ${(recentRecord.durationInMinutes % 60)}m'
                        : '-',
                    Icons.schedule,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _scrollToMostRecent() {
    if (_sleepRecords.isNotEmpty && _scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sleep Tracker'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: _setSleepGoal,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : FadeTransition(
              opacity: _fadeAnimation,
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                children: [
                  _buildSleepGoalCard(),
                  const SizedBox(height: 16),
                  _buildAnalyticsCard(),
                  const SizedBox(height: 24),
                  if (_sleepRecords.isEmpty)
                    Center(
                      child: Text(
                        'No sleep records yet',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  else
                    ..._sleepRecords.reversed.map(_buildSleepRecordCard).toList(),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addSleepRecord,
        icon: const Icon(Icons.add),
        label: const Text('New record'),
      ),
    );
  }
}
