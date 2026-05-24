import 'package:flutter/material.dart';
import 'package:flutter_application_1/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // bool _notificationsEnabled = true; // Removed as per request

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black,
        elevation: 0,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 20),
          _buildSectionHeader('Appearance'),
          SwitchListTile(
            title: const Text('Dark Mode'),
            subtitle: const Text('Enable dark theme'),
            value: themeProvider.isDarkMode,
            contentPadding: const EdgeInsets.symmetric(horizontal: 24),
            onChanged: (bool value) {
              themeProvider.toggleTheme();
            },
          ),
          const Divider(),
          _buildSectionHeader('Account & Security'),
          
          // Change Password
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 24),
            leading: const Icon(Icons.lock_reset, color: Color(0xFF00A9C1)),
            title: const Text('Change Password'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _showChangePasswordDialog,
          ),
          
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 24),
            leading: const Icon(Icons.privacy_tip_outlined, color: Color(0xFF00A9C1)),
            title: const Text('Privacy Policy'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _showPrivacyPolicy,
          ),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 24),
            leading: const Icon(Icons.description_outlined, color: Color(0xFF00A9C1)),
            title: const Text('Terms of Service'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _showTermsOfService,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  void _showChangePasswordDialog() {
    final passwordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final inputBorderColor = isDark ? Colors.white24 : Colors.grey.shade300;
        final inputFillColor = isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100;
        final textColor = isDark ? Colors.white : Colors.black87;

        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          child: Container(
            padding: const EdgeInsets.all(24),
            constraints: const BoxConstraints(maxWidth: 400),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00A9C1).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.lock_reset, color: Color(0xFF00A9C1), size: 32),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Change Password',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter your new password below.',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white54 : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // New Password Field
                  TextFormField(
                    controller: passwordController,
                    obscureText: true,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      labelText: 'New Password',
                      labelStyle: TextStyle(color: isDark ? Colors.white60 : Colors.grey[600]),
                      prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF00A9C1)),
                      filled: true,
                      fillColor: inputFillColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: inputBorderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: inputBorderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF00A9C1), width: 2),
                      ),
                    ),
                    validator: (value) =>
                        value != null && value.length < 6 ? 'Password must be at least 6 chars' : null,
                  ),
                  const SizedBox(height: 16),
                  
                  // Confirm Password Field
                  TextFormField(
                    controller: confirmPasswordController,
                    obscureText: true,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      labelText: 'Confirm Password',
                      labelStyle: TextStyle(color: isDark ? Colors.white60 : Colors.grey[600]),
                      prefixIcon: const Icon(Icons.check_circle_outline, color: Color(0xFF00A9C1)),
                      filled: true,
                      fillColor: inputFillColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: inputBorderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: inputBorderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF00A9C1), width: 2),
                      ),
                    ),
                    validator: (value) {
                      if (value != passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),
                  
                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade300),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            foregroundColor: textColor,
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            final scaffoldMessenger = ScaffoldMessenger.of(context);
                            final navigator = Navigator.of(context);
                            
                            if (formKey.currentState!.validate()) {
                              try {
                                final user = FirebaseAuth.instance.currentUser;
                                if (user != null) {
                                  await user.updatePassword(passwordController.text.trim());
                                  if (!mounted) return;
                                  navigator.pop();
                                  scaffoldMessenger.showSnackBar(
                                    const SnackBar(
                                      content: Text('Password updated successfully'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (!mounted) return;
                                navigator.pop(); // Close dialog on error too? Or keep it open? 
                                // User flow: usually error shows on text field, but here we show snackbar. 
                                // Let's keep existing logic: close and verify.
                                // Actually, better UX is to KEEP open and show error. 
                                // But requested was "improve appearance". The logic was fine. 
                                // I will stick to closing to match previous behavior for now unless it breaks.
                                // Wait, the previous logic closed it.
                                scaffoldMessenger.showSnackBar(
                                  SnackBar(
                                    content: Text('Error: $e'), 
                                    backgroundColor: Colors.redAccent
                                  ),
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: const Color(0xFF00A9C1),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Update'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showPrivacyPolicy() {
    _showLegalDialog(
      'Privacy Policy',
      '''
Effective Date: 2025-01-01

1. Introduction
Welcome to Isthmary. We are committed to protecting your privacy and ensuring your personal data is handled responsibly.

2. Data Collection
We collect personal information such as name, email, and investment preferences to provide better services.

3. Data Usage
Your data is used to:
- Connect investors with project owners.
- Process transactions securely.
- Improve our application features.

4. Data Sharing
We do not sell your data. We may share information with third-party service providers (e.g., payment processors) strictly for operational purposes.

5. Security
We verify identities and store data using industry-standard encryption.

6. Your Rights
You can request to view, update, or delete your data by contacting support.
      ''',
    );
  }

  void _showTermsOfService() {
    _showLegalDialog(
      'Terms of Service',
      '''
Effective Date: 2025-01-01

1. Acceptance of Terms
By using Isthmary, you agree to these Terms of Service.

2. User Accounts
- You must provide accurate information.
- You are responsible for maintaining the security of your account.
- "Investors" and "Project Owners" have distinct roles and permissions.

3. Investment Risks
Isthmary connects parties but does not guarantee the success of any project. Investing involves risks, including loss of capital.

4. Prohibited Activities
- Fraudulent schemes.
- Harassment or abuse.
- Posting false information.

5. Termination
We reserve the right to suspend accounts violating these terms.

6. Limitation of Liability
Isthmary is not liable for financial losses incurred through the platform.
      ''',
    );
  }

  void _showLegalDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Text(content, style: const TextStyle(fontSize: 14)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
