import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/add_project_page.dart';
import 'package:flutter_application_1/app_drawer.dart';

// 1. Data Model for Owner's Projects
class MyProject {
  final String id;
  final String title;
  final String category;
  final String target;
  final String raised;
  final String status;
  final Color statusColor;
  final double progress; // 0.0 to 1.0

  MyProject({
    required this.id,
    required this.title,
    required this.category,
    required this.target,
    required this.raised,
    required this.status,
    required this.statusColor,
    required this.progress,
  });

  factory MyProject.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final double targetAmount = (data['targetAmount'] ?? 0).toDouble();
    final double raisedAmount = (data['raisedAmount'] ?? 0).toDouble();
    final String status = data['status'] ?? 'PENDING';

    Color getColor(String status) {
      switch (status.toUpperCase()) {
        case 'APPROVED':
        case 'FUNDED':
          return const Color(0xFF2ECC71); // Green
        case 'REJECTED':
          return const Color(0xFFE74C3C); // Red
        case 'PENDING':
        default:
          return const Color(0xFFF1C40F); // Yellow
      }
    }

    return MyProject(
      id: doc.id,
      title: data['title'] ?? 'Untitled',
      category: data['category'] ?? 'General',
      target: '${targetAmount.toStringAsFixed(0)} EGP',
      raised: '${raisedAmount.toStringAsFixed(0)} EGP',
      status: status,
      statusColor: getColor(status),
      progress: targetAmount > 0 ? (raisedAmount / targetAmount) : 0.0,
    );
  }
}

class OwnerHomePage extends StatefulWidget {
  const OwnerHomePage({super.key});

  @override
  State<OwnerHomePage> createState() => _OwnerHomePageState();
}

