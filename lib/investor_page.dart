import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/app_drawer.dart';

// Data Model for Projects
class ProjectData {
  final String id;
  final String title;
  final String description; 
  final String sector;
  final String funding;
  final String imageUrl;
  final bool isFeatured; // logic to determine this (e.g. if raised > 50%)
  final double progress;

  ProjectData({
    required this.id,
    required this.title,
    this.description = '',
    required this.sector,
    required this.funding,
    required this.imageUrl,
    this.isFeatured = false,
    this.progress = 0.0,
  });

  factory ProjectData.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final double target = (data['targetAmount'] ?? 0).toDouble();
    final double raised = (data['raisedAmount'] ?? 0).toDouble();
    final double progress = target > 0 ? raised / target : 0.0;
    
    // Determine if featured (example logic: high priority or random, here just using a dummy rule or explicit field)
    // For now, let's say "Technology" projects are featured for demo, or add a field later.
    final bool featured = data['isFeatured'] ?? false; 

    return ProjectData(
      id: doc.id,
      title: data['title'] ?? 'Untitled',
      description: data['description'] ?? '',
      sector: data['category'] ?? 'Other',
      funding: '${target.toStringAsFixed(0)} EGP',
      imageUrl: data['imageUrl'] ?? 'images/splash_background.png', // Fallback
      isFeatured: featured, // You can change this logic
      progress: progress,
    );
  }
}

class InvestorHomePage extends StatefulWidget {
  const InvestorHomePage({super.key});

  @override
  State<InvestorHomePage> createState() => _InvestorHomePageState();
}

class _InvestorHomePageState extends State<InvestorHomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  // State for filtering
  String _searchQuery = '';
  String _selectedCategory = 'All';

  late Stream<List<ProjectData>> _projectsStream;

  @override
  void initState() {
    super.initState();
    _initStream();
  }

  void _initStream() {
    // Fetch only PENDING or APPROVED projects (exclude FUNDED)
    // NOTE: This requires a composite index in Firestore
    _projectsStream = FirebaseFirestore.instance
        .collection('projects')
        .where('status', whereIn: ['PENDING', 'APPROVED'])
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProjectData.fromFirestore(doc))
            .toList());
  }

  List<ProjectData> _filterProjects(List<ProjectData> allProjects) {
    return allProjects.where((project) {
      // 1. Filter by Category
      bool categoryMatches = _selectedCategory == 'All' || 
                             project.sector == _selectedCategory;
      
      // 2. Filter by Search Query
      bool searchMatches = project.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                           project.sector.toLowerCase().contains(_searchQuery.toLowerCase());

      return categoryMatches && searchMatches;
    }).toList();
  }

  AppBar _buildAppBar(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      elevation: 0,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF00A9C1),
            ),
            child: ClipOval(
              child: Image.asset(
                'images/ic_logo.png',
                fit: BoxFit.cover,
                errorBuilder: (c,o,s) => const Icon(Icons.business, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'Isthmary',
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF1A1A1A),
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: GestureDetector(
            onTap: () {
              _scaffoldKey.currentState?.openDrawer();
            },
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF00A9C1), width: 2),
              ),
              child: const CircleAvatar(
                radius: 18,
                backgroundColor: Colors.transparent,
                child: Icon(Icons.menu, color: Color(0xFF00A9C1), size: 24),
              ),
            ),
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(75.0),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 16.0),
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1A1A1A), fontSize: 15),
              decoration: InputDecoration(
                hintText: 'Search for projects...',
                hintStyle: TextStyle(color: isDark ? Colors.white24 : const Color(0xFF9E9E9E)),
                prefixIcon: const Icon(Icons.search, size: 22, color: Color(0xFF00A9C1)),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA),
      drawer: AppDrawer(userType: 'Investor'),
      appBar: _buildAppBar(context),
      body: StreamBuilder<List<ProjectData>>(
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
                          _initStream(); 
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

          final allData = snapshot.data ?? [];
          final filteredList = _filterProjects(allData);
          
          // For Featured, let's take items that have a flag or just the first 3 of the list for now
          final featuredMatches = filteredList.take(3).toList(); 
          final gridMatches = filteredList; // Show all in grid/list

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // 1. Category and Filter Tags
                _CategoryTags(
                  selectedCategory: _selectedCategory,
                  onCategorySelected: (category) {
                    setState(() {
                      if (_selectedCategory == category) {
                        _selectedCategory = 'All'; // Deselect
                      } else {
                        _selectedCategory = category;
                      }
                    });
                  },
                ),
                const SizedBox(height: 32),

                // 2. Featured Projects Section
                if (featuredMatches.isNotEmpty && _searchQuery.isEmpty && _selectedCategory == 'All') ...[
                  Text(
                    'Promising Investment',
                    style: TextStyle(
                      fontSize: 24, 
                      fontWeight: FontWeight.bold, 
                      color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _FeaturedProjectsCarousel(projects: featuredMatches),
                  const SizedBox(height: 40),
                ],

                // 3. Project Listings
                Text(
                  _searchQuery.isNotEmpty || _selectedCategory != 'All' ? 'Search Results' : 'Explore All Projects',
                  style: TextStyle(
                    fontSize: 24, 
                    fontWeight: FontWeight.bold, 
                    color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 16),
                
                if (gridMatches.isEmpty) 
                  const Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: Center(child: Text("No projects found matching your criteria.", style: TextStyle(color: Color(0xFF9E9E9E)))),
                  )
                else
                  _ProjectsGrid(projects: gridMatches),
              ],
            ),
          );
        }
      ),
    );
  }
}

