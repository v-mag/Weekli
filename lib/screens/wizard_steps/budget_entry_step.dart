import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import '../../models/transaction.dart' as model;
import '../../widgets/transaction_form_components.dart';
import '../../theme/app_theme.dart';

class BudgetEntryStep extends StatelessWidget {
  final model.TransactionType transactionType;
  final TextEditingController categoryController;
  final List<TextEditingController> amountControllers;
  final DateTime selectedDate;
  final Function(BuildContext) onWeekTap;
  final VoidCallback onNext;

  const BudgetEntryStep({
    super.key,
    required this.transactionType,
    required this.categoryController,
    required this.amountControllers,
    required this.selectedDate,
    required this.onWeekTap,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Budget Details',
            style: TextStyle(
              fontSize: 24, 
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 24),
          
          // Expected Amount field (single input only)
          Text(
            'Expected Amount',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: theme.colorScheme.onSurface),
          ),
          const SizedBox(height: 8),
          TransactionAmountInput(
            amountControllers: amountControllers,
            allowMultiple: false, // Budget entries only allow single amount
          ),
          const SizedBox(height: 16),

          // Category field
          Text(
            'Category',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: theme.colorScheme.onSurface),
          ),
          const SizedBox(height: 8),
          TransactionCategoryInput(
            controller: categoryController,
            transactionType: transactionType,
          ),
          const SizedBox(height: 16),
          
          // Week field (custom week selector)
          Text(
            'Week',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: theme.colorScheme.onSurface),
          ),
          const SizedBox(height: 8),
          TransactionDateInput(
            selectedDate: selectedDate,
            onTap: () => onWeekTap(context),
            displayFormat: (date) => _getWeekRangeText(date),
            label: 'Week',
          ),
          const SizedBox(height: 32),
          
          // Next button
          SizedBox(
            width: double.infinity,
            child: CupertinoButton(
              onPressed: onNext,
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(12),
              child: const Text(
                'Set Budget',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getWeekRangeText(DateTime date) {
    final weekStart = _getWeekStart(date);
    final weekEnd = weekStart.add(const Duration(days: 6));
    return '${DateFormat('MMM dd').format(weekStart)} - ${DateFormat('MMM dd, yyyy').format(weekEnd)}';
  }

  DateTime _getWeekStart(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }
} 