class _OwnerHomePageState extends State<OwnerHomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // State for search and filter
  String _searchQuery = '';
  String _selectedStatusFilter = 'All'; // 'All', 'PENDING', 'FUNDED', 'REJECTED'
  final TextEditingController _searchController = TextEditingController();

  late Stream<List<MyProject>> _projectsStream;

  @override
  void initState() {
    super.initState();
    _initProjectsStream();
  }

  void _initProjectsStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _projectsStream = FirebaseFirestore.instance
          .collection('projects')
          .where('owner_id', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => MyProject.fromFirestore(doc))
              .toList());
    } else {
      _projectsStream = Stream.value([]);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Filter Logic
  List<MyProject> _filterProjects(List<MyProject> projects) {
    return projects.where((project) {
      // 1. Search Filter
      final matchesSearch =
          project.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          project.category.toLowerCase().contains(_searchQuery.toLowerCase());

      // 2. Status Filter
      final matchesStatus =
          _selectedStatusFilter == 'All' ||
          project.status.toUpperCase() == _selectedStatusFilter.toUpperCase();

      return matchesSearch && matchesStatus;
    }).toList();
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Filter Projects by Status",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 12.0,
                    children: ['All', 'PENDING', 'FUNDED'].map((status) {
                      final isSelected = _selectedStatusFilter == status;
                      return ChoiceChip(
                        label: Text(status),
                        selected: isSelected,
                        selectedColor: const Color(0xFF00796B),
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.black,
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedStatusFilter = status;
                            });
                            // setModalState(() {}); // Not strictly needed if setState rebuilds parent, but good for local content updates waiting
                            Navigator.pop(context);
                          }
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;


    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      drawer: const AppDrawer(userType: 'Owner'),
      body: StreamBuilder<List<MyProject>>(
        stream: _projectsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF00A9C1)));
          }

          if (snapshot.hasError) {
             final isPermError = '${snapshot.error}'.contains('permission-denied');
             return Center(
               child: Column(
                 mainAxisAlignment: MainAxisAlignment.center,
                 children: [
                   Icon(
                     isPermError ? Icons.lock_outline : Icons.error_outline,
                     color: Colors.redAccent,
                     size: 48,
                   ),
                   const SizedBox(height: 16),
                   Text(
                     'Unable to load projects',
                     style: TextStyle(
                       color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                       fontSize: 18,
                       fontWeight: FontWeight.bold,
                     ),
                   ),
                   const SizedBox(height: 8),
                   Padding(
                     padding: const EdgeInsets.symmetric(horizontal: 32),
                     child: Text(
                       isPermError 
                           ? 'Access Denied. Please ensure your account is authenticated and Firestore rules are deployed.' 
                           : 'Error: ${snapshot.error}',
                       textAlign: TextAlign.center,
                       style: TextStyle(
                         color: isDark ? Colors.white70 : const Color(0xFF757575),
                         fontSize: 14,
                       ),
                     ),
                   ),
                   const SizedBox(height: 24),
                   ElevatedButton.icon(
                     onPressed: () {
                        setState(() {
                          _initProjectsStream(); 
                        });
                     },
                     icon: const Icon(Icons.refresh),
                     label: const Text('Retry'),
                     style: ElevatedButton.styleFrom(
                       backgroundColor: const Color(0xFF00A9C1),
                       foregroundColor: Colors.white,
                     ),
                   )
                 ],
               ),
             );
          }

          final allProjects = snapshot.data ?? [];
          final filteredList = _filterProjects(allProjects);

          return Column(
            children: [
              // APP BAR CUSTOM
              Container(
                padding: const EdgeInsets.only(
                  top: 60,
                  left: 20,
                  right: 20,
                  bottom: 30,
                ),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(24),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 35,
                              height: 35,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF00A9C1),
                              ),
                              child: ClipOval(
                                child: Image.asset(
                                  'images/ic_logo.png',
                                  fit: BoxFit.cover,
                                  errorBuilder: (c, o, s) => const Icon(
                                    Icons.business,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Isthmary',
                              style: TextStyle(
                                color: Color(0xFF00A9C1),
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'My Projects',
                          style: TextStyle(
                            color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () {
                        _scaffoldKey.currentState?.openDrawer();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF00A9C1), width: 2),
                      ),
                      child: const CircleAvatar(
                        backgroundColor: Colors.transparent,
                        child: Icon(Icons.menu, color: Color(0xFF00A9C1)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Rest of the page
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 24,
                  ),
                  child: Column(
                    children: [
                      // Summary based on ALL projects (not filtered)
                      _buildSummaryCard(context, const Color(0xFF46EABB), allProjects),
                      const SizedBox(height: 24),
                      _buildAddProjectButton(context),
                      const SizedBox(height: 32),

                      // Search & Filter Row
                      if (allProjects.isNotEmpty) 
                        _buildSearchAndFilterRow(context),

                      // Active Filter Indicator
                      if (_selectedStatusFilter != 'All' && allProjects.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                          child: Row(
                            children: [
                              Text(
                                'Filtering by: $_selectedStatusFilter',
                                style: TextStyle(
                                  color: primaryColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedStatusFilter = 'All';
                                  });
                                },
                                child: Icon(
                                  Icons.close,
                                  size: 16,
                                  color: primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 16),

                      // Dynamic List View
                      if (allProjects.isEmpty)
                         _buildEmptyState(isDark)
                      else if (filteredList.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 20.0),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.search_off,
                                  size: 40,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'No projects match your filter',
                                  style: TextStyle(
                                    color: isDark ? Colors.white54 : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ...filteredList.map(
                          (project) => Column(
                            children: [
                              _buildProjectCard(
                                context: context,
                                project: project,
                              ),
                              const SizedBox(height: 12),
                            ],
                          ),
                        ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
         mainAxisAlignment: MainAxisAlignment.center,
         children: [
             Icon(
               Icons.folder_open_outlined,
               size: 100,
               color: isDark ? Colors.white24 : Colors.grey[300],
             ),
             const SizedBox(height: 20),
             Text(
               'No Projects Yet',
               style: TextStyle(
                 fontSize: 18,
                 fontWeight: FontWeight.bold,
                 color: isDark ? Colors.white70 : Colors.black54,
               ),
             ),
             const SizedBox(height: 8),
             Text(
               'Add your first project to get started!',
               style: TextStyle(
                 fontSize: 14, 
                 color: isDark ? Colors.white38 : Colors.black38
               ),
             ),
         ],
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    Color primaryColor,
    List<MyProject> projects,
  ) {
    final total = projects.length.toString();
    final approved = projects
        .where((p) => p.status == 'FUNDED' || p.status == 'APPROVED')
        .length
        .toString();
    final pending = projects
        .where((p) => p.status == 'PENDING')
        .length
        .toString();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFE0E0E0),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _summaryItem(context, 'Total', total, primaryColor),
          _summaryItem(context, 'Approved', approved, primaryColor),
          _summaryItem(context, 'Pending', pending, primaryColor),
        ],
      ),
    );
  }

  Widget _summaryItem(
    BuildContext context,
    String label,
    String value,
    Color primaryColor,
  ) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF757575),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            color: primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildAddProjectButton(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 55,
      decoration: BoxDecoration(
        color: const Color(0xFF00A9C1),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00A9C1).withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddProjectPage()),
          );
        },
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          "Add New Project",
          style: TextStyle(
            fontSize: 16, 
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchAndFilterRow(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      height: 55,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFE0E0E0),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          const Icon(
            Icons.search_rounded,
            color: Color(0xFF00A9C1),
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _searchController,
              textAlignVertical: TextAlignVertical.center,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              cursorColor: const Color(0xFF00A9C1),
              decoration: InputDecoration(
                filled: false,
                hintText: 'Search projects...',
                hintStyle: TextStyle(
                  color: isDark ? Colors.white38 : const Color(0xFF9E9E9E),
                  fontSize: 14,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (_searchQuery.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear_rounded, size: 20),
              color: isDark ? Colors.white54 : const Color(0xFF757575),
              splashRadius: 20,
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                });
              },
            ),
          // Filter Button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _showFilterSheet,
              borderRadius: const BorderRadius.horizontal(
                right: Radius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Icon(
                  Icons.tune_rounded,
                  color: _selectedStatusFilter != 'All'
                      ? const Color(0xFF00A9C1)
                      : const Color(0xFF9E9E9E),
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectCard({
    required BuildContext context,
    required MyProject project,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final secondaryTextColor = isDark ? Colors.white54 : const Color(0xFF757575);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFE0E0E0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // title + badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  project.title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: project.statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: project.statusColor),
                ),
                child: Text(
                  project.status,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: project.statusColor,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            project.category,
            style: TextStyle(
              fontSize: 13,
              color: secondaryTextColor,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TARGET AMOUNT',
                      style: TextStyle(
                        fontSize: 10,
                        color: secondaryTextColor.withValues(alpha: 0.6),
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      project.target,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'RAISED AMOUNT',
                      style: TextStyle(
                        fontSize: 10,
                        color: secondaryTextColor.withValues(alpha: 0.6),
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      project.raised,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF00A9C1),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: project.progress,
              minHeight: 6,
              backgroundColor: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF5F5F5),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF00A9C1),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/project_details',
                  arguments: {
                    'projectId': project.id,
                    'userType': 'owner',
                    'status': project.status,
                    'title': project.title,
                  },
                );
              },
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF00A9C1),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('View Details', style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward_ios, size: 14),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
