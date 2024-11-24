import 'package:flutter/material.dart';

class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms and Conditions'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Terms and Conditions of Use',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Text(
              '1. Acceptance of Terms\n\n'
              'By accessing and using the PureLife app, you agree to comply with these terms and conditions of use. If you do not agree with any part of these terms, you should not use the app.\n\n'
              
              '2. Service Description\n\n'
              'PureLife is a health and wellness app that offers features such as:\n'
              '• Physical activity and step tracking\n'
              '• Medication logging and reminders\n'
              '• Meal and hydration tracking\n'
              '• Sleep monitoring\n'
              '• Virtual health assistant (MindBot)\n'
              '• Mood and wellness tracking\n\n'
              
              '3. User Responsibilities\n\n'
              'The user is responsible for:\n'
              '• Providing accurate and truthful information\n'
              '• Maintaining account and password security\n'
              '• Using the app in accordance with applicable laws\n'
              '• Not sharing sensitive health information with other users\n\n'
              
              '4. Service Limitations\n\n'
              'PureLife does not replace professional medical care. Information and suggestions provided by the app, including MindBot, are for informational and general wellness purposes only.\n\n'
              
              '5. Privacy and Data\n\n'
              'We collect and process data such as:\n'
              '• Profile information (name, age, ZIP code)\n'
              '• Physical activity and step data\n'
              '• Medication and meal records\n'
              '• Mood and wellness information\n'
              '• MindBot interactions\n\n'
              'Your data is protected and processed according to our Privacy Policy and applicable data protection laws.\n\n'
              
              '6. Device Permissions\n\n'
              'The app requires access to:\n'
              '• Physical activity sensors\n'
              '• Storage for local data\n'
              '• Internet for synchronization and MindBot functionality\n\n'
              
              '7. Security\n\n'
              'We use security technologies to protect your data, including:\n'
              '• Secure authentication via Firebase\n'
              '• Encryption of sensitive data\n'
              '• Data access control\n\n'
              
              '8. Changes to Terms\n\n'
              'We reserve the right to modify these terms at any time. Significant changes will be notified through the app.\n\n'
              
              '9. Contact\n\n'
              'For questions about these terms or the app, contact us through MindBot or our support channels.\n\n'
              
              '10. Termination\n\n'
              'We reserve the right to terminate access to the app in case of violation of these terms or inappropriate use of the service.',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
