import 'package:flutter/material.dart';

class StartPageWidget extends StatelessWidget {
  const StartPageWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.spa_outlined,
                size: 80,
                color: colorScheme.primary,
              ),
              const SizedBox(height: 32),
              Text(
                'PureLife',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w300,
                  letterSpacing: 2,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 64),
              FilledButton(
                onPressed: () => Navigator.pushNamed(context, '/login'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: colorScheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  'Login',
                  style: TextStyle(fontSize: 16, letterSpacing: 1),
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => Navigator.pushNamed(context, '/register'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: colorScheme.primary, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Text(
                  'Register',
                  style: TextStyle(
                    fontSize: 16,
                    letterSpacing: 1,
                    color: colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/terms'),
                child: Text(
                  'Ao continuar você concorda com nossos termos e condições',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.primary,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
