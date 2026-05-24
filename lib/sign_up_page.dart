import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  String? _fullName;
  String? _email;
  String? _phone;
  String? _password;
  String _selectedRole = 'investor'; // Default role

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
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back Button
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Color(0xFF00A9C1), size: 28),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(height: 20),
                
                // Logo
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    padding: const EdgeInsets.all(12),
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
                ),
                const SizedBox(height: 24),
                
                // Title
                Center(
                  child: Text(
                    'Create Account',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                
                // Full Name Field
                _buildTextField(
                  hint: "Full Name",
                  icon: Icons.person_outline,
                  onSaved: (v) => _fullName = v,
                  validator: (val) => val == null || val.isEmpty ? "Required" : null,
                  isDark: isDark,
                  textColor: textColor,
                ),
                const SizedBox(height: 16),

                // Email Field
                _buildTextField(
                  hint: "Email",
                  icon: Icons.email_outlined,
                  onSaved: (v) => _email = v,
                  validator: (val) => val == null || !val.contains('@') ? "Invalid email" : null,
                  isDark: isDark,
                  textColor: textColor,
                ),
                const SizedBox(height: 16),

                // Phone Number Field
                _buildTextField(
                  hint: "Phone Number",
                  icon: Icons.phone_outlined,
                  onSaved: (v) => _phone = v,
                  validator: (val) => val == null || val.isEmpty ? "Required" : null,
                  isDark: isDark,
                  textColor: textColor,
                ),
                const SizedBox(height: 16),

                // Password Field
                _buildTextField(
                  hint: "Password",
                  icon: Icons.lock_outline,
                  obscure: _obscurePassword,
                  onSaved: (v) => _password = v,
                  validator: (val) => val == null || val.length < 6 ? "Min 6 chars" : null,
                  suffix: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: isDark ? Colors.white54 : const Color(0xFF9E9E9E),
                      size: 22,
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  isDark: isDark,
                  textColor: textColor,
                ),
                const SizedBox(height: 24),
                
                // Role Selection Label
                Text(
                  'Join As',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Role Selection Cards
                Row(
                  children: [
                    Expanded(
                      child: _buildRoleCard(
                        "Project Owner",
                        Icons.business_center_outlined,
                        _selectedRole == 'owner',
                        isDark,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildRoleCard(
                        "Investor",
                        Icons.trending_up,
                        _selectedRole == 'investor',
                        isDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Create Account Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00A9C1),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    child: const Text(
                      'Create Account',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Sign In Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Already have an account? ",
                      style: TextStyle(
                        color: secondaryTextColor,
                        fontSize: 15,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Text(
                        "Sign In",
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
      ),
    );
  }

  Widget _buildRoleCard(String role, IconData icon, bool isSelected, bool isDark) {
    
    final cardColor = isDark ? const Color(0xFF2A2A2A) : Colors.white;
    final borderColor = isSelected 
        ? const Color(0xFF00A9C1) 
        : (isDark ? Colors.white24 : const Color(0xFFE0E0E0));
    final iconColor = isSelected 
        ? const Color(0xFF00A9C1) 
        : (isDark ? Colors.white70 : const Color(0xFF757575));
    final textColor = isSelected 
        ? const Color(0xFF00A9C1) 
        : (isDark ? Colors.white70 : const Color(0xFF757575));


    return GestureDetector(
      onTap: () => setState(() => _selectedRole = role == 'Project Owner' ? 'owner' : 'investor'),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF00A9C1).withValues(alpha: 0.1) : cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: borderColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: iconColor,
              size: 32,
            ),
            const SizedBox(height: 12),
            Text(
              role,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textColor,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 13,
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
      _handleSignUp();
    }
  }

  Future<void> _handleSignUp() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
          child: CircularProgressIndicator(color: Color(0xFF00A9C1)),
        ),
      );
      
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _email!.trim(),
        password: _password!.trim(),
      );
      
      if (credential.user != null) {
        await FirebaseFirestore.instance.collection('users').doc(credential.user!.uid).set({
          'fullName': _fullName,
          'email': _email,
          'phone': _phone,
          'role': _selectedRole,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      if (!mounted) return;
      Navigator.pop(context); // Close loading
      Navigator.pushNamedAndRemoveUntil(
        context,
        _selectedRole == 'owner' ? '/owner' : '/investor',
        (r) => false,
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

