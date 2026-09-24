import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class TasksTab extends StatefulWidget {
  final VoidCallback? onBack;

  const TasksTab({Key? key, this.onBack}) : super(key: key);

  @override
  State<TasksTab> createState() => _TasksTabState();
}

class _TasksTabState extends State<TasksTab> {
  String _selectedFilter = 'My';

  final List<Map<String, dynamic>> _tasks = [
    {
      'title': "Zone A (Sector 4)",
      'dueDate': 'High Risk',
      'isOverdue': true,
      'badges': ['red_alert'],
      'checked': false,
    },
    {
      'title': 'Zone B (Lake View)',
      'dueDate': 'Safe',
      'isOverdue': false,
      'badges': ['green', 'circle'],
      'checked': true,
    },
    {
      'title': "Zone C (Park Area)",
      'subtitle': 'Water Temp 32°C',
      'isOverdue': true,
      'badges': ['warning'],
      'checked': false,
    },
    {
      'title': "Zone D (North)",
      'dueDate': 'Caution',
      'isOverdue': false,
      'badges': ['warning', 'circle'],
      'checked': false,
    },
    {
      'title': 'Zone E (South)',
      'dueDate': 'Safe',
      'isOverdue': false,
      'badges': ['green'],
      'checked': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Background ambient orange/amber flare (matching screenshot)
          Positioned(
            top: -40,
            right: -60,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.accentOrange.withOpacity(0.18),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. TOP HEADER: Back Button & Title
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
                        "Zone Monitoring",
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 2. CORE FEATURES
                  const Text(
                    'Quick Filters',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildFeatureCard(
                          title: 'High Risk',
                          subtitle: 'Zones',
                          tag: 'Alerts',
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _buildFeatureCard(
                          title: 'Safe',
                          subtitle: 'Zones',
                          tag: 'Normal',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),

                  // 3. FILTER PILLS (My, All, Overdue)
                  Row(
                    children: ['My', 'All', 'Overdue'].map((filter) {
                      final isSelected = _selectedFilter == filter;
                      return Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedFilter = filter;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primary : AppColors.bgCard,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected ? AppColors.primary : AppColors.borderCard,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: AppColors.primary.withOpacity(0.4),
                                        blurRadius: 10,
                                        spreadRadius: 1,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Text(
                              filter,
                              style: TextStyle(
                                color: isSelected ? Colors.white : AppColors.textSecondary,
                                fontSize: 13,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // 4. TASK ITEMS LIST
                  ..._buildFilteredTasks(),
                  const SizedBox(height: 100), // padding for bottom nav
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({
    required String title,
    required String subtitle,
    required String tag,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderCard),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 16),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: AppColors.textMuted.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                tag,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildFilteredTasks() {
    List<Map<String, dynamic>> displayed = _tasks;
    if (_selectedFilter == 'Overdue') {
      displayed = _tasks.where((t) => t['isOverdue'] == true).toList();
    }

    return displayed.map((task) {
      final isOverdue = task['isOverdue'] == true;
      final isChecked = task['checked'] == true;

      if (isOverdue) {
        // Red glowing Overdue card
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF2A151C),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.danger.withOpacity(0.5)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.danger.withOpacity(0.18),
                  blurRadius: 14,
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.danger.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.calendar_today_rounded,
                    color: AppColors.danger,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task['title'],
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Overdue',
                        style: TextStyle(
                          color: AppColors.danger,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(
                    color: AppColors.danger,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(Icons.priority_high, color: Colors.white, size: 14),
                  ),
                ),
              ],
            ),
          ),
        );
      }

      // Standard Task Card
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderCard),
          ),
          child: Row(
            children: [
              // Checkbox Circle
              GestureDetector(
                onTap: () {
                  setState(() {
                    task['checked'] = !isChecked;
                  });
                },
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isChecked ? AppColors.primary : Colors.transparent,
                    border: Border.all(
                      color: isChecked ? AppColors.primary : AppColors.textMuted,
                      width: 1.8,
                    ),
                  ),
                  child: isChecked
                      ? const Icon(Icons.check, color: Colors.white, size: 14)
                      : null,
                ),
              ),
              const SizedBox(width: 14),

              // Title & Due Date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task['title'],
                      style: TextStyle(
                        color: isChecked ? AppColors.textMuted : AppColors.textPrimary,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        decoration: isChecked ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Due Date  ${task['dueDate'] ?? '06 Nov'}',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),

              // Badges
              Row(
                children: _buildTaskBadges(task['badges'] ?? []),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  List<Widget> _buildTaskBadges(List<dynamic> badges) {
    List<Widget> widgets = [];
    for (var b in badges) {
      if (b == 'green') {
        widgets.add(
          Container(
            width: 12,
            height: 12,
            margin: const EdgeInsets.only(left: 6),
            decoration: const BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
            ),
          ),
        );
      } else if (b == 'red') {
        widgets.add(
          Container(
            width: 12,
            height: 12,
            margin: const EdgeInsets.only(left: 6),
            decoration: const BoxDecoration(
              color: AppColors.danger,
              shape: BoxShape.circle,
            ),
          ),
        );
      } else if (b == 'warning') {
        widgets.add(
          const Padding(
            padding: EdgeInsets.only(left: 6),
            child: Icon(Icons.warning_rounded, color: AppColors.warning, size: 16),
          ),
        );
      } else if (b == 'circle') {
        widgets.add(
          Container(
            width: 12,
            height: 12,
            margin: const EdgeInsets.only(left: 6),
            decoration: const BoxDecoration(
              color: AppColors.accentOrange,
              shape: BoxShape.circle,
            ),
          ),
        );
      }
    }
    return widgets;
  }
}
