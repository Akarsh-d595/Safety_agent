import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/safety_controller.dart';
import '../models/emergency_model.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    await context.read<SafetyController>().loadIncidents();
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final incidents = context.watch<SafetyController>().incidents;
    final online    = context.watch<SafetyController>().backendOnline;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('📋 Incident History',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _refresh,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.blueAccent))
          : !online
              ? _OfflineBanner()
              : incidents.isEmpty
                  ? _EmptyState()
                  : RefreshIndicator(
                      onRefresh: _refresh,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: incidents.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) => _IncidentTile(incident: incidents[i]),
                      ),
                    ),
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, color: Colors.white38, size: 64),
            const SizedBox(height: 16),
            const Text('Backend offline',
                style: TextStyle(color: Colors.white54, fontSize: 18)),
            const SizedBox(height: 8),
            const Text('Incident history requires a backend connection.',
                style: TextStyle(color: Colors.white38, fontSize: 13),
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey),
              child: const Text('Go to Settings',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, color: Colors.white24, size: 64),
            SizedBox(height: 16),
            Text('No incidents recorded yet.',
                style: TextStyle(color: Colors.white54, fontSize: 16)),
          ],
        ),
      );
}

class _IncidentTile extends StatelessWidget {
  final IncidentRecord incident;
  const _IncidentTile({required this.incident});

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(incident.level);
    final label = _labelFor(incident.level);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color),
                ),
                child: Text(label,
                    style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
              ),
              const Spacer(),
              Text(
                _formatDate(incident.timestamp),
                style: const TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Text
          Text(incident.text,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              maxLines: 3,
              overflow: TextOverflow.ellipsis),
          // Location
          if (incident.latitude != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.greenAccent, size: 14),
                const SizedBox(width: 4),
                Text(
                  '${incident.latitude!.toStringAsFixed(4)}, '
                  '${incident.longitude!.toStringAsFixed(4)}',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ],
          // Triggered badge
          if (incident.triggered) ...[
            const SizedBox(height: 6),
            const Row(
              children: [
                Icon(Icons.emergency, color: Colors.redAccent, size: 14),
                SizedBox(width: 4),
                Text('Emergency triggered',
                    style: TextStyle(color: Colors.redAccent, fontSize: 12)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Color _colorFor(DangerLevel level) {
    switch (level) {
      case DangerLevel.high:   return Colors.red;
      case DangerLevel.medium: return Colors.orange;
      case DangerLevel.low:    return Colors.yellow;
      case DangerLevel.none:   return Colors.grey;
    }
  }

  String _labelFor(DangerLevel level) {
    switch (level) {
      case DangerLevel.high:   return '🚨 HIGH';
      case DangerLevel.medium: return '⚠️ MEDIUM';
      case DangerLevel.low:    return '🔔 LOW';
      case DangerLevel.none:   return '✅ SAFE';
    }
  }

  String _formatDate(DateTime dt) {
    final local = dt.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/'
        '${local.year}  '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }
}
