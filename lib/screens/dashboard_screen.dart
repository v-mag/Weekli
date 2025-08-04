import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/transaction_provider.dart';
import '../providers/theme_provider.dart';
import '../models/transaction.dart' as model;
import '../theme/app_theme.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weekli Dashboard'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              final isDarkMode = themeProvider.themeMode == ThemeMode.dark ||
                  (themeProvider.themeMode == ThemeMode.system &&
                      MediaQuery.of(context).platformBrightness == Brightness.dark);
              return IconButton(
                icon: Icon(
                  isDarkMode ? Icons.light_mode : Icons.dark_mode,
                ),
                onPressed: () {
                  themeProvider.toggleTheme(!isDarkMode);
                },
              );
            },
          ),
        ],
      ),
      body: Consumer<TransactionProvider>(
        builder: (context, provider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Weekly Overview Card
                _buildOverviewCard(
                  context,
                  'This Week',
                  provider.weeklyIncome,
                  provider.weeklyExpense,
                  provider.weeklyBalance,
                ),
                const SizedBox(height: 16),
                
                // Monthly Overview Card
                _buildOverviewCard(
                  context,
                  'This Month',
                  provider.monthlyIncome,
                  provider.monthlyExpense,
                  provider.monthlyBalance,
                ),
                const SizedBox(height: 24),
                
                // Recent Transactions
                Text(
                  'Recent Transactions',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                
                if (provider.transactions.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.receipt_long, size: 48, color: Colors.grey),
                            SizedBox(height: 8),
                            Text(
                              'No transactions yet',
                              style: TextStyle(color: Colors.grey, fontSize: 16),
                            ),
                            Text(
                              'Tap the + button to add your first transaction',
                              style: TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  ...provider.transactions.take(5).map((transaction) =>
                    _buildTransactionTile(context, transaction)
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildOverviewCard(
    BuildContext context,
    String title,
    double income,
    double expense,
    double balance,
  ) {
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: _buildAmountColumn(
                    'Income',
                    currencyFormat.format(income),
                    Colors.green,
                    Icons.trending_up,
                  ),
                ),
                Expanded(
                  child: _buildAmountColumn(
                    'Expense',
                    currencyFormat.format(expense),
                    Colors.red,
                    Icons.trending_down,
                  ),
                ),
                Expanded(
                  child: _buildAmountColumn(
                    'Balance',
                    currencyFormat.format(balance),
                    balance >= 0 ? Colors.green : Colors.red,
                    balance >= 0 ? Icons.account_balance_wallet : Icons.warning,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountColumn(String label, String amount, Color color, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          amount,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionTile(BuildContext context, model.Transaction transaction) {
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    final dateFormat = DateFormat('MMM dd, yyyy');
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: transaction.isIncome ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
          child: Icon(
            transaction.isIncome ? Icons.trending_up : Icons.trending_down,
            color: transaction.isIncome ? Colors.green : Colors.red,
          ),
        ),
        title: Text(
          transaction.title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (transaction.description != null && transaction.description!.isNotEmpty)
              Text(transaction.description!),
            Text(
              dateFormat.format(transaction.date),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              currencyFormat.format(transaction.amount),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: transaction.isIncome ? Colors.green : Colors.red,
              ),
            ),
            if (transaction.category != null)
              Text(
                transaction.category!,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
          ],
        ),
      ),
    );
  }
} 