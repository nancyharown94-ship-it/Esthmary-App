import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/invest_page.dart';
import 'package:url_launcher/url_launcher.dart';

class ProjectDetailsPage extends StatefulWidget {
  const ProjectDetailsPage({super.key});

  @override
  State<ProjectDetailsPage> createState() => _ProjectDetailsPageState();
}

class _ProjectDetailsPageState extends State<ProjectDetailsPage> {
  Map<String, dynamic>? _ownerData;
  bool _isOwnerFetching = false;

  Future<void> _fetchOwnerDetails(String ownerId) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(ownerId)
          .get();
      if (userDoc.exists && mounted) {
        setState(() {
          _ownerData = userDoc.data();
        });
      }
    } catch (e) {
      debugPrint("Error fetching owner: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final String userType = args?['userType'] ?? 'investor';
    final String? projectId = args?['projectId'];

    if (projectId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Error")),
        body: const Center(child: Text("Project ID missing")),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
      appBar: AppBar(
        title: const Text(
          "Project Details",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        foregroundColor: isDark ? Colors.white : const Color(0xFF1A1A1A),
        centerTitle: true,
        elevation: 0,
        actions: [
          if (userType == 'owner')
            IconButton(
              icon: const Icon(Icons.edit_note_rounded, size: 28),
              tooltip: 'Edit Project',
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/edit_project',
                  arguments: {'projectId': projectId},
                );
              },
            ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('projects')
            .doc(projectId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.white70)));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: isDark ? const Color(0xFF00A9C1) : const Color(0xFF00A9C1)));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text("Project not found", style: TextStyle(color: isDark ? Colors.white70 : const Color(0xFF757575))));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          // Fetch Owner Data if missing
          final String ownerId = data['owner_id'] ?? data['ownerId'] ?? '';
          if (_ownerData == null && ownerId.isNotEmpty && !_isOwnerFetching) {
            _isOwnerFetching = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _fetchOwnerDetails(ownerId);
            });
          }

          final String title = data['title'] ?? 'Untitled Project';
          final String description = data['description'] ?? 'No description provided.';
          final String? imageUrl = data['imageUrl'];
          final String? pdfUrl = data['pdfUrl'];
          final double target = (data['targetAmount'] ?? 0).toDouble();
          final double raised = (data['raisedAmount'] ?? 0).toDouble();
          final String status = data['status'] ?? 'PENDING';
          final String ownerName = _ownerData?['fullName'] ?? 'Unknown Owner';
          final String location = data['location'] ?? 'Unknown Location';
          final String stage = data['projectStage'] ?? 'Unknown Stage';
          
          final isOwner = userType == 'owner';
          final isOwnerPending = isOwner && status == 'PENDING';

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Project Image with Premium Frame
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFE0E0E0),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: imageUrl != null && imageUrl.isNotEmpty
                        ? Image.network(
                            imageUrl,
                            height: 250,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (c, o, s) => Container(
                              height: 250,
                              width: double.infinity,
                              color: const Color(0xFF010A12),
                              child: const Icon(Icons.broken_image, size: 50, color: Colors.white24),
                            ),
                          )
                        : Image.asset(
                            'images/splash_background.png',
                            height: 250,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                  ),
                ),
                const SizedBox(height: 24),
                
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 12),
                
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _buildBadge(status, _getStatusColor(status), isDark),
                    if (stage.isNotEmpty) _buildBadge(stage, const Color(0xFF00A9C1), isDark),
                    if (location.isNotEmpty) _buildBadge(location, isDark ? Colors.white60 : const Color(0xFF757575), isDark, icon: Icons.location_on_outlined),
                  ],
                ),
                const SizedBox(height: 32),
                
                // Owner Info Row
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFE0E0E0),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF00A9C1), width: 2),
                        ),
                        child: CircleAvatar(
                          backgroundColor: Colors.transparent,
                          child: Text(
                            ownerName.isNotEmpty ? ownerName[0].toUpperCase() : 'U',
                            style: const TextStyle(color: Color(0xFF00A9C1), fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ownerName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                            ),
                          ),
                          Text(
                            isOwner ? "Project Founder (You)" : "Project Founder",
                            style: TextStyle(color: isDark ? Colors.white54 : const Color(0xFF757575), fontSize: 13),
                          ),
                        ],
                      ),
                      const Spacer(),
                      if (status == 'APPROVED' || status == 'FUNDED')
                        const Icon(Icons.verified_rounded, color: Color(0xFF00A9C1), size: 28),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                if (isOwnerPending) ...[
                  _buildOffersSection(context, true, Colors.white),
                ] else ...[
                  Row(
                    children: [
                      Expanded(
                        child: InfoCard(
                          title: "Target Goal",
                          value: "${target.toStringAsFixed(0)} EGP",
                          icon: Icons.track_changes_rounded,
                          color: const Color(0xFF00A9C1),
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: InfoCard(
                          title: "Amount Raised",
                          value: "${raised.toStringAsFixed(0)} EGP",
                          icon: Icons.payments_outlined,
                          color: const Color(0xFF00BFA5),
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  const Text(
                    "About the Project",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.6,
                      color: isDark ? Colors.white70 : const Color(0xFF757575),
                    ),
                  ),
                  const SizedBox(height: 40),
                  
                  if (pdfUrl != null && pdfUrl.isNotEmpty)
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final uri = Uri.parse(pdfUrl);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                          } else {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Could not launch PDF')),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.picture_as_pdf_outlined),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF00A9C1),
                          side: const BorderSide(color: Color(0xFF00A9C1), width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        label: const Text(
                          "Download Pitch Deck",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  
                  const SizedBox(height: 20),
                  
                  if (!isOwner)
                    SizedBox(
                      width: double.infinity,
                      child: Container(
                        height: 55,
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
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => InvestPage(
                                  projectId: args?['projectId'],
                                  projectTitle: title,
                                  ownerId: ownerId,
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            "INVEST NOW",
                            style: TextStyle(
                              fontSize: 16, 
                              color: isDark ? const Color(0xFF010A12) : Colors.white, 
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBadge(String text, Color color, bool isDark, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'APPROVED':
      case 'FUNDED':
        return const Color(0xFF2ECC71);
      case 'REJECTED':
        return const Color(0xFFE74C3C);
      case 'PENDING':
      default:
        return const Color(0xFFF1C40F);
    }
  }

  Widget _buildOffersSection(
      BuildContext context, bool isDark, Color textColor) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final String? projectId = args?['projectId'];
    
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('proposals')
          .where('projectId', isEqualTo: projectId)
          .where('status', isEqualTo: 'PENDING')
          .snapshots(),
      builder: (context, snapshot) {
        final offersCount = snapshot.hasData ? snapshot.data!.docs.length : 0;
        
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              const Icon(Icons.assignment_ind_rounded,
                  size: 48, color: Color(0xFF46EABB)),
              const SizedBox(height: 16),
              Text(
                "Current Offers",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white70 : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Check Proposals",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF46EABB),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "$offersCount Active Proposals",
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white54 : Colors.grey[500],
                ),
              ),
              const SizedBox(height: 24),
              if (offersCount > 0) ...[
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF46EABB), Color(0xFF00BFA5)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(
                          context, 
                          '/offers',
                          arguments: {'projectId': projectId}
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: const Color(0xFF010A12),
                      ),
                      child: const Text("View All Offers", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              ] else ...[
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: () => _deleteProject(context, projectId),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text("Remove Project"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      }
    );
  }

  Future<void> _deleteProject(BuildContext context, String? projectId) async {
    if (projectId == null) return;

    // Save context references before async operations
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF010A12),
        title: const Text('Delete Project', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to delete this project?\n\nThis action cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // Check again if there are any offers
      final offersSnapshot = await FirebaseFirestore.instance
          .collection('proposals')
          .where('projectId', isEqualTo: projectId)
          .where('status', isEqualTo: 'PENDING')
          .get();

      if (offersSnapshot.docs.isNotEmpty) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Cannot delete project with pending offers'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      // Delete the project
      await FirebaseFirestore.instance
          .collection('projects')
          .doc(projectId)
          .delete();

      // Show success message
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Project deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate back to owner home
      navigator.pushNamedAndRemoveUntil('/owner', (route) => false);

    } catch (e) {
      debugPrint("Error deleting project: $e");
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }
}

class InfoCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final bool isDark;

  const InfoCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: color.withValues(alpha: 0.1),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 17,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: isDark ? Colors.white70 : const Color(0xFF757575),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
