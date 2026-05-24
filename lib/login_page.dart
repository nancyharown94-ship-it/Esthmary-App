import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  bool _obscure = true;
  bool _isLoading = false; // Added loading state
  String? _email;
  String? _password;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final backgroundColor = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final secondaryTextColor = isDark ? Colors.white70 : const Color(0xFF757575);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    
                    // Logo
                    Container(
                      width: 100,
                      height: 100,
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'images/ic_logo.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // Title
                    Text(
                      'Welcome Back',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 48),

                    // Email Input
                    _buildTextField(
                      hint: "Email",
                      icon: Icons.email_outlined,
                      onSaved: (val) => _email = val,
                      validator: (val) => val == null || val.isEmpty ? "Required" : null,
                      isDark: isDark,
                      textColor: textColor,
                    ),
                    const SizedBox(height: 16),

                    // Password Input
                    _buildTextField(
                      hint: "Password",
                      icon: Icons.lock_outline,
                      obscure: _obscure,
                      suffix: IconButton(
                        icon: Icon(
                          _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: isDark ? Colors.white54 : const Color(0xFF9E9E9E),
                          size: 22,
                        ),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                      onSaved: (val) => _password = val,
                      validator: (val) => val == null || val.length < 6 ? "Too short" : null,
                      isDark: isDark,
                      textColor: textColor,
                    ),
                    const SizedBox(height: 40),

                    // Login Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submit, // Disable when loading
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00A9C1),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                        child: const Text(
                          'Sign In',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Sign Up Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account? ",
                          style: TextStyle(
                            color: secondaryTextColor,
                            fontSize: 15,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pushNamed(context, '/signup'),
                          child: const Text(
                            'Sign Up',
                            style: TextStyle(
                              color: Color(0xFF00A9C1),
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            // Loading Overlay
            if (_isLoading)
              Container(
                color: Colors.black.withOpacity(0.5),
                child: const Center(
                  child: CircularProgressIndicator(color: Color(0xFF00A9C1)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String hint,
    required IconData icon,
    required bool isDark,
    required Color textColor,
    bool obscure = false,
    Widget? suffix,
    void Function(String?)? onSaved,
    String? Function(String?)? validator,
  }) {
    final fillColor = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF5F5F5);
    final hintColor = isDark ? Colors.white54 : const Color(0xFF9E9E9E);

    return TextFormField(
      obscureText: obscure,
      style: TextStyle(
        color: textColor,
        fontSize: 16,
      ),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: const Color(0xFF00A9C1), size: 22),
        suffixIcon: suffix,
        hintText: hint,
        hintStyle: TextStyle(
          color: hintColor,
          fontSize: 15,
        ),
        filled: true,
        fillColor: fillColor,
        contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF00A9C1), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
      ),
      onSaved: onSaved,
      validator: validator,
    );
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      _handleLogin();
    }
  }

  Future<void> _handleLogin() async {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _isLoading = true);

    String? errorTitle;
    String? errorMessage;
    bool shouldNavigate = false;
    String? targetRoute;
    bool isWarning = false;

    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _email!.trim(),
        password: _password!.trim(),
      );

      if (credential.user != null) {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(credential.user!.uid).get();
        
        if (userDoc.exists) {
          final role = userDoc.data()?['role'];
          shouldNavigate = true;
          targetRoute = role == 'owner' ? '/owner' : '/investor';
        } else {
          errorTitle = 'Profile Missing';
          errorMessage = 'User profile not found. Please contact support.';
          isWarning = true;
        }
      }
    } on FirebaseAuthException catch (e) {
      errorTitle = 'Login Failed';
      errorMessage = 'An unknown error occurred.';

      if (e.code == 'user-not-found') {
        errorTitle = 'User Not Found';
        errorMessage = 'No user found for that email.';
      } else if (e.code == 'wrong-password') {
        errorTitle = 'Wrong Password';
        errorMessage = 'Wrong password provided for that user.';
      } else if (e.code == 'invalid-email') {
        errorTitle = 'Invalid Email';
        errorMessage = 'The email address is not valid.';
      } else if (e.code == 'invalid-credential') {
        errorTitle = 'Invalid Credential';
        errorMessage = 'Invalid username or password.';
      } else {
        errorMessage = e.message ?? errorMessage;
      }
    } catch (e) {
      errorTitle = 'Error';
      errorMessage = e.toString();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }

    if (!mounted) return;

    if (shouldNavigate && targetRoute != null) {
      Navigator.pushNamedAndRemoveUntil(context, targetRoute!, (r) => false);
    } else if (errorTitle != null && errorMessage != null) {
      _showCustomErrorDialog(errorTitle, errorMessage, isWarning);
    }
  }

  void _showCustomErrorDialog(String title, String message, bool isWarning) {
     showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final bgColor = isDark ? const Color(0xFF2A2A2A) : Colors.white;
        final textColor = isDark ? Colors.white : Colors.black87;
        final iconColor = isWarning ? Colors.amber : Colors.red;
        final iconData = isWarning ? Icons.warning_amber_rounded : Icons.error_outline_rounded;

        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: bgColor,
          elevation: 10,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(iconData, size: 40, color: iconColor),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: iconColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'OK',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

