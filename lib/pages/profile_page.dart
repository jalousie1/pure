import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  String _fullName = '';
  String _email = '';
  String _age = '';
  String _cep = '';
  late AnimationController _animationController;
  late List<Animation<Offset>> _slideAnimations;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );

    // Create staggered animations for each info card
    _slideAnimations = List.generate(
      4,
      (index) => Tween<Offset>(
        begin: const Offset(0.5, 0),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval(
            index * 0.2,
            1.0,
            curve: Curves.easeOutCubic,
          ),
        ),
      ),
    );

    _loadUserData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
            _fullName = userData.data()?['full_name'] ?? 'Not provided';
            _email = userData.data()?['email'] ?? 'Not provided';
            _age = userData.data()?['age'] ?? 'Not provided';
            _cep = userData.data()?['CEP'] ?? 'Not provided';
            _isLoading = false;
            _animationController.forward(); // Start animations
          });
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _editProfile() async {
    final TextEditingController fullNameController = TextEditingController(text: _fullName);
    final TextEditingController ageController = TextEditingController(text: _age);
    final TextEditingController cepController = TextEditingController(text: _cep);
    bool isUpdating = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Edit Profile',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 24),
                _buildTextField(fullNameController, 'Full Name', Icons.person_outline),
                const SizedBox(height: 16),
                _buildTextField(ageController, 'Age', Icons.calendar_today_outlined, 
                  isNumber: true),
                const SizedBox(height: 16),
                _buildTextField(cepController, 'CEP', Icons.location_on_outlined, 
                  isNumber: true),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: isUpdating ? null : () async {
                      setDialogState(() => isUpdating = true);
                      try {
                        final user = FirebaseAuth.instance.currentUser;
                        if (user != null) {
                          await FirebaseFirestore.instance
                              .collection('users')
                              .doc(user.uid)
                              .update({
                            'full_name': fullNameController.text.trim(),
                            'age': ageController.text.trim(),
                            'CEP': cepController.text.trim(),
                          });
                          
                          if (mounted) {
                            Navigator.pop(context);
                            _loadUserData(); // Reload user data
                          }
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Failed to update profile')),
                        );
                      } finally {
                        if (mounted) {
                          setDialogState(() => isUpdating = false);
                        }
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: isUpdating
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Save Changes'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool isNumber = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      inputFormatters: isNumber ? [FilteringTextInputFormatter.digitsOnly] : null,
      style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Theme.of(context).colorScheme.primary),
        prefixIcon: Icon(icon, color: Theme.of(context).colorScheme.primary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
      ),
    );
  }

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to logout')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Profile',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onBackground,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.edit,
              color: Theme.of(context).colorScheme.primary,
            ),
            onPressed: _editProfile,
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
            )
          : AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) => Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                          child: Icon(
                            Icons.person,
                            size: 50,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    ..._buildAnimatedInfoTiles(),
                    const Spacer(),
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _logout,
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.red.withOpacity(isDark ? 0.8 : 0.7),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Logout',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  List<Widget> _buildAnimatedInfoTiles() {
    final items = [
      ('Full Name', _fullName, Icons.person_outline),
      ('Email', _email, Icons.email_outlined),
      ('Age', _age, Icons.calendar_today_outlined),
      ('CEP', _cep, Icons.location_on_outlined),
    ];

    return List.generate(
      items.length,
      (index) => SlideTransition(
        position: _slideAnimations[index],
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: _buildInfoTile(items[index].$1, items[index].$2, items[index].$3),
        ),
      ),
    );
  }

  Widget _buildInfoTile(String label, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value.isEmpty ? 'Not provided' : value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
