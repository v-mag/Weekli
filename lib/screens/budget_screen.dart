import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../models/category_budget.dart';
import '../models/transaction.dart' as model;
import '../providers/transaction_provider.dart';
import '../theme/app_theme.dart';
import '../screens/add_transaction_wizard.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  // Remove the empty list as we'll use the provider's data
  DateTime _currentWeekStart = _getWeekStart(DateTime.now());

  static DateTime _getWeekStart(DateTime date) {
    // Normalize date to midnight to ensure consistent calculations
    final normalizedDate = DateTime(date.year, date.month, date.day);
    // In Dart, Monday is 1 and Sunday is 7.
    return normalizedDate.subtract(Duration(days: normalizedDate.weekday - 1));
  }

  @override
  void initState() {
    super.initState();
    // Load category budgets when the screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TransactionProvider>().loadCategoryBudgets();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Budgets'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Consumer<TransactionProvider>(
        builder: (context, provider, child) {
          final budgetSummaries = _getBudgetSummaries(provider);
          
          return Column(
            children: [
              // Week Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: theme.cardColor,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.navigate_before),
                          onPressed: () {
                            setState(() {
                              _currentWeekStart = _currentWeekStart.subtract(const Duration(days: 7));
                            });
                          },
                          color: theme.brightness == Brightness.dark ? Colors.white : AppTheme.primaryColor,
                        ),
                        Expanded(
                          child: Text(
                            'Week of ${DateFormat('MMM dd, yyyy').format(_currentWeekStart)}',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.navigate_next),
                          onPressed: () {
                            setState(() {
                              _currentWeekStart = _currentWeekStart.add(const Duration(days: 7));
                            });
                          },
                          color: theme.brightness == Brightness.dark ? Colors.white : AppTheme.primaryColor,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${DateFormat('MMM dd').format(_currentWeekStart)} - ${DateFormat('MMM dd').format(_currentWeekStart.add(const Duration(days: 6)))}',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              
              // Budget Categories
              Expanded(
                child: budgetSummaries.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.pie_chart_outline,
                              size: 64,
                              color: AppTheme.secondaryTextColor.withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No budgets set for this week',
                              style: TextStyle(
                                fontSize: 18,
                                color: AppTheme.secondaryTextColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Use "Budget Entry" when adding transactions\nto set category expectations',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppTheme.secondaryTextColor,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: budgetSummaries.length,
                        itemBuilder: (context, index) {
                          return _buildBudgetCard(budgetSummaries[index], provider);
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/add-transaction');
        },
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  List<CategoryBudgetSummary> _getBudgetSummaries(TransactionProvider provider) {
    final weekEnd = _currentWeekStart.add(const Duration(days: 7));
    final weekTransactions = provider.transactions.where((t) {
      return !t.date.isBefore(_currentWeekStart) && t.date.isBefore(weekEnd);
    }).toList();

    final summaries = <CategoryBudgetSummary>[];
    
    for (final budget in provider.getCategoryBudgetsByWeek(_currentWeekStart)) {
      
      final categoryTransactions = weekTransactions
          .where((t) => t.category?.toLowerCase() == budget.category.toLowerCase() && 
                       t.type == budget.type)
          .toList();
      
      final actualAmount = categoryTransactions.fold(0.0, (sum, t) => sum + t.amount);
      
      summaries.add(CategoryBudgetSummary(
        budget: budget,
        actualAmount: actualAmount,
        transactionCount: categoryTransactions.length,
      ));
    }
    
    return summaries;
  }

  Widget _buildBudgetCard(CategoryBudgetSummary summary, TransactionProvider provider) {
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    final budget = summary.budget;
    final theme = Theme.of(context);
    final progressColor = budget.type == model.TransactionType.income
        ? AppTheme.incomeColor
        : (summary.isOverBudget
            ? AppTheme.expenseColor
            : (theme.brightness == Brightness.dark
                ? Colors.white
                : AppTheme.primaryColor));

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.0),
        child: Slidable(
          key: ValueKey(budget.id),
          startActionPane: ActionPane(
            motion: const ScrollMotion(),
            children: [
              Theme(
                data: Theme.of(context).copyWith(
                  outlinedButtonTheme: const OutlinedButtonThemeData(
                    style: ButtonStyle(
                      iconColor: WidgetStatePropertyAll(Colors.white)
                    )
                  )
                ),
                child: SlidableAction(
                  onPressed: (context) => _navigateToAddTransaction(context, budget),
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                  icon: Icons.add_circle_outline,
                ),
              ),
            ],
          ),
          endActionPane: ActionPane(
            motion: const ScrollMotion(),
            children: [
              Theme(data: Theme.of(context).copyWith(
                outlinedButtonTheme: const OutlinedButtonThemeData(
                    style: ButtonStyle(
                        iconColor: WidgetStatePropertyAll(Colors.white)))),
                child: SlidableAction(
                    onPressed: (context) => _showEditBudget(context, budget, provider),
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    icon: Icons.edit),
              ),
              Theme(data: Theme.of(context).copyWith(
                  outlinedButtonTheme: const OutlinedButtonThemeData(
                      style: ButtonStyle(
                          iconColor: WidgetStatePropertyAll(Colors.white)))),
                  child: SlidableAction(
                      onPressed: (context) => _showDeleteBudgetConfirmation(context, budget, provider),
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      icon: Icons.delete)),
            ],
          ),
          child: Card(
            margin: EdgeInsets.zero,
            elevation: 2,
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: (budget.type == model.TransactionType.income
                                  ? AppTheme.incomeColor
                                  : AppTheme.expenseColor)
                                .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          budget.type == model.TransactionType.income
                              ? Icons.trending_up
                              : Icons.trending_down,
                          color: budget.type == model.TransactionType.income
                              ? AppTheme.incomeColor
                              : AppTheme.expenseColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              budget.category,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            Text(
                              '${summary.transactionCount} transaction${summary.transactionCount != 1 ? 's' : ''}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            currencyFormat.format(summary.actualAmount),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: progressColor,
                            ),
                          ),
                          Text(
                            'of ${currencyFormat.format(budget.expectedAmount)}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Progress Bar
                  Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _getProgressText(summary),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: summary.isOverBudget
                                  ? (budget.type == model.TransactionType.income
                                      ? AppTheme.incomeColor
                                      : AppTheme.expenseColor)
                                  : Theme.of(context).textTheme.bodyMedium?.color,
                            ),
                          ),
                          if (summary.remainingAmount > 0 && !summary.isOverBudget)
                            Text(
                              '${currencyFormat.format(summary.remainingAmount)} left',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      LinearProgressIndicator(
                        value: summary.isOverBudget ? 1.0 : summary.progressPercentage,
                        backgroundColor: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey.shade800
                            : Colors.grey.shade300,
                        valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                        minHeight: 6,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showEditBudget(
    BuildContext context,
    CategoryBudget budget,
    TransactionProvider provider,
  ) {
    final amountController = TextEditingController(text: budget.expectedAmount.toString());
    final categoryController = TextEditingController(text: budget.category);
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Budget'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: categoryController,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                decoration: const InputDecoration(
                  labelText: 'Expected Amount',
                  border: OutlineInputBorder(),
                  prefixText: '\$',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final updatedBudget = budget.copyWith(
                  category: categoryController.text.trim(),
                  expectedAmount: double.tryParse(amountController.text) ?? budget.expectedAmount,
                );
                
                provider.updateCategoryBudget(updatedBudget);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Budget updated')),
                );
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteBudgetConfirmation(
    BuildContext context,
    CategoryBudget budget,
    TransactionProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Budget'),
          content: Text('Are you sure you want to delete the budget for "${budget.category}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                provider.deleteCategoryBudget(budget.id!);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Budget deleted')),
                );
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _navigateToAddTransaction(BuildContext context, CategoryBudget budget) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddTransactionWizard(
          initialCategory: budget.category,
          initialTransactionType: budget.type,
        ),
      ),
    );
  }

  String _getProgressText(CategoryBudgetSummary summary) {
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    if (summary.isOverBudget) {
      final overAmount = summary.actualAmount - summary.budget.expectedAmount;
      return '${currencyFormat.format(overAmount)} over';
    }
    
    final percentage = (summary.progressPercentage * 100).toInt();
    
    if (summary.budget.type == model.TransactionType.income) {
      return '$percentage% achieved';
    } else {
      return '$percentage% used';
    }
  }
} 