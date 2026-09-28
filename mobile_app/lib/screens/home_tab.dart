import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/sensor_provider.dart';
import '../providers/app_state.dart';

class HomeTab extends StatelessWidget {
  final VoidCallback? onNotificationTap;
  final Function(int)? onNavigateTab;

  const HomeTab({
    Key? key,
    this.onNotificationTap,
    this.onNavigateTab,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<SensorProvider>(
      builder: (context, provider, _) {
        final reading = provider.latestReading;
        final temp = reading?['temperature'] ?? '--';
        final humidity = reading?['humidity'] ?? '--';

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
                  // 1. TOP HEADER: Avatar, Welcome, Location, Bell
                  _buildHeader(context),
                  const SizedBox(height: 24),

                  // 2. MY PROJECTS SECTION TITLE
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Sensor Overview',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: AppColors.success,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${temp}°C / ${humidity}%',
                              style: const TextStyle(
                                color: AppColors.primaryLight,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 3. 2x2 PROJECT CARDS GRID
                  _buildProjectsGrid(context, provider),
                  const SizedBox(height: 20),

                  // 4. STATS COUNTERS ROW
                  _buildStatsRow(provider),
                  const SizedBox(height: 28),

                  // 5. RECENT ACTIVITY SECTION
                  _buildRecentActivity(context),
                  const SizedBox(height: 100), // padding for floating bottom bar
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        // Avatar with Glowing Ring
        GestureDetector(
          onTap: () => onNavigateTab?.call(4),
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF8B5CF6), Color(0xFF38BDF8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.4),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ],
            ),
            padding: const EdgeInsets.all(2.5),
            child: Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF1E293B),
              ),
              child: ClipOval(
                child: Image.network(
                  'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150&auto=format&fit=crop&q=80',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Center(
                    child: Icon(Icons.person, color: Colors.white, size: 28),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),

        // Welcome Text & Location
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Consumer<AppState>(
                builder: (context, appState, _) => Text(
                'Welcome, ${appState.name}!',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
                ),
              ),
              const SizedBox(height: 3),
              Row(
                children: const [
                  Icon(Icons.location_on, color: AppColors.textMuted, size: 13),
                  SizedBox(width: 3),
                  Text(
                    'Zone A (Sector 4)',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Bell Notification Button with Purple Badge
        GestureDetector(
          onTap: () {
            if (onNotificationTap != null) {
              onNotificationTap!();
            } else if (onNavigateTab != null) {
              onNavigateTab!(3); // Navigate to Alerts Tab
            }
          },
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.borderCard),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(
                  Icons.notifications_outlined,
                  color: AppColors.textSecondary,
                  size: 22,
                ),
                Positioned(
                  top: 10,
                  right: 11,
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.bgDark, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.8),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProjectsGrid(BuildContext context, SensorProvider provider) {
    final reading = provider.latestReading ?? {};
    final risk = (reading['risk_level'] ?? 'unknown').toString();
    final riskScore = reading['risk_score'] is num
        ? (reading['risk_score'] as num).toDouble()
        : 0.0;
    final water = reading['water_level'] ?? '--';
    final temperature = reading['temperature'] ?? '--';
    final humidity = reading['humidity'] ?? '--';
    final battery = provider.deviceStatus?['battery_level'] ?? '--';

    Widget metricCard(String title, String value, Color color, double progress) {
      final normalized = progress.clamp(0.0, 1.0).toDouble();
      return Expanded(
        child: _buildGlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 10),
              Text(value, style: TextStyle(color: color, fontSize: 19, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: normalized,
                  minHeight: 6,
                  backgroundColor: Colors.white.withOpacity(0.08),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Row(children: [
          metricCard('Breeding Risk', risk.toUpperCase(), risk == 'danger' ? AppColors.danger : (risk == 'caution' ? AppColors.warning : AppColors.success), riskScore / 100),
          const SizedBox(width: 14),
          metricCard('Battery Level', '$battery%', AppColors.primaryLight, (battery is num ? battery.toDouble() / 100 : 0)),
        ]),
        const SizedBox(height: 14),
        Row(children: [
          metricCard('Temperature', '$temperature°C', AppColors.accentPink, (temperature is num ? (temperature.toDouble() / 50) : 0)),
          const SizedBox(width: 14),
          metricCard('Water Level', '$water%', AppColors.primaryLight, (water is num ? water.toDouble() / 100 : 0)),
        ]),
        const SizedBox(height: 14),
        Align(
          alignment: Alignment.centerLeft,
          child: Text('Relative humidity: $humidity%', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        ),
      ],
    );
  }

  Widget _buildAvatarStack(int count) {
    const List<Color> colors = [Color(0xFF8B5CF6), Color(0xFF06B6D4), Color(0xFFEC4899)];
    return SizedBox(
      height: 24,
      child: Stack(
        children: List.generate(count, (index) {
          return Positioned(
            left: index * 16.0,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors[index % colors.length],
                border: Border.all(color: AppColors.bgCard, width: 2),
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStatsRow(SensorProvider provider) {
    return Row(
      children: [
        Expanded(
          child: _buildGlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  provider.deviceStatus?['status'] == 'connected' ? '1' : '0',
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                const Text('Connected Devices', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _buildGlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${provider.stats['active_alerts'] ?? provider.alerts.where((a) => a is Map && a['status'] == 'active').length}',
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                const Text('Active Alerts', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivity(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'System Logs',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
            GestureDetector(
              onTap: () {
                if (onNavigateTab != null) onNavigateTab!(1); // Go to Tasks/Activity
              },
              child: const Text(
                'See All',
                style: TextStyle(
                  color: AppColors.primaryLight,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Activity Item 1
        _buildActivityItem(
          icon: Icons.water_drop_outlined,
          iconBg: const Color(0xFF3B82F6),
          title: 'Pump Activated',
          time: '1 hour ago',
          subtitle: 'Water flushed from Zone A',
        ),
        const SizedBox(height: 12),

        // Activity Item 2
        _buildActivityItem(
          icon: Icons.warning_amber_rounded,
          iconBg: const Color(0xFFF97316),
          title: 'High Humidity Detected',
          time: '3 hours ago',
          subtitle: "Levels reached 85% in Sector 4.",
        ),
      ],
    );
  }

  Widget _buildActivityItem({
    required IconData icon,
    required Color iconBg,
    required String title,
    required String time,
    required String subtitle,
  }) {
    return _buildGlassCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBg.withOpacity(0.18),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: iconBg.withOpacity(0.35)),
            ),
            child: Icon(icon, color: iconBg, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      time,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassCard({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16),
  }) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderCard),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

// Progress Ring Custom Painter
class _ProgressRingPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color trackColor;
  final Color progressColor;
  final Color accentColor;

  _ProgressRingPainter({
    required this.progress,
    required this.strokeWidth,
    required this.trackColor,
    required this.progressColor,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Track
    final trackPaint = Paint()
      ..color = trackColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius, trackPaint);

    // Progress Arc
    final progressPaint = Paint()
      ..shader = SweepGradient(
        startAngle: 0.0,
        endAngle: math.pi * 2,
        colors: [progressColor, accentColor, progressColor],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final sweepAngle = math.pi * 2 * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
