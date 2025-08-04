import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import '../../models/transaction.dart' as model;
import '../../widgets/transaction_form_components.dart';
import '../../theme/app_theme.dart';
import 'type_selection_step.dart';

class ManualEntryStep extends StatelessWidget {
  final TransactionMode transactionMode;
  final model.TransactionType transactionType;
  final TextEditingController titleController;
  final TextEditingController categoryController;
  final List<TextEditingController> amountControllers;
  final DateTime selectedDate;
  final VoidCallback onDateTap;
  final VoidCallback onNext;

  const ManualEntryStep({
    super.key,
    required this.transactionMode,
    required this.transactionType,
    required this.titleController,
    required this.categoryController,
    required this.amountControllers,
    required this.selectedDate,
    required this.onDateTap,
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
          // Title field - only for actual transactions
          if (transactionMode == TransactionMode.actual) ...[
            Text(
              'Title',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: theme.colorScheme.onSurface),
            ),
            const SizedBox(height: 8),
            CupertinoTextField(
              controller: titleController,
              placeholder: 'Enter transaction title',
              maxLength: 64,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.inputDecorationTheme.fillColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.inputDecorationTheme.enabledBorder?.borderSide.color ?? theme.dividerColor,
                  width: 1.0,
                ),
              ),
              style: TextStyle(color: theme.colorScheme.onSurface),
              placeholderStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.4)),
            ),
            const SizedBox(height: 16),
          ],
          
          // Amount field with display total for multiple amounts
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (amountControllers.length > 1)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    'Total: \$${_getTotalAmount().toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: theme.primaryColor,
                    ),
                  ),
                ),
            ],
          ),
          Text(
            'Amount',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: theme.colorScheme.onSurface),
          ),
          const SizedBox(height: 8),
          TransactionAmountInput(
            amountControllers: amountControllers,
            allowMultiple: transactionMode == TransactionMode.actual,
          ),

          // Category field
          const SizedBox(height: 16),
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
                  
          // Date field
          Text(
            'Date',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: theme.colorScheme.onSurface),
          ),
          const SizedBox(height: 8),
          TransactionDateInput(
            selectedDate: selectedDate,
            onTap: onDateTap,
          ),
          const SizedBox(height: 32),
          
          // Next button
          SizedBox(
            width: double.infinity,
            child: CupertinoButton(
              onPressed: onNext,
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(12),
              child: Text(
                transactionMode == TransactionMode.budget ? 'Set Budget' : 'Continue',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _getTotalAmount() {
    return amountControllers.fold(0.0, (sum, controller) {
      return sum + (double.tryParse(controller.text) ?? 0.0);
    });
  }
} 