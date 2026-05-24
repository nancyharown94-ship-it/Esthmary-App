import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:flutter_application_1/edit_profile_page.dart';
import 'package:flutter_application_1/offers_page.dart';
import 'package:flutter_application_1/settings_page.dart';

class ProfilePage extends StatefulWidget {
  final String userType;

  const ProfilePage({super.key, required this.userType});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // State variables for user profile data
  String _name = "Loading...";
  String _email = "";
  String _phone = "";
  String _location = "Cairo, Egypt"; // Default if not in DB
  String _about = "I am interested in projects..."; // Default if not in DB
  String _role = "";

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _role = widget.userType; // Initial fallback
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (doc.exists && mounted) {
          final data = doc.data() as Map<String, dynamic>;
          setState(() {
            _name = data['fullName'] ?? "User Name";
            _email = data['email'] ?? user.email ?? "";
            _phone = data['phone'] ?? "";
            _role = data['role'] ?? widget.userType;
            // Optional fields
            _location = data['location'] ?? "Cairo, Egypt";
            _about = data['about'] ?? "No bio available.";
            _isLoading = false;
          });
        }
      } catch (e) {
        debugPrint("Error fetching profile: $e");
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  // Navigate to Edit Profile Page and wait for result
  Future<void> _editProfile() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfilePage(
          currentName: _name,
          currentEmail: _email,
          currentPhone: _phone,
          currentLocation: _location,
          currentAbout: _about,
          currentRole: _role,
        ),
      ),
    );

    // If result is returned (user saved changes), update Firestore and state
    if (result != null && result is Map<String, String>) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          // Update Firestore
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .update({
            'fullName': result['name'],
            // 'email': result['email'], // Note: Changing email in Auth needs more steps usually
            'phone': result['phone'],
            'location': result['location'],
            'about': result['about'],
            'role': result['role'],
          });

          // Update Local State
          setState(() {
            _name = result['name']!;
            // _email = result['email']!;
            _phone = result['phone']!;
            _location = result['location']!;
            _about = result['about']!;
            _role = result['role']!;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Profile updated successfully!')),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to update profile: $e')),
            );
          }
        }
      }
    }
  }

  void _navigateToOffers() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to view offers.')),
      );
      return;
    }

    // Determine arguments based on role
    // Assuming role suggests which view to show. 
    // Owner -> Received Offers (by their ownerId)
    // Investor -> Sent Offers (by their investorId)
    
    // Normalize string just in case
    final role = _role.toLowerCase().trim();
    
    // If exact string matching is risky, we can check contain or simply try one first.
    // Based on SignUp: 'Owner' / 'Investor'
    final isOwner = role.contains('owner');
    
    if (isOwner) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const OffersPage(),
          settings: RouteSettings(
            arguments: {'ownerId': user.uid},
          ),
        ),
      );
    } else {
      // Default to Investor view
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const OffersPage(),
          settings: RouteSettings(
            arguments: {'investorId': user.uid},
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;


    if (_isLoading) {
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        body: Center(child: CircularProgressIndicator(color: isDark ? const Color(0xFF00A9C1) : const Color(0xFF00A9C1))),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF5F5F5),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // ========= AppBar =========
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, size: 26, color: textColor),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Text(
                    "Profile",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, size: 22, color: Color(0xFF00A9C1)),
                    onPressed: _editProfile,
                  ),
                ],
              ),

              const SizedBox(height: 25),

              // ========= Profile Picture =========
              CircleAvatar(
                radius: 55,
                backgroundColor: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0),
                child: Icon(Icons.person, size: 50, color: isDark ? const Color(0xFF00A9C1) : const Color(0xFF757575)),
              ),

              const SizedBox(height: 15),

              // ========= Name =========
              Text(
                _name,
                style: TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),

              const SizedBox(height: 5),

              // ========= User Type =========
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF00A9C1).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _role.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF00A9C1),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 25),

              // ========= Personal Info Card =========
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: isDark ? null : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Personal Information",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),

                    const SizedBox(height: 15),

                    _profileRow(Icons.email_outlined, _email, textColor, const Color(0xFF00A9C1)),
                    const SizedBox(height: 12),

                    _profileRow(Icons.phone_outlined, _phone, textColor, const Color(0xFF00A9C1)),
                    const SizedBox(height: 12),

                    _profileRow(Icons.location_on_outlined, _location, textColor, const Color(0xFF00A9C1)),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ========= About Me Card =========
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: isDark ? null : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "About Me",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      _about,
                      style: TextStyle(fontSize: 15, color: textColor),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ========= My Offers Button =========
              GestureDetector(
                onTap: _navigateToOffers,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 20,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: isDark ? null : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: _activityRow(Icons.local_offer_outlined, "My Offers", textColor, const Color(0xFF00A9C1)),
                ),
              ),

              const SizedBox(height: 20),

              // ========= Settings Button =========
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsPage(),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 20,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: isDark ? null : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: _activityRow(Icons.settings_outlined, "Settings", textColor, const Color(0xFF00A9C1)),
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _profileRow(IconData icon, String text, Color textColor, Color iconColor) {
    return Row(
      children: [
        Icon(icon, size: 22, color: iconColor),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: TextStyle(fontSize: 15, color: textColor))),
      ],
    );
  }

  Widget _activityRow(IconData icon, String text, Color textColor, Color iconColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 22, color: iconColor),
            const SizedBox(width: 12),
            Text(text, style: TextStyle(fontSize: 16, color: textColor)),
          ],
        ),
        Icon(Icons.arrow_forward_ios, size: 16, color: textColor.withValues(alpha: 0.5)),
      ],
    );
  }
}
