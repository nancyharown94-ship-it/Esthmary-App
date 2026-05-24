import 'package:flutter/material.dart';

class EditProfilePage extends StatefulWidget {
  final String currentName;
  final String currentEmail;
  final String currentPhone;
  final String currentLocation;
  final String currentAbout;
  final String currentRole;

  const EditProfilePage({
    super.key,
    required this.currentName,
    required this.currentEmail,
    required this.currentPhone,
    required this.currentLocation,
    required this.currentAbout,
    required this.currentRole,
  });

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _locationController;
  late TextEditingController _aboutController;
  late String _selectedRole;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentName);
    _emailController = TextEditingController(text: widget.currentEmail);
    _phoneController = TextEditingController(text: widget.currentPhone);
    _locationController = TextEditingController(text: widget.currentLocation);
    _aboutController = TextEditingController(text: widget.currentAbout);
    _selectedRole = widget.currentRole.toLowerCase();
    
    // Validate role fallback
    if (_selectedRole != 'investor' && _selectedRole != 'owner') {
       _selectedRole = 'investor'; 
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _aboutController.dispose();
    super.dispose();
  }

  void _saveProfile() {
    if (_formKey.currentState!.validate()) {
      // Return the updated data as a Map
      final updatedData = {
        'name': _nameController.text.trim(),
        // 'email': _emailController.text.trim(), // Email is not editable
        'phone': _phoneController.text.trim(),
        'location': _locationController.text.trim(),
        'about': _aboutController.text.trim(),
        'role': _selectedRole,
      };
      Navigator.pop(context, updatedData);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final backgroundColor = isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF5F5F5);
    final cardColor = isDark ? const Color(0xFF2A2A2A) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final hintColor = isDark ? Colors.white54 : Colors.grey[600];
    final primaryColor = const Color(0xFF00A9C1);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          "Edit Profile",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        centerTitle: true,
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.check, color: primaryColor),
            onPressed: _saveProfile,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Header
              Center(
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: isDark ? const Color(0xFF333333) : Colors.grey[300],
                  child: Icon(Icons.person, size: 50, color: primaryColor),
                ),
              ),
              
              const SizedBox(height: 30),
              
              Text(
                "BASIC INFORMATION",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: hintColor,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 15),

              // Name Field
              _buildModernTextField(
                controller: _nameController,
                label: 'Full Name',
                icon: Icons.person_outline,
                isDark: isDark,
                primaryColor: primaryColor,
              ),
              const SizedBox(height: 16),

              // Role Dropdown
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF333333) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                     if (!isDark)
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: DropdownButtonFormField<String>(
                  value: _selectedRole,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    prefixIcon: Icon(Icons.badge_outlined, color: Color(0xFF00A9C1)),
                    labelText: 'User Type',
                    labelStyle: TextStyle(color: Colors.grey),
                  ),
                  dropdownColor: isDark ? const Color(0xFF333333) : Colors.white,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontFamily: 'Roboto', // Or your default font
                  ),
                  items: const [
                    DropdownMenuItem(value: 'investor', child: Text('Investor')),
                    DropdownMenuItem(value: 'owner', child: Text('Project Owner')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedRole = value;
                      });
                    }
                  },
                ),
              ),
              
              const SizedBox(height: 30),
              
              Text(
                "CONTACT DETAILS",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: hintColor,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 15),

              // Phone Field
              _buildModernTextField(
                controller: _phoneController,
                label: 'Phone Number',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                isDark: isDark,
                primaryColor: primaryColor,
              ),
              const SizedBox(height: 16),
              
              // Location Field
              _buildModernTextField(
                controller: _locationController,
                label: 'Location',
                icon: Icons.location_on_outlined,
                isDark: isDark,
                primaryColor: primaryColor,
              ),
              
              const SizedBox(height: 30),
              
              Text(
                "ABOUT ME",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: hintColor,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 15),

              // About Field
              _buildModernTextField(
                controller: _aboutController,
                label: 'Bio',
                icon: Icons.info_outline,
                maxLines: 4,
                isDark: isDark,
                primaryColor: primaryColor,
              ),

              const SizedBox(height: 40),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Save Changes',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDark,
    required Color primaryColor,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF333333) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: TextStyle(color: isDark ? Colors.white : Colors.black87),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: isDark ? Colors.white54 : Colors.grey),
          prefixIcon: Icon(icon, color: primaryColor),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: primaryColor, width: 1.5),
          ),
          enabledBorder:  OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          errorBorder: OutlineInputBorder(
             borderRadius: BorderRadius.circular(16),
             borderSide: const BorderSide(color: Colors.redAccent),
          ),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Please enter $label';
          }
          return null;
        },
      ),
    );
  }
}
