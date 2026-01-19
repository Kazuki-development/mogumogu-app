
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../viewmodels/food_list_view_model.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      throw Exception('Could not launch $url');
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
      backgroundColor: Colors.grey[50], // Very light grey background
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
                  // Usually linking to OS settings is platform specific or requires a plugin like app_settings
                  // For now, we can't easily open specific app settings without plugin 'app_settings'
                  // So we might skip this action or show a dialog.
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('OSの設定アプリから通知を許可してください')));
                },
              ),

              const Divider(height: 32),
              _buildSectionHeader('アプリについて'),
               _buildTile(
                title: 'プライバシーポリシー',
                icon: Icons.privacy_tip,
                onTap: () {
                  // Placeholder URL
                  _launchUrl('https://example.com/privacy'); 
                },
              ),
              _buildTile(
                title: 'バージョン',
                subtitle: '1.0.0+4', // Ideally dynamic
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
        activeColor: const Color(0xFFFF9800),
      ),
    );
  }
}
