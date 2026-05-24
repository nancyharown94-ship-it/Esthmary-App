
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';


class OffersPage extends StatefulWidget {
  const OffersPage({super.key});

  @override
  State<OffersPage> createState() => _OffersPageState();
}

class _OffersPageState extends State<OffersPage> {
  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final String? projectId = args?['projectId'];
    final String? ownerId = args?['ownerId'];
    final String? investorId = args?['investorId'];
    
    if (projectId == null && ownerId == null && investorId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Error")),
        body: const Center(child: Text("Missing arguments (projectId, ownerId, or investorId)")),
      );
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Determine query based on available arguments
    Query query = FirebaseFirestore.instance.collection('proposals');

    String title = "Investment Offers";
    bool isInvestorView = false;

    if (projectId != null) {
      // Original behavior: Show PENDING offers for a specific project
      query = query.where('projectId', isEqualTo: projectId).where('status', isEqualTo: 'PENDING');
    } else if (ownerId != null) {
      // Show ALL offers received by this owner (across all projects)
      query = query.where('ownerId', isEqualTo: ownerId);
      title = "Received Offers";
    } else if (investorId != null) {
      // Show ALL offers sent by this investor
      query = query.where('investorId', isEqualTo: investorId);
      title = "My Offers";
      isInvestorView = true;
    }

    // sort by creation time (descending)
    // Note: This requires an index. If not ready, it might fail.
    // We'll try to add it, but if it fails, maybe comment it out or handle error.
    // For now, let's leave it out or handle it carefully. 
    // The previous code had it commented out.

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(title),
        backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
        foregroundColor: isDark ? Colors.white : const Color(0xFF1A1A1A),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: query.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final offers = snapshot.data?.docs ?? [];

          if (offers.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    "No offers found",
                    style: TextStyle(fontSize: 18, color: isDark ? Colors.white38 : Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: offers.length,
            itemBuilder: (context, index) {
              final offer = offers[index].data() as Map<String, dynamic>;
              final offerId = offers[index].id;
              
              return _OfferCard(
                offerId: offerId,
                projectId: offer['projectId'] ?? '',
                projectTitle: offer['projectTitle'] ?? 'Unknown Project',
                investorName: offer['investorName'] ?? 'Unknown',
                amount: (offer['amount'] ?? 0).toDouble(),
                equity: (offer['equity'] ?? 0).toDouble(),
                description: offer['description'] ?? '',
                status: offer['status'] ?? 'PENDING',
                createdAt: offer['createdAt'] as Timestamp?,
                isDark: isDark,
                isInvestorView: isInvestorView,
              );
            },
          );
        },
      ),
    );
  }
}

class _OfferCard extends StatefulWidget {
  final String offerId;
  final String projectId;
  final String projectTitle;
  final String investorName;
  final double amount;
  final double equity;
  final String description;
  final String status;
  final Timestamp? createdAt;
  final bool isDark;
  final bool isInvestorView;

  const _OfferCard({
    required this.offerId,
    required this.projectId,
    required this.projectTitle,
    required this.investorName,
    required this.amount,
    required this.equity,
    required this.description,
    required this.status,
    this.createdAt,
    required this.isDark,
    required this.isInvestorView,
  });

  @override
  State<_OfferCard> createState() => _OfferCardState();
}

class _OfferCardState extends State<_OfferCard> {
  bool _isProcessing = false;
  // We no longer hide the card on accept, we just update status via stream
  // But for local interaction feedback:
  bool _localAccepted = false; 

  Future<void> _acceptOffer() async {
    if (_isProcessing) return;
    if (!mounted) return;
    
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Accept Offer'),
        content: Text(
          'Are you sure you want to accept the offer from ${widget.investorName}?\n\n'
          'Amount: ${widget.amount.toStringAsFixed(0)} EGP\n'
          'This will change your project status to FUNDED.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00A9C1),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Accept'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    if (mounted) setState(() => _isProcessing = true);

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final proposalRef = FirebaseFirestore.instance.collection('proposals').doc(widget.offerId);
        final projectRef = FirebaseFirestore.instance.collection('projects').doc(widget.projectId);

        final proposalSnapshot = await transaction.get(proposalRef);
        final projectSnapshot = await transaction.get(projectRef);

        if (!proposalSnapshot.exists) throw Exception('Proposal not found');
        if (!projectSnapshot.exists) throw Exception('Project not found');

        transaction.update(proposalRef, {
          'status': 'ACCEPTED',
          'acceptedAt': FieldValue.serverTimestamp(),
        });
        
        transaction.update(projectRef, {
          'status': 'FUNDED',
          'fundedAt': FieldValue.serverTimestamp(),
        });
      }).timeout(const Duration(seconds: 15));

