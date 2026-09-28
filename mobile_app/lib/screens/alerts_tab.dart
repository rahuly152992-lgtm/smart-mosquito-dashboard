import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../providers/sensor_provider.dart';
import '../theme/app_theme.dart';

class AlertsTab extends StatefulWidget {
  final VoidCallback? onBack;
  const AlertsTab({Key? key, this.onBack}) : super(key: key);
  @override
  State<AlertsTab> createState() => _AlertsTabState();
}

class _AlertsTabState extends State<AlertsTab> {
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<SensorProvider>().fetchAlerts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: Consumer<SensorProvider>(
          builder: (context, provider, _) {
            final alerts = provider.alerts.where((item) {
              if (item is! Map) return false;
              return _filter == 'all' || item['status'] == _filter;
            }).toList();
            final activeDanger = alerts.where((a) => a['status'] == 'active' && a['risk_level'] == 'danger').isNotEmpty;
            return RefreshIndicator(
              onRefresh: () => provider.fetchAlerts(status: 'all'),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                children: [
                  Row(children: [
                    GestureDetector(onTap: widget.onBack, child: Container(width: 40, height: 40, decoration: BoxDecoration(color: AppColors.bgCard, shape: BoxShape.circle, border: Border.all(color: AppColors.borderCard)), child: const Icon(Icons.chevron_left_rounded, color: AppColors.textPrimary))),
                    const SizedBox(width: 14),
                    const Expanded(child: Text('System Alerts', style: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w700))),
                    IconButton(onPressed: () => provider.fetchAlerts(status: 'all'), icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary)),
                  ]),
                  const SizedBox(height: 18),
                  if (activeDanger) Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0xFF281118), borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.danger.withOpacity(0.5))), child: const Text('CRITICAL ALERT: Active breeding risk detected. Review the incident and take action.', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600))),
                  if (activeDanger) const SizedBox(height: 16),
                  Wrap(spacing: 8, children: ['all', 'active', 'resolved'].map((value) => ChoiceChip(label: Text(value[0].toUpperCase() + value.substring(1)), selected: _filter == value, onSelected: (_) => setState(() => _filter = value)).toList()),
                  const SizedBox(height: 12),
                  if (provider.isLoading && alerts.isEmpty) const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator())),
                  if (!provider.isLoading && alerts.isEmpty) const Padding(padding: EdgeInsets.all(28), child: Center(child: Text('No alerts recorded.', style: TextStyle(color: AppColors.textMuted)))),
                  ...alerts.map((alert) => _buildAlertCard(context, alert, provider)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAlertCard(BuildContext context, Map alert, SensorProvider provider) {
    final resolved = alert['status'] == 'resolved';
    final danger = alert['risk_level'] == 'danger';
    final color = resolved ? AppColors.success : (danger ? AppColors.danger : AppColors.warning);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.borderCard)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Expanded(child: Text('${alert['title'] ?? 'Breeding risk alert'}', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700))), Text(resolved ? 'RESOLVED' : (danger ? 'HIGH RISK' : 'CAUTION'), style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700))]),
        const SizedBox(height: 6),
        Text('📍 ${alert['location'] ?? 'Unknown location'}  ·  ${alert['created_at'] ?? ''}', style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
        const SizedBox(height: 8),
        Text('Water ${alert['water_level'] ?? '--'}%  ·  Temp ${alert['temperature'] ?? '--'}°C  ·  Humidity ${alert['humidity'] ?? '--'}%', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        const SizedBox(height: 10),
        Row(children: [
          TextButton(onPressed: () => _showDetails(context, alert), child: const Text('Details')),
          const Spacer(),
          if (!resolved) FilledButton.tonalIcon(
            onPressed: provider.isLoading ? null : () async {
              final name = context.read<AppState>().name;
              final success = await provider.resolveAlert('${alert['alert_id']}', name);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(success ? 'Alert resolved' : 'Unable to resolve alert')));
            },
            icon: const Icon(Icons.check, size: 16), label: const Text('Resolve'),
          ),
        ]),
      ]),
    );
  }

  void _showDetails(BuildContext context, Map alert) {
    final reasons = (alert['reasons'] as List?)?.join('\n• ') ?? 'No detection details available.';
    showDialog<void>(context: context, builder: (dialogContext) => AlertDialog(
      title: Text('${alert['title'] ?? 'Alert details'}'),
      content: SingleChildScrollView(child: Text('ID: ${alert['alert_id'] ?? '--'}\nDevice: ${alert['device_id'] ?? '--'}\nLocation: ${alert['location'] ?? '--'}\nWater: ${alert['water_level'] ?? '--'}%\nTemperature: ${alert['temperature'] ?? '--'}°C\nHumidity: ${alert['humidity'] ?? '--'}%\n\nDetection drivers:\n• $reasons')),
      actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Close'))],
    ));
  }
}
