import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class InvestPage extends StatefulWidget {
  final String? projectId;
  final String? projectTitle;
  final String? ownerId;

  const InvestPage({
    super.key,
    this.projectId,
    this.projectTitle,
    this.ownerId,
  });

  @override
  State<InvestPage> createState() => _InvestPageState();
}

class _InvestPageState extends State<InvestPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _ratioController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
    _ratioController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitInvestment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not logged in");
      
      // Fetch user name (optional, but good for display)
      String investorName = "Unknown Investor";
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        investorName = userDoc.data()?['fullName'] ?? investorName;
      }

      final proposalData = {
        'projectId': widget.projectId,
        'projectTitle': widget.projectTitle,
        'ownerId': widget.ownerId,
        'investorId': user.uid,
        'investorName': investorName,
        'amount': double.tryParse(_amountController.text) ?? 0.0,
        'equity': double.tryParse(_ratioController.text) ?? 0.0,
        'description': _descriptionController.text.trim(),
        'status': 'PENDING',
        'createdAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance.collection('proposals').add(proposalData);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Proposal Sent Successfully!')),
      );
      Navigator.pop(context);

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          "SUBMIT PROPOSAL",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Project Info Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: isDark 
                      ? const LinearGradient(colors: [Color(0xFF2C2C2C), Color(0xFF1E1E1E)])
                      : const LinearGradient(colors: [Color(0xFFE0F7FA), Color(0xFFF0F4C3)]), // Light teal/lime mix or just white
                  color: isDark ? null : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF00A9C1).withValues(alpha: 0.2)),
                  boxShadow: isDark 
                      ? null 
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "PROJECT",
                      style: TextStyle(
                        fontSize: 10,
                        color: Color(0xFF00A9C1),
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.projectTitle ?? "Untitled Project",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              
              Text(
                "Offer Details",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 20),
              
              // Investment Amount Field
              _buildModernTextField(
                isDark: isDark,
                controller: _amountController,
                label: "Investment Amount (EGP)",
                hint: "e.g. 50,000",
                icon: Icons.monetization_on_outlined,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter the amount';
                  if (double.tryParse(value) == null) return 'Please enter a valid number';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Ratio/Percentage Field
              _buildModernTextField(
                isDark: isDark,
                controller: _ratioController,
                label: "Desired Equity (%)",
                hint: "e.g. 15",
                icon: Icons.pie_chart_outline,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter the percentage';
                  if (double.tryParse(value) == null) return 'Please enter a valid number';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Optional Description Field
              _buildModernTextField(
                isDark: isDark,
                controller: _descriptionController,
                label: "Proposal Message (Optional)",
                hint: "Add notes, terms, or questions...",
                icon: Icons.chat_bubble_outline_rounded,
                maxLines: 4,
              ),
              const SizedBox(height: 48),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 55,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00A9C1), Color(0xFF00BFA5)],
                    ),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00A9C1).withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitInvestment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: _isLoading 
                      ? CircularProgressIndicator(color: isDark ? const Color(0xFF010A12) : Colors.white)
                      : Text(
                          "SEND PROPOSAL",
                          style: TextStyle(
                            fontSize: 16, 
                            fontWeight: FontWeight.bold,
                            color: isDark ? const Color(0xFF010A12) : Colors.white,
                            letterSpacing: 1.2,
                          ),
                        ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernTextField({
    required bool isDark,
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            color: isDark ? Colors.white54 : const Color(0xFF757575),
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1A1A1A)),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: const Color(0xFF00A9C1), size: 20),
            hintText: hint,
            hintStyle: TextStyle(
              color: isDark ? Colors.white.withValues(alpha: 0.2) : const Color(0xFF9E9E9E),
            ),
            filled: true,
            fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF5F5F5),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFE0E0E0),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFE0E0E0),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF00A9C1), width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1),
            ),
          ),
        ),
      ],
    );
  }
}
