import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/api_client.dart';
import '../../widgets/custom_button.dart';

class ServerSettingsScreen extends StatefulWidget {
  const ServerSettingsScreen({super.key});

  @override
  State<ServerSettingsScreen> createState() => _ServerSettingsScreenState();
}

class _ServerSettingsScreenState extends State<ServerSettingsScreen> {
  final _apiClient = ApiClient();
  late TextEditingController _urlController;
  late bool _isDemoMode;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: _apiClient.baseUrl);
    _isDemoMode = _apiClient.isDemoMode;
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    await _apiClient.updateBaseUrl(_urlController.text.trim());
    await _apiClient.setDemoMode(_isDemoMode);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Server settings saved successfully!'),
        backgroundColor: AppColors.income,
      ),
    );
    Navigator.pop(context);
  }

  void _setPreset(String url) {
    setState(() {
      _urlController.text = url;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Backend & API Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.lightCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.cloud_sync_outlined, color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Demo / Offline Mode',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Explore all features with simulated sample data',
                        style: TextStyle(
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: _isDemoMode,
                  activeTrackColor: AppColors.primary,
                  onChanged: (val) {
                    setState(() {
                      _isDemoMode = val;
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Backend API Base URL',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _urlController,
            enabled: !_isDemoMode,
            decoration: const InputDecoration(
              hintText: 'http://192.168.1.X/Personal Finance Tracker',
              prefixIcon: Icon(Icons.language_rounded, size: 18),
              helperText: 'Base URL hosting your PHP /backend/api endpoints',
              helperMaxLines: 2,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Quick Presets:',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ActionChip(
                label: const Text('Localhost (Desktop/Web)'),
                onPressed: () => _setPreset('http://localhost/Personal Finance Tracker'),
              ),
              ActionChip(
                label: const Text('Android Emulator (10.0.2.2)'),
                onPressed: () => _setPreset('http://10.0.2.2/Personal Finance Tracker'),
              ),
              ActionChip(
                label: const Text('Local XAMPP Port 8080'),
                onPressed: () => _setPreset('http://localhost:8080/Personal Finance Tracker'),
              ),
            ],
          ),
          const SizedBox(height: 36),
          PrimaryButton(
            text: 'Save & Apply Settings',
            icon: Icons.check_circle_outline_rounded,
            onPressed: _saveSettings,
          ),
        ],
      ),
    );
  }
}
