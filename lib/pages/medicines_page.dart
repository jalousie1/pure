import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/medicine.dart';
import 'dart:convert';

class MedicinesPage extends StatefulWidget {
  const MedicinesPage({super.key});

  @override
  State<MedicinesPage> createState() => _MedicinesPageState();
}

class _MedicinesPageState extends State<MedicinesPage> with SingleTickerProviderStateMixin {
  List<Medicine> _medicines = [];
  bool _isLoading = true;
  late AnimationController _animationController;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadMedicines();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMedicines() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists && doc.data()!.containsKey('medicines')) {
        final medicinesJson = doc.data()!['medicines'] as String;
        final medicinesList = jsonDecode(medicinesJson) as List;
        setState(() {
          _medicines = medicinesList
              .map((med) => Medicine.fromJson(Map<String, dynamic>.from(med)))
              .toList();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load medicines')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveMedicines() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final medicinesJson = jsonEncode(_medicines.map((m) => m.toJson()).toList());
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'medicines': medicinesJson});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save medicines')),
      );
    }
  }

  Future<TimeOfDay?> _selectTime(BuildContext context) async {
    return showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
  }

  Future<void> _addMedicine() async {
    await showDialog(
      context: context,
      builder: (context) => _buildMedicineDialog(),
    );
  }

  Widget _buildMedicineDialog({Medicine? medicine}) {
    final nameController = TextEditingController(text: medicine?.name);
    final doseController = TextEditingController(text: medicine?.dose);
    TimeOfDay selectedTime = medicine?.time ?? TimeOfDay.now();

    return StatefulBuilder(
      builder: (context, setState) {
        return AlertDialog(
          title: Text(
            medicine == null ? 'Adicionar Medicamento' : 'Editar Medicamento',
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Campo de texto para o nome do medicamento
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nome do Medicamento',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                // Campo de texto para a dose
                TextField(
                  controller: doseController,
                  decoration: const InputDecoration(
                    labelText: 'Dose',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                // Seletor de horário com UI aprimorada
                InkWell(
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: selectedTime,
                    );
                    if (time != null) {
                      setState(() => selectedTime = time);
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Horário',
                      border: OutlineInputBorder(),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
                        ),
                        const Icon(Icons.access_time),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () async {
                final newMedicine = Medicine(
                  name: nameController.text,
                  dose: doseController.text,
                  hour: selectedTime.hour,
                  minute: selectedTime.minute,
                );

                setState(() {
                  if (medicine == null) {
                    _medicines.add(newMedicine);
                  } else {
                    final index = _medicines.indexOf(medicine);
                    _medicines[index] = newMedicine;
                  }
                });
                await _saveMedicines();
                if (mounted) Navigator.pop(context);
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );
  }

  // Add new method to build summary card
  Widget _buildMedicineSummaryCard() {
    // Group medicines by time periods
    final morningMeds = _medicines.where((m) => m.hour >= 5 && m.hour < 12).length;
    final afternoonMeds = _medicines.where((m) => m.hour >= 12 && m.hour < 18).length;
    final eveningMeds = _medicines.where((m) => m.hour >= 18 || m.hour < 5).length;

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
              'Resumo de Medicamentos',
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
                  icon: Icons.wb_sunny,
                  label: 'Manhã',
                  value: '$morningMeds',
                ),
                _buildSummaryItem(
                  icon: Icons.wb_twighlight,
                  label: 'Tarde',
                  value: '$afternoonMeds',
                ),
                _buildSummaryItem(
                  icon: Icons.nights_stay,
                  label: 'Noite',
                  value: '$eveningMeds',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Add helper method for summary items
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
    // Sort medicines by time
    final sortedMedicines = List<Medicine>.from(_medicines)
      ..sort((a, b) {
        if (a.hour != b.hour) return a.hour.compareTo(b.hour);
        return a.minute.compareTo(b.minute);
      });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Medicamentos'),
        centerTitle: true,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildMedicineSummaryCard(),
                const SizedBox(height: 24),
                if (_medicines.isEmpty)
                  Center(
                    child: Text(
                      'Nenhum medicamento registrado',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: sortedMedicines.length,
                    itemBuilder: (context, index) {
                      final medicine = sortedMedicines[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: _buildMedicineCard(medicine, index),
                      );
                    },
                  ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addMedicine,
        icon: const Icon(Icons.add),
        label: const Text('Novo medicamento'),
      ),
    );
  }

  // Add helper method to group and sort medicines
  Map<String, List<Medicine>> _groupAndSortMedicines() {
    final groups = <String, List<Medicine>>{
      'Manhã (5h-12h)': [],
      'Tarde (12h-18h)': [],
      'Noite (18h-5h)': [],
    };

    for (var medicine in _medicines) {
      if (medicine.hour >= 5 && medicine.hour < 12) {
        groups['Manhã (5h-12h)']!.add(medicine);
      } else if (medicine.hour >= 12 && medicine.hour < 18) {
        groups['Tarde (12h-18h)']!.add(medicine);
      } else {
        groups['Noite (18h-5h)']!.add(medicine);
      }
    }

    // Sort medicines within each group by time
    groups.forEach((key, medicines) {
      medicines.sort((a, b) {
        if (a.hour != b.hour) return a.hour.compareTo(b.hour);
        return a.minute.compareTo(b.minute);
      });
    });

    // Remove empty groups
    groups.removeWhere((key, medicines) => medicines.isEmpty);

    return groups;
  }

  // Adicione o método _buildMedicineCard para criar cartões de medicamento com UI aprimorada
  Widget _buildMedicineCard(Medicine medicine, int index) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          medicine.name,
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(medicine.dose),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  '${medicine.hour.toString().padLeft(2, '0')}:${medicine.minute.toString().padLeft(2, '0')}',
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Text('Editar'),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Text('Excluir'),
            ),
          ],
          onSelected: (value) async {
            if (value == 'edit') {
              await _editMedicine(medicine);
            } else if (value == 'delete') {
              setState(() {
                _medicines.remove(medicine);
              });
              await _saveMedicines();
            }
          },
        ),
      ),
    );
  }

  // Adicione um método para editar um medicamento
  Future<void> _editMedicine(Medicine medicine) async {
    await showDialog(
      context: context,
      builder: (context) => _buildMedicineDialog(medicine: medicine),
    );
  }
}