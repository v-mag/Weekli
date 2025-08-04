import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import '../../models/transaction.dart' as model;
import '../../theme/app_theme.dart';
import 'type_selection_step.dart';

class ConfirmationStep extends StatelessWidget {
  final TransactionMode transactionMode;
  final model.TransactionType transactionType;
  final String title;
  final double totalAmount;
  final String? category;
  final DateTime selectedDate;
  final model.RecurrenceType recurrenceType;
  final DateTime? recurrenceEndDate;
  final VoidCallback onSave;
  final VoidCallback onBack;

  const ConfirmationStep({
    super.key,
    required this.transactionMode,
    required this.transactionType,
    required this.title,
    required this.totalAmount,
    required this.category,
    required this.selectedDate,
    required this.recurrenceType,
    required this.recurrenceEndDate,
    required this.onSave,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            transactionMode == TransactionMode.budget 
                ? 'Review Budget Entry' 
                : 'Confirm Transaction',
            style: TextStyle(
              fontSize: 24, 
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 24),
          
          // Transaction details card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Transaction type badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: (transactionType == model.TransactionType.income
                            ? AppTheme.incomeColor
                            : AppTheme.expenseColor)
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: transactionType == model.TransactionType.income
                          ? AppTheme.incomeColor
                          : AppTheme.expenseColor,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        transactionType == model.TransactionType.income
                            ? Icons.trending_up
                            : Icons.trending_down,
                        size: 16,
                        color: transactionType == model.TransactionType.income
                            ? AppTheme.incomeColor
                            : AppTheme.expenseColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        transactionType == model.TransactionType.income 
                            ? 'Income' 
                            : 'Expense',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: transactionType == model.TransactionType.income
                              ? AppTheme.incomeColor
                              : AppTheme.expenseColor,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Title
                if (title.isNotEmpty) ...[
                  _buildDetailRow(context, 'Title', title),
                  const SizedBox(height: 12),
                ],
                
                // Amount
                _buildDetailRow(
                  context,
                  'Amount', 
                  currencyFormat.format(totalAmount),
                  valueColor: transactionType == model.TransactionType.income
                      ? AppTheme.incomeColor
                      : AppTheme.expenseColor,
                ),
                const SizedBox(height: 12),
                
                // Category
                if (category?.isNotEmpty == true) ...[
                  _buildDetailRow(context, 'Category', category!),
                  const SizedBox(height: 12),
                ],
                
                // Date
                _buildDetailRow(
                  context,
                  transactionMode == TransactionMode.budget ? 'Week' : 'Date',
                  transactionMode == TransactionMode.budget
                      ? _getWeekRangeText(selectedDate)
                      : DateFormat('MMM dd, yyyy').format(selectedDate),
                ),
                
                // Recurrence
                if (recurrenceType != model.RecurrenceType.none) ...[
                  const SizedBox(height: 12),
                  _buildDetailRow(context, 'Recurrence', _getRecurrenceText(recurrenceType)),
                  if (recurrenceEndDate != null) ...[
                    const SizedBox(height: 8),
                    _buildDetailRow(
                      context,
                      'Until', 
                      DateFormat('MMM dd, yyyy').format(recurrenceEndDate!),
                    ),
                  ],
                ],
              ],
            ),
          ),
          
          const Spacer(),
          
          // Action buttons
          Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: CupertinoButton(
                  onPressed: onSave,
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(12),
                  child: Text(
                    transactionMode == TransactionMode.budget 
                        ? 'Create Budget' 
                        : 'Add Transaction',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              )              
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value, {Color? valueColor}) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: theme.textTheme.bodyMedium?.color,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: valueColor ?? theme.colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }

  String _getRecurrenceText(model.RecurrenceType type) {
    switch (type) {
      case model.RecurrenceType.none:
        return 'None';
      case model.RecurrenceType.daily:
        return 'Daily';
      case model.RecurrenceType.weekly:
        return 'Weekly';
      case model.RecurrenceType.monthly:
        return 'Monthly';
      case model.RecurrenceType.yearly:
        return 'Yearly';
    }
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