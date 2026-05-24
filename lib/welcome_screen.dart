import 'package:flutter/material.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF010A12),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF010A12),
              Color(0xFF001A1A),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // New App Logo
                  Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF46EABB).withValues(alpha: 0.1),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'images/app_logo_new.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Welcome Card with Glassmorphism effect
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      color: Colors.white.withValues(alpha: 0.05),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                        width: 1.5,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          children: [
                            // App Title with Gradient
                            ShaderMask(
                              shaderCallback: (bounds) => const LinearGradient(
                                colors: [Color(0xFF46EABB), Color(0xFF00BFA5)],
                              ).createShader(bounds),
                              child: const Text(
                                'Isthmary',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 1.5,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Description
                            const Text(
                              'Premium Platform for Smart Investment and Financial Growth',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white70,
                                height: 1.5,
                                fontWeight: FontWeight.w300,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 40),

                            // User Type Selection Title
                            const Text(
                              'Choose your account type to continue',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF46EABB),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),

                            // User Type Buttons Row
                            Row(
                              children: [
                                // Investor Button
                                Expanded(
                                  child: _buildUserTypeButton(
                                    context,
                                    title: 'Investor',
                                    icon: Icons.trending_up,
                                    userType: 'investor',
                                  ),
                                ),
                                const SizedBox(width: 16),
                                // Owner Button
                                Expanded(
                                  child: _buildUserTypeButton(
                                    context,
                                    title: 'Owner',
                                    icon: Icons.business_center,
                                    userType: 'owner',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),

                            // Footer Text
                            Text(
                              "By continuing, you agree to the Terms of Service and Privacy Policy.",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.3),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserTypeButton(
    BuildContext context, {
    required String title,
    required IconData icon,
    required String userType,
  }) {
    return SizedBox(
      height: 120,
      child: ElevatedButton(
        onPressed: () {
          Navigator.pushNamed(context, '/login', arguments: userType);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white.withValues(alpha: 0.05),
          foregroundColor: const Color(0xFF46EABB),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: const Color(0xFF46EABB).withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          elevation: 0,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF46EABB).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: const Color(0xFF46EABB)),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16, 
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
