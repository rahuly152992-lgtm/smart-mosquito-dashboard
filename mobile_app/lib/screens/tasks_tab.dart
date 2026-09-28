import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sensor_provider.dart';
import '../theme/app_theme.dart';

class TasksTab extends StatefulWidget {
  final VoidCallback? onBack;
  const TasksTab({Key? key, this.onBack}) : super(key: key);
  @override
  State<TasksTab> createState() => _TasksTabState();
}

class _TasksTabState extends State<TasksTab> {
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<SensorProvider>().fetchRecords();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: Consumer<SensorProvider>(builder: (context, provider, _) {
          final records = provider.records.where((record) {
            if (record is! Map) return false;
            final risk = '${record['risk_level'] ?? 'unknown'}'.toLowerCase();
            if (_selectedFilter == 'High Risk') return risk == 'danger';
            if (_selectedFilter == 'Caution') return risk == 'caution';
            if (_selectedFilter == 'Safe') return risk == 'safe';
            return true;
          }).toList();
          return RefreshIndicator(
            onRefresh: () => provider.fetchRecords(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
              children: [
                Row(children: [
                  GestureDetector(onTap: widget.onBack, child: Container(width: 40, height: 40, decoration: BoxDecoration(color: AppColors.bgCard, shape: BoxShape.circle, border: Border.all(color: AppColors.borderCard)), child: const Icon(Icons.chevron_left_rounded, color: AppColors.textPrimary))),
                  const SizedBox(width: 14),
                  const Expanded(child: Text('Sensor History', style: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w700))),
                  IconButton(onPressed: () => provider.fetchRecords(), icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary)),
                ]),
                const SizedBox(height: 18),
                Row(children: [
                  _summaryCard('Records', '${provider.records.length}'),
                  const SizedBox(width: 10),
                  _summaryCard('High risk', '${provider.records.where((r) => r is Map && '${r['risk_level']}'.toLowerCase() == 'danger').length}'),
                ]),
                const SizedBox(height: 18),
                Wrap(spacing: 8, children: ['All', 'High Risk', 'Caution', 'Safe'].map((filter) => ChoiceChip(label: Text(filter), selected: _selectedFilter == filter, onSelected: (_) => setState(() => _selectedFilter = filter)).toList()),
                const SizedBox(height: 12),
                if (records.isEmpty) const Padding(padding: EdgeInsets.all(28), child: Center(child: Text('No telemetry records found.', style: TextStyle(color: AppColors.textMuted)))),
                ...records.map((record) => _recordCard(record as Map)),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _summaryCard(String label, String value) => Expanded(child: Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.borderCard)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w700)), const SizedBox(height: 4), Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 12))])));

  Widget _recordCard(Map record) {
    final risk = '${record['risk_level'] ?? 'unknown'}'.toLowerCase();
    final color = risk == 'danger' ? AppColors.danger : (risk == 'caution' ? AppColors.warning : AppColors.success);
    final timestamp = DateTime.tryParse('${record['timestamp'] ?? ''}');
    final time = timestamp == null ? '--' : timestamp.toLocal().toString().substring(0, 16);
    return Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.borderCard)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Expanded(child: Text(time, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600))), Text(risk.toUpperCase(), style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700))]), const SizedBox(height: 8), Text('Water ${record['water_level'] ?? '--'}%  ·  Temp ${record['temperature'] ?? '--'}°C  ·  Humidity ${record['humidity'] ?? '--'}%', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)), const SizedBox(height: 5), Text('AI larvae index ${record['image_risk_score'] ?? '--'}%  ·  Risk score ${record['risk_score'] ?? '--'}', style: const TextStyle(color: AppColors.textMuted, fontSize: 11))]));
  }
}
