import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'providers/transaction_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/home_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/transactions_screen.dart';
import 'screens/add_transaction_wizard.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => TransactionProvider()),
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
      ],
      child: const WeekliApp(),
    ),
  );
}

class WeekliApp extends StatelessWidget {
  const WeekliApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Weekli - Weekly Finance Tracker',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          locale: const Locale('en', 'GB'),
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en', 'US'),
            Locale('en', 'GB'),
          ],
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
        );
      },
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
