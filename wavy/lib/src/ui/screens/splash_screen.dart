import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../local_storage/hive_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;

      // Check directly — these are synchronous and available immediately
      final currentUser = FirebaseAuth.instance.currentUser;
      final onboardingDone = HiveService().getOnboardingComplete();

      if (currentUser != null && onboardingDone) {
        context.go('/feed');
      } else {
        context.go('/language');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Image.asset(
          'assets/wavy_logo_new.png',
          width: MediaQuery.of(context).size.width * 0.7,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
