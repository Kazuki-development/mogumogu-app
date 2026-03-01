
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:app_settings/app_settings.dart';
import '../viewmodels/food_list_view_model.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _version = '...';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _version = '${packageInfo.version}+${packageInfo.buildNumber}';
    });
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    try {
      if (!await launchUrl(uri)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('URLを開けませんでした')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('URLを開けませんでした')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('設定'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      backgroundColor: Colors.grey[50],
      body: Consumer<FoodListViewModel>(
        builder: (context, viewModel, child) {
          return ListView(
            children: [
              const SizedBox(height: 16),
              _buildSectionHeader('全般'),
              _buildSwitchTile(
                title: '期限切れを自動削除',
                subtitle: '賞味期限を過ぎた食材を、アプリ起動時に自動で削除します。',
                value: viewModel.autoDeleteEnabled,
                onChanged: (bool value) {
                  viewModel.setAutoDeleteEnabled(value);
                },
                icon: Icons.auto_delete,
                isDangerous: true,
              ),

              const Divider(height: 32),
              _buildSectionHeader('通知'),
              _buildTile(
                title: '通知設定を確認',
                subtitle: 'OSの設定画面を開きます',
                icon: Icons.notifications_active,
                onTap: () {
                  AppSettings.openAppSettings(type: AppSettingsType.notification);
                },
              ),

              const Divider(height: 32),
              _buildSectionHeader('アプリについて'),
               _buildTile(
                title: 'プライバシーポリシー',
                icon: Icons.privacy_tip,
                onTap: () {
                  _launchUrl('https://note.com/e_ai/n/nd0baeb7e560b'); 
                },
              ),
              _buildTile(
                title: 'バージョン',
                subtitle: _version,
                icon: Icons.info,
                onTap: null,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildTile({
    required String title,
    String? subtitle,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return Container(
      color: Colors.white,
      child: ListTile(
        leading: Icon(icon, color: Colors.grey[700]),
        title: Text(title, style: const TextStyle(fontSize: 16)),
        subtitle: subtitle != null
            ? Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey))
            : null,
        trailing: onTap != null ? const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey) : null,
        onTap: onTap,
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
    bool isDangerous = false,
  }) {
    return Container(
      color: Colors.white,
      child: SwitchListTile(
        secondary: Icon(icon, color: isDangerous ? Colors.red[300] : Colors.grey[700]),
        title: Text(title, style: const TextStyle(fontSize: 16)),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 12, color: isDangerous ? Colors.red[300] : Colors.grey),
        ),
        value: value,
        onChanged: onChanged,
        activeTrackColor: const Color(0xFFFF9800),
      ),
    );
  }
}
