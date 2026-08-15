import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme/app_colors.dart';
import '../services/background_sync_service.dart';
import '../services/storage_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  String _refreshInterval = '3 Hours';

  Duration _intervalToDuration(String interval) {
    switch (interval) {
      case '1 Hour':
        return const Duration(hours: 1);
      case '6 Hours':
        return const Duration(hours: 6);
      case '12 Hours':
        return const Duration(hours: 12);
      case '3 Hours':
      default:
        return const Duration(hours: 3);
    }
  }

  Future<void> _exportDataJson() async {
    final jsonStr = StorageService.exportDataAsJson();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        title: const Text('Export Local JSON Backup'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Copy your complete local DELHIVERY data backup:',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Container(
              height: 150,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  jsonStr,
                  style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: jsonStr));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Backup JSON copied to clipboard!')),
              );
            },
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: const Text('Copy JSON'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentPrimary,
              foregroundColor: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _importDataJson() async {
    final textController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        title: const Text('Import JSON Backup'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Paste your exported JSON backup data below:',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: textController,
              maxLines: 6,
              style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
              decoration: const InputDecoration(
                hintText: '{"app": "DELHIVERY", ...}',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentPrimary,
              foregroundColor: Colors.black,
            ),
            child: const Text('Import Data'),
          ),
        ],
      ),
    );

    if (result == true && textController.text.trim().isNotEmpty) {
      final success = await StorageService.importDataFromJson(textController.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? 'Data imported successfully!' : 'Failed to parse import JSON format.',
            ),
            backgroundColor: AppColors.cardBg,
          ),
        );
      }
    }
  }

  Future<void> _confirmClearAllData() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        title: const Text('Clear All Local Data?'),
        content: const Text(
          'This will permanently delete all tracked shipments and activity logs stored locally on your device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear All', style: TextStyle(color: AppColors.statusDelayed)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await StorageService.clearAllData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All local data cleared!')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Settings & Info'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Section: Sync & Notifications
          const Text(
            'BACKGROUND SYNC & NOTIFICATIONS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Local Status Notifications', style: TextStyle(color: AppColors.textPrimary)),
                  subtitle: const Text('Alert when package status changes during refresh', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  activeColor: AppColors.accentPrimary,
                  value: _notificationsEnabled,
                  onChanged: (val) async {
                    setState(() {
                      _notificationsEnabled = val;
                    });
                    if (val) {
                      await BackgroundSyncService.registerPeriodicTask(
                        frequency: _intervalToDuration(_refreshInterval),
                      );
                    } else {
                      await BackgroundSyncService.cancelPeriodicTask();
                    }
                  },
                ),
                const Divider(color: AppColors.cardBorder, height: 1),
                ListTile(
                  title: const Text('Refresh Interval', style: TextStyle(color: AppColors.textPrimary)),
                  subtitle: Text('Current: $_refreshInterval', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  trailing: DropdownButton<String>(
                    value: _refreshInterval,
                    dropdownColor: AppColors.cardBg,
                    style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                    underline: const SizedBox(),
                    items: ['1 Hour', '3 Hours', '6 Hours', '12 Hours']
                        .map((val) => DropdownMenuItem(value: val, child: Text(val)))
                        .toList(),
                    onChanged: (val) async {
                      if (val != null) {
                        setState(() {
                          _refreshInterval = val;
                        });
                        if (_notificationsEnabled) {
                          await BackgroundSyncService.registerPeriodicTask(
                            frequency: _intervalToDuration(val),
                          );
                        }
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Section: Supported Logistics Providers
          const Text(
            'COURIER INTEGRATION MODE',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.check_circle_rounded, color: AppColors.textPrimary, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Auto-Tracked Couriers (Scrape Adapters):',
                      style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 13),
                    ),
                  ],
                ),
                SizedBox(height: 6),
                Padding(
                  padding: EdgeInsets.only(left: 26),
                  child: Text(
                    '• Delhivery\n• India Post\n• DTDC\n• Ecom Express\n• Blue Dart',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
                  ),
                ),
                SizedBox(height: 14),
                Row(
                  children: [
                    Icon(Icons.link_rounded, color: AppColors.textSecondary, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Manual Link Mode (Internal Platforms):',
                      style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 13),
                    ),
                  ],
                ),
                SizedBox(height: 6),
                Padding(
                  padding: EdgeInsets.only(left: 26),
                  child: Text(
                    '• Amazon, Flipkart, Myntra, Ajio internal logistics (Direct link launch & manual status marking).',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Section: Data & Backup
          const Text(
            'DATA MANAGEMENT (LOCAL HIVE STORAGE)',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.file_upload_outlined, color: AppColors.textPrimary),
                  title: const Text('Export Backup (JSON)', style: TextStyle(color: AppColors.textPrimary)),
                  subtitle: const Text('Copy JSON string of all shipments', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  onTap: _exportDataJson,
                ),
                const Divider(color: AppColors.cardBorder, height: 1),
                ListTile(
                  leading: const Icon(Icons.file_download_outlined, color: AppColors.textPrimary),
                  title: const Text('Import Backup (JSON)', style: TextStyle(color: AppColors.textPrimary)),
                  subtitle: const Text('Restore shipments from JSON data', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  onTap: _importDataJson,
                ),
                const Divider(color: AppColors.cardBorder, height: 1),
                ListTile(
                  leading: const Icon(Icons.delete_forever_outlined, color: AppColors.statusDelayed),
                  title: const Text('Clear All Local Data', style: TextStyle(color: AppColors.statusDelayed)),
                  subtitle: const Text('Delete all local Hive DB records', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  onTap: _confirmClearAllData,
                ),
              ],
            ),
          ),
          const SizedBox(height: 36),

          // About Card
          const Center(
            child: Column(
              children: [
                Text(
                  'DELHIVERY v1.0.0',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '100% Free & Local-First • Universal Tracker',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
