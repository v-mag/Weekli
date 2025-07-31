import 'package:flutter/material.dart';

class NavigationHelper {
  // Route names
  static const String home = '/';
  static const String dashboard = '/dashboard';
  static const String calendar = '/calendar';
  static const String transactions = '/transactions';
  static const String addTransaction = '/add-transaction';

  // Navigation methods
  static void navigateTo(BuildContext context, String routeName) {
    Navigator.pushNamed(context, routeName);
  }

  static void navigateToAndReplace(BuildContext context, String routeName) {
    Navigator.pushReplacementNamed(context, routeName);
  }

  static void navigateToAndClear(BuildContext context, String routeName) {
    Navigator.pushNamedAndRemoveUntil(
      context,
      routeName,
      (route) => false,
    );
  }

  static void goBack(BuildContext context) {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  static void goBackToHome(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(
      context,
      home,
      (route) => false,
    );
  }

  // Specific navigation methods for easier use
  static void goToDashboard(BuildContext context) {
    navigateTo(context, dashboard);
  }

  static void goToCalendar(BuildContext context) {
    navigateTo(context, calendar);
  }

  static void goToTransactions(BuildContext context) {
    navigateTo(context, transactions);
  }

  static void goToAddTransaction(BuildContext context) {
    navigateTo(context, addTransaction);
  }
} 