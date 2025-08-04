import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../providers/transaction_provider.dart';
import '../models/transaction.dart' as model;
import '../theme/app_theme.dart';
import 'edit_transaction_screen.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  String _filterType = 'All';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            color: Theme.of(context).brightness == Brightness.light
                ? Colors.white
                : null,
            onSelected: (value) {
              setState(() {
                _filterType = value;
              });
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                  value: 'All',
                  child: Text('All',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface))),
              PopupMenuItem(
                  value: 'Income',
                  child: Text('Income',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface))),
              PopupMenuItem(
                  value: 'Expense',
                  child: Text('Expense',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface))),
            ],
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_filterType),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Consumer<TransactionProvider>(
        builder: (context, provider, child) {
          List<model.Transaction> filteredTransactions = provider.transactions;

          if (_filterType == 'Income') {
            filteredTransactions = provider.transactions
                .where((t) => t.type == model.TransactionType.income)
                .toList();
          } else if (_filterType == 'Expense') {
            filteredTransactions = provider.transactions
                .where((t) => t.type == model.TransactionType.expense)
                .toList();
          }

          if (filteredTransactions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No transactions found',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap the + button to add your first transaction',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            );
          }

          // Group transactions by date
          final Map<String, List<model.Transaction>> groupedTransactions = {};
          for (final transaction in filteredTransactions) {
            final dateKey = DateFormat('yyyy-MM-dd').format(transaction.date);
            if (!groupedTransactions.containsKey(dateKey)) {
              groupedTransactions[dateKey] = [];
            }
            groupedTransactions[dateKey]!.add(transaction);
          }

          final sortedDates = groupedTransactions.keys.toList()
            ..sort((a, b) => b.compareTo(a)); // Sort in descending order

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: sortedDates.length,
            itemBuilder: (context, index) {
              final dateKey = sortedDates[index];
              final transactions = groupedTransactions[dateKey]!;
              final date = DateTime.parse(dateKey);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDateHeader(date, transactions),
                  ...transactions.map((transaction) =>
                      _buildTransactionTile(context, transaction, provider)),
                  const SizedBox(height: 8),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildDateHeader(DateTime date, List<model.Transaction> transactions) {
    final dateFormat = DateFormat('EEEE, MMM dd, yyyy');
    final currencyFormat = NumberFormat.currency(symbol: '\$');

    final totalIncome = transactions
        .where((t) => t.type == model.TransactionType.income)
        .fold(0.0, (sum, t) => sum + t.amount);

    final totalExpense = transactions
        .where((t) => t.type == model.TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);

    final balance = totalIncome - totalExpense;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            dateFormat.format(date),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (totalIncome > 0)
                Text(
                  '+${currencyFormat.format(totalIncome)}',
                  style: const TextStyle(
                    color: Colors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              if (totalExpense > 0)
                Text(
                  '-${currencyFormat.format(totalExpense)}',
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              if (balance != 0)
                Text(
                  currencyFormat.format(balance),
                  style: TextStyle(
                    color: balance >= 0 ? Colors.green : Colors.red,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionTile(
    BuildContext context,
    model.Transaction transaction,
    TransactionProvider provider,
  ) {
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    final timeFormat = DateFormat('HH:mm');

    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.0),
        child: Slidable(
          key: ValueKey(transaction.id),
          endActionPane: ActionPane(
            motion: const ScrollMotion(),
            children: [
              Theme(
                data: Theme.of(context).copyWith(
                    outlinedButtonTheme: const OutlinedButtonThemeData(
                        style: ButtonStyle(
                            iconColor: WidgetStatePropertyAll(Colors.white)))),
                child: SlidableAction(
                    onPressed: (context) =>
                        _navigateToEditTransaction(context, transaction),
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    icon: Icons.edit),
              ),
              Theme(
                  data: Theme.of(context).copyWith(
                      outlinedButtonTheme: const OutlinedButtonThemeData(
                          style: ButtonStyle(
                              iconColor:
                                  WidgetStatePropertyAll(Colors.white)))),
                  child: SlidableAction(
                      onPressed: (context) => _showDeleteConfirmation(
                          context, transaction, provider),
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      icon: Icons.delete)),
            ],
          ),
          child: Card(
            margin: EdgeInsets.zero,
            shape:
                const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: transaction.isIncome
                    ? Colors.green.withOpacity(0.1)
                    : Colors.red.withOpacity(0.1),
                child: Icon(
                  transaction.isIncome
                      ? Icons.trending_up
                      : Icons.trending_down,
                  color: transaction.isIncome ? Colors.green : Colors.red,
                ),
              ),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      transaction.title,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  if (transaction.isRecurrent)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getRecurrenceText(transaction.recurrenceType),
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.blue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (transaction.description?.isNotEmpty == true)
                    Text(transaction.description!),
                  Row(
                    children: [
                      if (transaction.category != null) ...[
                        Text(
                          transaction.category!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              trailing: Text(
                currencyFormat.format(transaction.amount),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: transaction.isIncome ? Colors.green : Colors.red,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getRecurrenceText(model.RecurrenceType type) {
    switch (type) {
      case model.RecurrenceType.daily:
        return 'Daily';
      case model.RecurrenceType.weekly:
        return 'Weekly';
      case model.RecurrenceType.monthly:
        return 'Monthly';
      case model.RecurrenceType.yearly:
        return 'Yearly';
      default:
        return '';
    }
  }

  void _showDeleteConfirmation(
    BuildContext context,
    model.Transaction transaction,
    TransactionProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Transaction'),
          content:
              Text('Are you sure you want to delete "${transaction.title}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                provider.deleteTransaction(transaction.id!);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Transaction deleted')),
                );
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _navigateToEditTransaction(
      BuildContext context, model.Transaction transaction) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EditTransactionScreen(transaction: transaction),
      ),
    );
  }
}
