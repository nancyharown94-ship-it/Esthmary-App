import 'package:flutter/material.dart';

class HelpSupportPage extends StatefulWidget {
  const HelpSupportPage({super.key});

  @override
  State<HelpSupportPage> createState() => _HelpSupportPageState();
}

class _HelpSupportPageState extends State<HelpSupportPage> {
  // Expanded state for FAQs to allow only one open at a time if desired, or just for tracking
  // Using ExpansionTile automatically handles state, but customized look is better.

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final backgroundColor = isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF5F5F5);
    final textColor = isDark ? Colors.white : Colors.black87;
    final primaryColor = const Color(0xFF00A9C1);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Help & Support',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Illustration/Icon
                  Center(
                    child: Container(
                      height: 120,
                      width: 120,
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.support_agent,
                        size: 60,
                        color: primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: Text(
                      "How can we help you?",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      "Find answers to common questions or contact us directly.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.white54 : Colors.grey[600],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // FAQ Section Title
                  Text(
                    "FREQUENTLY ASKED QUESTIONS",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white54 : Colors.grey[600],
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // FAQs
                  _buildFAQItem(
                    context,
                    'How do I invest in a project?',
                    'Browse the projects on the home page, select one you like, and click "Submit Proposal" to send your offer to the owner.',
                    isDark, 
                    primaryColor,
                  ),
                  _buildFAQItem(
                    context,
                    'Is my personal information safe?',
                    'Yes, we take security seriously and use industry-standard encryption to protect your data. Your privacy is our top priority.',
                    isDark,
                    primaryColor,
                  ),
                  _buildFAQItem(
                    context,
                    'How can I add my own project?',
                    'If you are registered as an Owner, you can tap the floating "+" button on your home dashboard to create a new project listing.',
                    isDark,
                    primaryColor,
                  ),
                  _buildFAQItem(
                    context,
                    'Can I change my account type?',
                    'Currently, account types are fixed upon registration. Please contact support if you need to switch roles.',
                    isDark,
                    primaryColor,
                  ),

                  const SizedBox(height: 32),
                  
                  // Contact Section Title
                  Text(
                    "CONTACT US",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white54 : Colors.grey[600],
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildContactCard(
                    context,
                    icon: Icons.email_outlined,
                    title: "Email Support",
                    subtitle: "support@isthmary.com",
                    isDark: isDark,
                    primaryColor: primaryColor,
                  ),
                  const SizedBox(height: 12),
                   _buildContactCard(
                    context,
                    icon: Icons.phone_outlined,
                    title: "Call Us",
                    subtitle: "+20 123 456 7890",
                    isDark: isDark,
                    primaryColor: primaryColor,
                  ),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQItem(BuildContext context, String question, String answer, bool isDark, Color primaryColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
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
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          title: Text(
            question,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          iconColor: primaryColor,
          collapsedIconColor: isDark ? Colors.white54 : Colors.grey,
          children: [
            Text(
              answer,
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.grey[700],
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDark,
    required Color primaryColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: primaryColor, size: 24),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white70 : Colors.grey[600],
                ),
              ),
            ],
          ),
          const Spacer(),
          Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: isDark ? Colors.white24 : Colors.grey[300],
          ),
        ],
      ),
    );
  }
}
