import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _balanceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    _balanceController.text = settingsProvider.initialBalance.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _balanceController.dispose();
    super.dispose();
  }

  void _saveInitialBalance() {
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    final newBalance = double.tryParse(_balanceController.text) ?? 0.0;
    settingsProvider.updateInitialBalance(newBalance);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Initial balance updated')),
    );
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark ||
        (themeProvider.themeMode == ThemeMode.system &&
            MediaQuery.of(context).platformBrightness == Brightness.dark);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          ListTile(
            title: const Text('Initial Balance'),
            subtitle: const Text('Set your starting account balance'),
            trailing: SizedBox(
              width: 120,
              child: CupertinoTextField(
                controller: _balanceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textAlign: TextAlign.end,
                onSubmitted: (_) => _saveInitialBalance(),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: _saveInitialBalance,
            style: ElevatedButton.styleFrom(
              foregroundColor: isDarkMode ? Colors.white : null,
            ),
            child: const Text('Save Balance'),
          ),
          const Divider(height: 32),
          ListTile(
            title: const Text('Theme'),
            subtitle: Text(isDarkMode ? 'Dark Mode' : 'Light Mode'),
            trailing: CupertinoSwitch(
              value: isDarkMode,
              onChanged: (value) {
                themeProvider.toggleTheme(value);
              },
            ),
          ),
        ],
      ),
    );
  }
} 