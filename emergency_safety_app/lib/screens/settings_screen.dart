import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/safety_controller.dart';
import '../models/emergency_model.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _urlCtrl;
  late TextEditingController _nameCtrl;
  late TextEditingController _contactCtrl;
  late bool _useBackend;
  late List<String> _contacts;
  bool _saving = false;
  bool _testing = false;
  String? _testResult;

  @override
  void initState() {
    super.initState();
    final s = context.read<SafetyController>().settings;
    _urlCtrl     = TextEditingController(text: s.backendUrl);
    _nameCtrl    = TextEditingController(text: s.userName);
    _contactCtrl = TextEditingController();
    _useBackend  = s.useBackend;
    _contacts    = List.from(s.emergencyContacts);
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    _nameCtrl.dispose();
    _contactCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final controller = context.read<SafetyController>();
    await controller.updateSettings(
      controller.settings.copyWith(
        backendUrl:        _urlCtrl.text.trim(),
        userName:          _nameCtrl.text.trim(),
        emergencyContacts: _contacts,
        useBackend:        _useBackend,
      ),
    );
    setState(() => _saving = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Settings saved'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _testConnection() async {
    setState(() { _testing = true; _testResult = null; });
    final controller = context.read<SafetyController>();
    // Temporarily update URL for the test
    await controller.updateSettings(
      controller.settings.copyWith(backendUrl: _urlCtrl.text.trim()),
    );
    setState(() {
      _testing    = false;
      _testResult = controller.backendOnline ? '✅ Connected' : '❌ Unreachable';
    });
  }

  void _addContact() {
    final raw = _contactCtrl.text.trim();
    if (raw.isEmpty) return;
    // Basic E.164 validation
    final e164 = raw.startsWith('+') ? raw : '+$raw';
    if (!RegExp(r'^\+\d{7,15}$').hasMatch(e164)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a valid phone number (e.g. +1234567890)'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    if (!_contacts.contains(e164)) {
      setState(() { _contacts.add(e164); });
    }
    _contactCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    final online = context.watch<SafetyController>().backendOnline;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('⚙️ Settings',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('SAVE', style: TextStyle(color: Colors.blueAccent,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── User info ────────────────────────────────────────────────────
          _SectionHeader('👤 User'),
          _Card(child: TextField(
            controller: _nameCtrl,
            style: const TextStyle(color: Colors.white),
            decoration: _inputDeco('Your name (shown in alerts)'),
          )),
          const SizedBox(height: 20),

          // ── Backend ──────────────────────────────────────────────────────
          _SectionHeader('🌐 Backend'),
          _Card(child: Column(
            children: [
              SwitchListTile(
                value: _useBackend,
                onChanged: (v) => setState(() => _useBackend = v),
                title: const Text('Use backend API',
                    style: TextStyle(color: Colors.white)),
                subtitle: Text(
                  online ? 'Connected' : 'Offline — using local detection',
                  style: TextStyle(
                    color: online ? Colors.greenAccent : Colors.orangeAccent,
                    fontSize: 12,
                  ),
                ),
                activeColor: Colors.blueAccent,
              ),
              if (_useBackend) ...[
                const Divider(color: Colors.white12),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: TextField(
                    controller: _urlCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDeco('Backend URL (e.g. http://10.0.2.2:8000)'),
                    keyboardType: TextInputType.url,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: _testing ? null : _testConnection,
                        icon: _testing
                            ? const SizedBox(width: 14, height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.wifi_tethering, size: 16),
                        label: const Text('Test Connection'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueGrey.shade700,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (_testResult != null)
                        Text(_testResult!,
                            style: TextStyle(
                              color: _testResult!.startsWith('✅')
                                  ? Colors.greenAccent
                                  : Colors.redAccent,
                              fontWeight: FontWeight.bold,
                            )),
                    ],
                  ),
                ),
              ],
            ],
          )),
          const SizedBox(height: 20),

          // ── Emergency contacts ───────────────────────────────────────────
          _SectionHeader('📞 Emergency Contacts'),
          _Card(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _contactCtrl,
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDeco('+1234567890'),
                        keyboardType: TextInputType.phone,
                        onSubmitted: (_) => _addContact(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _addContact,
                      icon: const Icon(Icons.add_circle, color: Colors.blueAccent, size: 30),
                    ),
                  ],
                ),
              ),
              if (_contacts.isEmpty)
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Text('No contacts added yet.',
                      style: TextStyle(color: Colors.white38, fontSize: 13)),
                )
              else
                ..._contacts.map((c) => ListTile(
                  leading: const Icon(Icons.person, color: Colors.blueAccent),
                  title: Text(c, style: const TextStyle(color: Colors.white)),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    onPressed: () => setState(() => _contacts.remove(c)),
                  ),
                )),
            ],
          )),
          const SizedBox(height: 32),

          // ── Save button ──────────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.save, color: Colors.white),
              label: const Text('Save Settings',
                  style: TextStyle(color: Colors.white, fontSize: 16,
                      fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDeco(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38),
        filled: true,
        fillColor: Colors.white.withOpacity(0.07),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      );
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(title,
            style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8)),
      );
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white12),
        ),
        child: child,
      );
}
