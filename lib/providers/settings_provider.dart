import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider with ChangeNotifier {
  static const String _initialBalanceKey = 'initialBalance';
  double _initialBalance = 0.0;

  double get initialBalance => _initialBalance;

  SettingsProvider() {
    _loadInitialBalance();
  }

  void _loadInitialBalance() async {
    final prefs = await SharedPreferences.getInstance();
    _initialBalance = prefs.getDouble(_initialBalanceKey) ?? 0.0;
    notifyListeners();
  }

  Future<void> updateInitialBalance(double newBalance) async {
    _initialBalance = newBalance;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_initialBalanceKey, newBalance);
    notifyListeners();
  }
} 