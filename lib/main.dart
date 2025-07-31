import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/transaction_provider.dart';
import 'screens/home_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/transactions_screen.dart';
import 'screens/add_transaction_wizard.dart';

void main() {
  runApp(const WeekliApp());
}

class WeekliApp extends StatelessWidget {
  const WeekliApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => TransactionProvider(),
      child: MaterialApp(
        title: 'Weekli - Weekly Finance Tracker',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.teal,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          cardTheme: CardTheme(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 0,
          ),
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.teal,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
          cardTheme: CardTheme(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 0,
          ),
        ),
        themeMode: ThemeMode.system,
        initialRoute: '/',
        routes: {
          '/': (context) => const HomeScreen(),
          '/dashboard': (context) => const DashboardScreen(),
          '/calendar': (context) => const CalendarScreen(),
          '/transactions': (context) => const TransactionsScreen(),
          '/add-transaction': (context) => const AddTransactionWizard(),
        },
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case '/dashboard':
              return MaterialPageRoute(
                builder: (context) => const DashboardScreen(),
                settings: settings,
              );
            case '/calendar':
              return MaterialPageRoute(
                builder: (context) => const CalendarScreen(),
                settings: settings,
              );
            case '/transactions':
              return MaterialPageRoute(
                builder: (context) => const TransactionsScreen(),
                settings: settings,
              );
            case '/add-transaction':
              return MaterialPageRoute(
                builder: (context) => const AddTransactionWizard(),
                settings: settings,
              );
            default:
              return MaterialPageRoute(
                builder: (context) => const HomeScreen(),
                settings: settings,
              );
          }
        },
      ),
    );
  }
}

// Navigation Helper Class
class AppRoutes {
  static const String home = '/';
  static const String dashboard = '/dashboard';
  static const String calendar = '/calendar';
  static const String transactions = '/transactions';
  static const String addTransaction = '/add-transaction';

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
    Navigator.pop(context);
  }
}
