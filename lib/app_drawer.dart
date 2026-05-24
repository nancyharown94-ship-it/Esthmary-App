import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuth;
import 'package:flutter/material.dart';
import 'package:flutter_application_1/profile_page.dart';
import 'package:flutter_application_1/settings_page.dart';
import 'package:flutter_application_1/help_support_page.dart';

class AppDrawer extends StatelessWidget {
  final String userType;

  const AppDrawer({super.key, required this.userType});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Drawer(
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
      child: Column(
        children: [
          // Drawer Header with Dynamic Data
          FutureBuilder<DocumentSnapshot?>(
            future: FirebaseAuth.instance.currentUser != null 
              ? FirebaseFirestore.instance
                  .collection('users')
                  .doc(FirebaseAuth.instance.currentUser!.uid)
                  .get()
              : Future.value(null),
            builder: (context, snapshot) {
              String displayName = "Loading...";
              String displayEmail = userType; 

              if (snapshot.connectionState == ConnectionState.done) {
                 if (FirebaseAuth.instance.currentUser == null) {
                    displayName = "Guest";
                 } else if (snapshot.hasData && snapshot.data != null && snapshot.data!.exists) {
                    final data = snapshot.data!.data() as Map<String, dynamic>;
                    displayName = data['fullName'] ?? "User Name";
                 } else if (FirebaseAuth.instance.currentUser?.displayName != null && 
                    FirebaseAuth.instance.currentUser!.displayName!.isNotEmpty) {
                    displayName = FirebaseAuth.instance.currentUser!.displayName!;
                 } else {
                    displayName = "User";
                 }
              }

              return Container(
                width: double.infinity,
                padding: const EdgeInsets.only(top: 60, bottom: 30, left: 24, right: 24),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFF00A9C1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(
                          color: isDark ? const Color(0xFF00A9C1) : Colors.white,
                          width: 3,
                        ),
                      ),
                      child: Icon(
                        Icons.person,
                        size: 40,
                        color: isDark ? const Color(0xFF00A9C1) : const Color(0xFF00A9C1),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      displayName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: isDark ? Colors.white : Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      displayEmail,
                      style: TextStyle(
                        color: isDark ? const Color(0xFF00A9C1) : Colors.white.withValues(alpha: 0.9),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 16),
          // Drawer Items
          _buildDrawerItem(
            context: context,
            icon: Icons.person_outline,
            title: 'Profile',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfilePage(userType: userType),
                ),
              );
            },
          ),
          _buildDrawerItem(
            context: context,
            icon: Icons.settings_outlined,
            title: 'Settings',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
          ),
          _buildDrawerItem(
            context: context,
            icon: Icons.help_outline,
            title: 'Help & Support',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const HelpSupportPage(),
                ),
              );
            },
          ),

          const Spacer(),

          // Logout Button
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text(
                'LOGOUT',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Colors.redAccent, width: 1.5),
              ),
              onTap: () async {
                // Navigate first to avoid permission errors on current page refreshing
                Navigator.of(context).pop(); // Close drawer
                Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                
                // Then sign out
                await FirebaseAuth.instance.signOut();
              },
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return ListTile(
      leading: Icon(
        icon,
        color: isDark ? const Color(0xFF00A9C1) : const Color(0xFF00A9C1),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDark ? Colors.white : const Color(0xFF1A1A1A),
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }
}