      if (mounted) {
        setState(() {
          _localAccepted = true;
          _isProcessing = false;
        });
      }

      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('✅ Success! Offer accepted.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
      
      // We don't necessarily navigate away if we are in "Received Offers" list mode.
      // But if we want to mimic previous behavior:
      // navigator.pushNamedAndRemoveUntil('/owner', (route) => false);
      // Actually, staying on the list is better if managing multiple offers.
      
    } catch (e) {
      debugPrint("Error accepting offer: $e");
      if (mounted) setState(() => _isProcessing = false);
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('❌ Error: ${e.toString()}'), 
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  Future<void> _rejectOffer() async {
    try {
      if (mounted) setState(() => _isProcessing = true);
      await FirebaseFirestore.instance
          .collection('proposals')
          .doc(widget.offerId)
          .update({'status': 'REJECTED'});

      if (mounted) {
         setState(() => _isProcessing = false);
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Offer rejected')));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_localAccepted && widget.status == 'PENDING') {
      // Optimistic update visual logic could go here, 
      // strictly speaking the stream will update the widget props to 'ACCEPTED' momentarily.
    }

    final dateStr = widget.createdAt != null 
        ? "${widget.createdAt!.toDate().day}/${widget.createdAt!.toDate().month}/${widget.createdAt!.toDate().year}"
        : "Unknown";
        
    Color statusColor;
    switch (widget.status) {
      case 'ACCEPTED': statusColor = Colors.green; break;
      case 'REJECTED': statusColor = Colors.red; break;
      default: statusColor = Colors.orange;
    }

    return AnimatedOpacity(
      opacity: _isProcessing ? 0.5 : 1.0,
      duration: const Duration(milliseconds: 300),
      child: Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      color: widget.isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: widget.isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFE0E0E0),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status and Date
             Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    widget.status.toUpperCase(),
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
                  ),
                ),
                Text(
                  dateStr,
                  style: TextStyle(
                    fontSize: 12,
                    color: widget.isDark ? Colors.white54 : Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Header Info
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFF00A9C1).withValues(alpha: 0.1),
                  child: Icon(
                    widget.isInvestorView ? Icons.business : Icons.person, // Building for project, Person for investor
                    color: const Color(0xFF00A9C1),
                    size: 20
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        // If Investor view, show Project Title. If Owner View, show Investor Name (and maybe Project Title too)
                        widget.isInvestorView ? widget.projectTitle : widget.investorName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (!widget.isInvestorView) // Show project title for owners too properly
                      Text(
                         "For: ${widget.projectTitle}",
                         style: TextStyle(
                           fontSize: 12,
                           color: widget.isDark ? Colors.white54 : Colors.grey[600],
                         ),
                       ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            
            // Offer Details
            Row(
              children: [
                Expanded(
                  child: _InfoBox(
                    label: "Amount",
                    value: "${widget.amount.toStringAsFixed(0)} EGP",
                    icon: Icons.monetization_on,
                    color: Colors.green,
                    isDark: widget.isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _InfoBox(
                    label: "Equity",
                    value: "${widget.equity.toStringAsFixed(1)}%",
                    icon: Icons.percent,
                    color: Colors.orange,
                    isDark: widget.isDark,
                  ),
                ),
              ],
            ),

            if (widget.description.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                "Details:",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: widget.isDark ? Colors.white70 : Colors.grey[700],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.description,
                style: TextStyle(
                  fontSize: 14,
                  color: widget.isDark ? Colors.white60 : Colors.grey[600],
                ),
              ),
            ],

            // Only show actions if NOT investor view and status is PENDING
            if (!widget.isInvestorView && widget.status == 'PENDING') ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isProcessing ? null : _acceptOffer,
                      icon: _isProcessing 
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.check_circle_outline, size: 20),
                      label: Text(_isProcessing ? "Processing..." : "Accept"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00A9C1),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isProcessing ? null : _rejectOffer,
                      icon: const Icon(Icons.cancel_outlined, size: 20),
                      label: const Text("Reject"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
      ), // Card
    ); // AnimatedOpacity
  }
}

class _InfoBox extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool isDark;

  const _InfoBox({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white54 : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
