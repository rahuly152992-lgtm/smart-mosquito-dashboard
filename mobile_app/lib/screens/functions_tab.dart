import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class FunctionsTab extends StatefulWidget {
  final VoidCallback? onBack;
  final Function(String)? onToolSelect;

  const FunctionsTab({Key? key, this.onBack, this.onToolSelect}) : super(key: key);

  @override
  State<FunctionsTab> createState() => _FunctionsTabState();
}

class _FunctionsTabState extends State<FunctionsTab> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<Map<String, dynamic>> _functions = [
    {
      'title': 'Create Project',
      'icon': Icons.add_rounded,
      'color': Color(0xFF8B5CF6),
      'action': 'create_project',
    },
    {
      'title': 'Manage Tasks',
      'icon': Icons.checklist_rounded,
      'color': Color(0xFF38BDF8),
      'action': 'manage_tasks',
    },
    {
      'title': 'Team Chat',
      'icon': Icons.chat_bubble_rounded,
      'color': Color(0xFFA855F7),
      'action': 'team_chat',
    },
    {
      'title': 'File Storage',
      'icon': Icons.folder_rounded,
      'color': Color(0xFFF59E0B),
      'action': 'file_storage',
    },
    {
      'title': 'Analytics Hub',
      'icon': Icons.bar_chart_rounded,
      'color': Color(0xFF06B6D4),
      'action': 'analytics_hub',
    },
    {
      'title': 'Settings/\nConfigurations',
      'icon': Icons.settings_rounded,
      'color': Color(0xFF94A3B8),
      'action': 'settings',
    },
    {
      'title': 'User\nManagement',
      'icon': Icons.people_alt_rounded,
      'color': Color(0xFF10B981),
      'action': 'user_management',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final filtered = _functions
        .where((f) => f['title'].toString().toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. TOP HEADER
              Row(
                children: [
                  GestureDetector(
                    onTap: widget.onBack,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.bgCard,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.borderCard),
                      ),
                      child: const Icon(
                        Icons.chevron_left_rounded,
                        color: AppColors.textPrimary,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Text(
                    'All Functions',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 2. SEARCH BAR
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.bgCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.borderCard),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search_rounded, color: AppColors.textMuted, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) {
                          setState(() {
                            _searchQuery = val;
                          });
                        },
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 13.5),
                        decoration: const InputDecoration(
                          hintText: 'Search functions...',
                          hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 13.5),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    if (_searchQuery.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                        child: const Icon(Icons.close, color: AppColors.textMuted, size: 18),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 3. 2-COLUMN GRID OF FUNCTION TILES
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filtered.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 1.15,
                ),
                itemBuilder: (context, index) {
                  final item = filtered[index];
                  final Color iconColor = item['color'];

                  return GestureDetector(
                    onTap: () {
                      if (widget.onToolSelect != null) {
                        widget.onToolSelect!(item['action']);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Selected: ${item['title'].replaceAll('\n', ' ')}'),
                            duration: const Duration(seconds: 1),
                            backgroundColor: AppColors.bgCardAlt,
                          ),
                        );
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.bgCard,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.borderCard),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: iconColor.withOpacity(0.16),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: iconColor.withOpacity(0.3)),
                            ),
                            child: Icon(
                              item['icon'],
                              color: iconColor,
                              size: 24,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            item['title'],
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 100), // padding for bottom nav
            ],
          ),
        ),
      ),
    );
  }
}
