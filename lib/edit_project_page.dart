import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class EditProjectPage extends StatefulWidget {
  final String projectId;

  const EditProjectPage({super.key, required this.projectId});

  @override
  State<EditProjectPage> createState() => _EditProjectPageState();
}

class _EditProjectPageState extends State<EditProjectPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  bool _isSaving = false;

  // Controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _targetAmountController = TextEditingController();
  final _locationController = TextEditingController();

  String? _selectedStage;
  final List<String> _stages = [
    'Idea',
    'Prototype',
    'MVP',
    'Growth',
    'Expansion'
  ];

  @override
  void initState() {
    super.initState();
    _loadProjectData();
  }

  Future<void> _loadProjectData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('projects')
          .doc(widget.projectId)
          .get();

      if (doc.exists && mounted) {
        final data = doc.data()!;
        setState(() {
          _titleController.text = data['title'] ?? '';
          _descriptionController.text = data['description'] ?? '';
          _targetAmountController.text = (data['targetAmount'] ?? 0).toString();
          _locationController.text = data['location'] ?? '';
          _selectedStage = data['projectStage'] ?? 'Idea';
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading project: $e");
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading project: $e')),
        );
      }
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      await FirebaseFirestore.instance
          .collection('projects')
          .doc(widget.projectId)
          .update({
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'targetAmount': double.parse(_targetAmountController.text.trim()),
        'location': _locationController.text.trim(),
        'projectStage': _selectedStage,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Project updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint("Error updating project: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _targetAmountController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text("Edit Project"),
        backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
        foregroundColor: isDark ? Colors.white : const Color(0xFF1A1A1A),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    _buildLabel("Project Title"),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _titleController,
                      decoration: _buildInputDecoration("Enter project title", isDark),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter project title';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Description
                    _buildLabel("Description"),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: _buildInputDecoration("Enter project description", isDark),
                      maxLines: 5,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter project description';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Target Amount
                    _buildLabel("Target Amount (EGP)"),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _targetAmountController,
                      decoration: _buildInputDecoration("Enter target amount", isDark),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter target amount';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Location
                    _buildLabel("Location"),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _locationController,
                      decoration: _buildInputDecoration("Enter location", isDark),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter location';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Project Stage
                    _buildLabel("Project Stage"),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedStage,
                      decoration: _buildInputDecoration("Select project stage", isDark),
                      items: _stages.map((stage) {
                        return DropdownMenuItem(
                          value: stage,
                          child: Text(stage),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedStage = value);
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select project stage';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 40),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveChanges,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00A9C1),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text(
                                "Save Changes",
                                style: TextStyle(fontSize: 18),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildLabel(String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: isDark ? Colors.white54 : const Color(0xFF757575),
        letterSpacing: 0.5,
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hint, bool isDark) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: isDark ? Colors.white24 : const Color(0xFF9E9E9E),
        fontSize: 14,
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
    );
  }
}
