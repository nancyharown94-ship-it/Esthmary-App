import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddProjectPage extends StatefulWidget {
  const AddProjectPage({super.key});

  @override
  State<AddProjectPage> createState() => _AddProjectPageState();
}

class _AddProjectPageState extends State<AddProjectPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _targetController = TextEditingController();
  final _equityController = TextEditingController(); // Renamed from duration
  final _locationController = TextEditingController();

  // Dropdown Values
  String? _selectedCategory;
  String? _selectedStage; // Renamed from risk

  // File Upload State
  PlatformFile? _pickedImage;
  PlatformFile? _pickedPdf;
  bool _imageError = false;
  bool _pdfError = false;

  Future<void> _pickImage() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true, // Required for Web
      );

      if (result != null) {
        setState(() {
          _pickedImage = result.files.single;
          _imageError = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  Future<void> _pickPdf() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true, // Required for Web
      );

      if (result != null) {
        setState(() {
          _pickedPdf = result.files.single;
          _pdfError = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking PDF: $e')),
      );
    }
  }

  Future<String> _uploadFile(PlatformFile file, String folder) async {
    try {
      final bytes = file.bytes;
      // Sanitize filename: remove spaces and special chars, keep extension
      final nameWithoutExt = file.name.split('.').first.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
      final ext = file.name.split('.').last;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_$nameWithoutExt.$ext';
      final filePath = '$folder/$fileName';

      if (bytes != null) {
        // For Web (primary) or if bytes are loaded
        await Supabase.instance.client.storage
            .from('projects')
            .uploadBinary(
              filePath,
              bytes,
              fileOptions: const FileOptions(upsert: true),
            );
      } else {
        // For Mobile/Desktop (fallback to path)
        final path = file.path;
        if (path == null) throw Exception('File path is null');
        
        final fileParams = File(path);
        await Supabase.instance.client.storage
            .from('projects')
            .upload(
              filePath,
              fileParams,
              fileOptions: const FileOptions(upsert: true),
            );
      }

      // Get the public URL
      final publicUrl = Supabase.instance.client.storage
          .from('projects')
          .getPublicUrl(filePath);
      
      return publicUrl;
    } catch (e) {
      debugPrint('Upload Error: $e');
      throw Exception('Upload failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
      appBar: AppBar(
        title: const Text(
          'LIST NEW PROJECT',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        foregroundColor: isDark ? Colors.white : const Color(0xFF1A1A1A),
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ================== 1. Project Details Section ==================
              _buildSectionHeader('Project Details', isDark ? Colors.white : const Color(0xFF1A1A1A)),
              const SizedBox(height: 16),
              _buildModernTextField(
                isDark: isDark,
                label: 'Project Title',
                hint: 'e.g. Smart Agriculture Platform',
                controller: _nameController,
                icon: Icons.title,
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 20),
              _buildModernTextField(
                isDark: isDark,
                label: 'Short Description',
                hint: 'Brief overview of the project idea...',
                controller: _descriptionController,
                icon: Icons.description_outlined,
                maxLines: 4,
                validator: (val) => val == null || val.length < 20
                    ? 'Min 20 characters required'
                    : null,
              ),
              const SizedBox(height: 32),

              // ================== 2. Investment Details Section ==================
              _buildSectionHeader('Investment Details', isDark ? Colors.white : const Color(0xFF1A1A1A)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildModernTextField(
                      isDark: isDark,
                      label: 'Target (EGP)',
                      hint: 'e.g. 50,000',
                      controller: _targetController,
                      icon: Icons.account_balance_wallet_outlined,
                      keyboardType: TextInputType.number,
                      validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildModernTextField(
                      isDark: isDark,
                      label: 'Equity (%)',
                      hint: 'e.g. 10%',
                      controller: _equityController,
                      icon: Icons.pie_chart_outline,
                      validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // ================== 3. Category & Stage Section ==================
              _buildSectionHeader('Category & Stage', isDark ? Colors.white : const Color(0xFF1A1A1A)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildModernDropdown(
                      isDark: isDark,
                      label: 'Category',
                      hint: 'Select',
                      value: _selectedCategory,
                      items: const [
                        'Technology',
                        'Food & Beverage',
                        'Services',
                        'Manufacturing',
                        'Other',
                      ],
                      onChanged: (val) => setState(() => _selectedCategory = val),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildModernDropdown(
                      isDark: isDark,
                      label: 'Project Stage',
                      hint: 'Select stage',
                      value: _selectedStage,
                      items: const ['Idea Phase', 'Prototype', 'MVP', 'Growth', 'Expansion'],
                      onChanged: (val) => setState(() => _selectedStage = val),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // ================== 4. Location Section ==================
              _buildSectionHeader('Location', isDark ? Colors.white : const Color(0xFF1A1A1A)),
              const SizedBox(height: 16),
              _buildModernTextField(
                isDark: isDark,
                label: 'City / Country',
                hint: 'e.g. Cairo, Egypt',
                controller: _locationController,
                icon: Icons.location_on_outlined,
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 32),

              // ================== 5. File Uploads Section ==================
              _buildSectionHeader('Project Files', isDark ? Colors.white : const Color(0xFF1A1A1A)),
              const SizedBox(height: 16),
              
              _buildUploadArea(
                isDark: isDark,
                title: 'Project Cover Image',
                subtitle: 'PNG, JPG expected',
                icon: Icons.image_outlined,
                fileName: _pickedImage?.name,
                hasError: _imageError,
                onTap: _pickImage,
              ),
              const SizedBox(height: 16),
              
              _buildUploadArea(
                isDark: isDark,
                title: 'Business Plan (PDF)',
                subtitle: 'Required Pitch Deck',
                icon: Icons.picture_as_pdf_outlined,
                fileName: _pickedPdf?.name,
                hasError: _pdfError,
                onTap: _pickPdf,
              ),

              const SizedBox(height: 48),

              // ================== Submit Button ==================
              SizedBox(
                width: double.infinity,
                height: 55,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00A9C1), Color(0xFF00BFA5)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00A9C1).withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: Text(
                      'LIST PROJECT',
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

  void _submitForm() async {
    setState(() {
      _imageError = _pickedImage == null;
      _pdfError = _pickedPdf == null;
    });

    if (_formKey.currentState!.validate() && !_imageError && !_pdfError) {
      // 1. Show Loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
           Navigator.pop(context); // close loading
           if (!mounted) return;
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('You must be logged in to add a project')),
           );
           return;
        }

        // 2. Upload Files to Supabase
        String? imageUrl;
        String? pdfUrl;

        // Upload Image
        if (_pickedImage != null) {
           imageUrl = await _uploadFile(_pickedImage!, 'images');
        }

        // Upload PDF
        if (_pickedPdf != null) {
           pdfUrl = await _uploadFile(_pickedPdf!, 'pdfs');
        }

        // 3. Prepare Data
        final projectData = {
          'title': _nameController.text.trim(),
          'description': _descriptionController.text.trim(),
          'targetAmount': double.tryParse(_targetController.text.replaceAll(',', '')) ?? 0.0,
          'equity': _equityController.text.trim(), // Renamed from duration
          'category': _selectedCategory,
          'projectStage': _selectedStage, // Renamed from riskLevel
          'location': _locationController.text.trim(),
          'owner_id': user.uid,
          'createdAt': FieldValue.serverTimestamp(),
          'status': 'PENDING',
          'imageUrl': imageUrl,
          'pdfUrl': pdfUrl,
          'raisedAmount': 0.0,
        };

        // 4. Save to Firestore
        await FirebaseFirestore.instance.collection('projects').add(projectData);

        if (!mounted) return;

        // 5. Close loading and show success
        Navigator.pop(context); // close loading

        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Project Submitted'),
            content: const Text('Your project has been sent for review successfully.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // close dialog
                  Navigator.pop(context); // back to home
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } catch (e) {
        Navigator.pop(context); // close loading
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving project: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields and upload files.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: color,
        letterSpacing: 1.1,
      ),
    );
  }

  Widget _buildModernTextField({
    required bool isDark,
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.white54 : const Color(0xFF757575),
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
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
              color: isDark ? Colors.white24 : const Color(0xFF9E9E9E),
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

  Widget _buildModernDropdown({
    required bool isDark,
    required String label,
    required String hint,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.white54 : const Color(0xFF757575),
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: value,
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: onChanged,
          validator: (val) => val == null ? 'Required' : null,
          dropdownColor: isDark ? const Color(0xFF2A2A2A) : Colors.white,
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF1A1A1A),
            fontSize: 14,
          ),
          icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF00A9C1)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: isDark ? Colors.white24 : const Color(0xFF9E9E9E),
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
          ),
        ),
      ],
    );
  }

  Widget _buildUploadArea({
    required bool isDark,
    required String title,
    required String subtitle,
    required IconData icon,
    required String? fileName,
    required bool hasError,
    required VoidCallback onTap,
  }) {
    final accentColor = const Color(0xFF00A9C1);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: hasError 
                ? Colors.redAccent 
                : (fileName != null ? accentColor : (isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFE0E0E0))),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (fileName != null ? accentColor : (isDark ? Colors.white : Colors.black)).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                fileName != null ? Icons.check_circle : icon,
                color: fileName != null ? accentColor : (isDark ? Colors.white54 : const Color(0xFF757575)),
                size: 24,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fileName ?? title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: fileName != null ? accentColor : (isDark ? Colors.white : const Color(0xFF1A1A1A)),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    fileName != null ? 'File selected successfully' : subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white38 : const Color(0xFF757575),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.upload_outlined, color: accentColor, size: 24),
          ],
        ),
      ),
    );
  }
}
