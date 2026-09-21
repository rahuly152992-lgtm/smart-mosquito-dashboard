import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AlertsTab extends StatefulWidget {
  final VoidCallback? onBack;

  const AlertsTab({Key? key, this.onBack}) : super(key: key);

  @override
  State<AlertsTab> createState() => _AlertsTabState();
}

class _AlertsTabState extends State<AlertsTab> {
  bool _showCriticalAlert = true;

  final List<Map<String, dynamic>> _alerts = [
    {
      'type': 'comment',
      'title': 'New Comment',
      'subtitle': 'Prioritized notifications',
      'color': Color(0xFF10B981),
      'icon': Icons.chat_bubble_outline_rounded,
    },
    {
      'type': 'team',
      'title': 'Team Joined',
      'subtitle': 'Prioritized notifications',
      'color': Color(0xFFF97316),
      'icon': Icons.groups_outlined,
    },
    {
      'type': 'team',
      'title': 'Team Joined',
      'subtitle': 'Prioritized notifications',
      'color': Color(0xFF38BDF8),
      'icon': Icons.groups_outlined,
    },
    {
      'type': 'comment',
      'title': 'New Comment',
      'subtitle': 'Prioritized notifications',
      'color': Color(0xFFEF4444),
      'icon': Icons.chat_bubble_outline_rounded,
    },
    {
      'type': 'team',
      'title': 'Team Joined',
      'subtitle': 'Prioritized notifications',
      'color': Color(0xFF10B981),
      'icon': Icons.groups_outlined,
    },
    {
      'type': 'team',
      'title': 'Team Joined',
      'subtitle': 'Prioritized notifications',
      'color': Color(0xFFF59E0B),
      'icon': Icons.groups_outlined,
    },
  ];

  @override
  Widget build(BuildContext context) {
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
              // 1. TOP HEADER: Back Button, Title, Filter Funnel
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
                  const Expanded(
                    child: Text(
                      'System Alerts',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.bgCard,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.borderCard),
                    ),
                    child: const Icon(
                      Icons.filter_list_rounded,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 2. CRITICAL ALERT BANNER
              if (_showCriticalAlert) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF281118),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.danger.withOpacity(0.5)),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.danger.withOpacity(0.2),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: AppColors.danger.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.warning_amber_rounded,
                              color: AppColors.danger,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'CRITICAL ALERT:\nBudget Threshold Breached',
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    height: 1.25,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _showCriticalAlert = false;
                              });
                            },
                            child: const Icon(
                              Icons.close_rounded,
                              color: AppColors.textMuted,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Critical alert is a session budget threshold Threshold Breached.\nLine to full report',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // 3. NOTIFICATION LIST
              ..._alerts.map((item) {
                final Color itemColor = item['color'];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
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
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: itemColor.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: itemColor.withOpacity(0.35)),
                          ),
                          child: Icon(
                            item['icon'],
                            color: itemColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['title'],
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                item['subtitle'],
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.textMuted,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
              const SizedBox(height: 100), // padding for bottom nav
            ],
          ),
        ),
      ),
    );
  }
}