class _CategoryTags extends StatelessWidget {
  final String selectedCategory;
  final Function(String) onCategorySelected;

  const _CategoryTags({
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Categories matching the Add Project dropdown
    final categories = [
      'Technology',
      'F&B', // Food & Beverage mapped in UI if needed, but saving as 'Food & Beverage'
      'Services',
      'Manufacturing',
      'Real Estate', // Wasn't in add project but good to have
      'Other'
    ];

    return Wrap(
      spacing: 12.0,
      runSpacing: 10.0,
      children: <Widget>[
        ActionChip(
          label: const Text(
            'All',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          avatar: const Icon(Icons.tune, color: Colors.white, size: 18),
          backgroundColor: const Color(0xFF00A9C1),
          onPressed: () => onCategorySelected('All'),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          side: BorderSide.none,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        ...categories.map(
          (label) {
            final displayLabel = label == 'F&B' ? 'Food & Beverage' : label;
            final isSelected = selectedCategory == displayLabel || (label == 'F&B' && selectedCategory == 'Food & Beverage');
            
            return FilterChip(
              label: Text(
                label, 
                style: TextStyle(
                  fontSize: 13,
                  color: isSelected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF757575)),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                )
              ),
              selected: isSelected,
              onSelected: (_) => onCategorySelected(label == 'F&B' ? 'Food & Beverage' : label),
              backgroundColor: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5),
              selectedColor: const Color(0xFF00A9C1),
              checkmarkColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              side: isSelected ? BorderSide.none : BorderSide(
                color: isDark ? Colors.white.withValues(alpha: 0.2) : const Color(0xFFE0E0E0),
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            );
          },
        ),
      ],
    );
  }
}

class _FeaturedProjectsCarousel extends StatelessWidget {
  final List<ProjectData> projects;
  const _FeaturedProjectsCarousel({required this.projects});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        spacing: 20.0,
        children: projects.map((project) => _FeaturedProjectCard(
          project: project,
        )).toList(),
      ),
    );
  }
}

class _FeaturedProjectCard extends StatelessWidget {
  final ProjectData project;

  const _FeaturedProjectCard({required this.project});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      elevation: 0,
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFE0E0E0),
          width: 1,
        ),
      ),
      child: Container(
        width: 300,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: project.imageUrl.startsWith('http') 
              ? Image.network(
                  project.imageUrl,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (c,o,s) => Container(color: const Color(0xFFF5F5F5), height: 160),
                )
              : Image.asset(
                  'images/splash_background.png',
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    project.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    project.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white54 : const Color(0xFF757575),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Target: ${project.funding}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF00A9C1),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00A9C1), Color(0xFF00BFA5)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(
                            context, 
                            '/project_details',
                            arguments: {
                              'projectId': project.id,
                              'userType': 'investor',
                            }
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text(
                          'View Details',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProjectsGrid extends StatelessWidget {
  final List<ProjectData> projects;
  const _ProjectsGrid({required this.projects});

  @override
  Widget build(BuildContext context) {
    // Using Column for a simple vertical list of full-width cards
    return Column(
      children: projects.map((project) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 15.0),
          child: _ProjectCard(
            project: project,
            cardWidth: double.infinity, // Full width
          ),
        );
      }).toList(),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  final ProjectData project;
  final double cardWidth;

  const _ProjectCard({
    required this.project,
    required this.cardWidth,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      elevation: 0,
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFE0E0E0),
          width: 1,
        ),
      ),
      child: Container(
        width: cardWidth,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: project.imageUrl.startsWith('http')
                  ? Image.network(
                      project.imageUrl,
                      height: 130,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (c, o, s) => Container(color: const Color(0xFFF5F5F5), height: 130),
                    )
                  : Image.asset(
                      'images/splash_background.png',
                      height: 130,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          project.title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (project.sector.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00A9C1).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF00A9C1)),
                          ),
                          child: Text(
                            project.sector,
                            style: const TextStyle(
                              fontSize: 10, 
                              color: Color(0xFF00A9C1), 
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Target: ${project.funding}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF00A9C1),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: project.progress,
                      minHeight: 6,
                      backgroundColor: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF5F5F5),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF00A9C1),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Details Button
                  SizedBox(
                    width: double.infinity,
                    height: 40,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pushNamed(
                          context, 
                          '/project_details',
                          arguments: {
                            'projectId': project.id,
                            'userType': 'investor',
                          }
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF00A9C1),
                        side: const BorderSide(color: Color(0xFF00A9C1), width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('View Details', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
  
