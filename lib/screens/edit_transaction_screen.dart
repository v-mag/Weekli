import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/transaction_provider.dart';
import '../models/transaction.dart' as model;
import '../theme/app_theme.dart';
import '../widgets/transaction_form_components.dart';

class EditTransactionScreen extends StatefulWidget {
  final model.Transaction transaction;

  const EditTransactionScreen({super.key, required this.transaction});

  @override
  State<EditTransactionScreen> createState() => _EditTransactionScreenState();
}

class _EditTransactionScreenState extends State<EditTransactionScreen> {
  final _titleController = TextEditingController();
  final _categoryController = TextEditingController();
  final List<TextEditingController> _amountControllers = [TextEditingController()];
  
  late model.TransactionType _transactionType;
  late DateTime _selectedDate;
  late model.RecurrenceType _recurrenceType;
  DateTime? _recurrenceEndDate;
  
  bool _isLoading = false;
  
  final GlobalKey<State<TransactionAmountInput>> _amountInputKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    final transaction = widget.transaction;
    
    // Initialize form fields
    _titleController.text = transaction.title;
    _categoryController.text = transaction.category ?? '';
    _amountControllers[0].text = transaction.amount.toString();
    
    _transactionType = transaction.type;
    _selectedDate = transaction.date;
    _recurrenceType = transaction.recurrenceType;
    _recurrenceEndDate = transaction.recurrenceEndDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _categoryController.dispose();
    for (var controller in _amountControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        final theme = Theme.of(context);
        return Theme(
          data: theme.copyWith(
            dialogBackgroundColor: theme.brightness == Brightness.light ? Colors.white : null,
            colorScheme: theme.colorScheme.copyWith(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
              onSurface: theme.colorScheme.onSurface,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primaryColor,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _showRecurrenceOptions() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Recurrence'),
        actions: model.RecurrenceType.values.map((type) {
          return CupertinoActionSheetAction(
            onPressed: () {
              setState(() => _recurrenceType = type);
              Navigator.of(context).pop();
              
              if (type != model.RecurrenceType.none) {
                _selectRecurrenceEndDate();
              } else {
                _recurrenceEndDate = null;
              }
            },
            child: Text(_getRecurrenceText(type)),
          );
        }).toList(),
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  void _selectRecurrenceEndDate() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 300,
        color: Colors.white,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    child: const Text('Cancel'),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  CupertinoButton(
                    child: const Text('Done'),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: _recurrenceEndDate ?? DateTime.now().add(const Duration(days: 30)),
                minimumDate: _selectedDate,
                onDateTimeChanged: (DateTime date) {
                  setState(() => _recurrenceEndDate = date);
                },
              ),
            ),
          ],
        ),
      ),
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

  bool _validateForm() {
    if (_titleController.text.trim().isEmpty) {
      _showErrorSnackBar('Please enter a title');
      return false;
    }
    
    if (_amountControllers[0].text.trim().isEmpty) {
      _showErrorSnackBar('Please enter an amount');
      return false;
    }
    
    return true;
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _saveTransaction() async {
    if (!_validateForm()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final amountInput = _amountInputKey.currentState! as dynamic;
      final totalAmount = amountInput.getTotalAmount() as double;
      
      final updatedTransaction = widget.transaction.copyWith(
        title: _titleController.text.trim(),
        description: null,
        amount: totalAmount,
        type: _transactionType,
        date: _selectedDate,
        category: _categoryController.text.isNotEmpty ? _categoryController.text : null,
        recurrenceType: _recurrenceType,
        recurrenceEndDate: _recurrenceEndDate,
      );
      
      await context.read<TransactionProvider>().updateTransaction(updatedTransaction);
      
      // Show success overlay
      _showSuccessOverlay();
      
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Failed to update transaction');
    }
  }

  void _showSuccessOverlay() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Container(
        color: Colors.black54,
        child: const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 64,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Transaction Updated!',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    // Auto dismiss after 1.5 seconds and navigate back
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        Navigator.of(context).pop(); // Close success dialog
        Navigator.of(context).pop(); // Go back to previous screen
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Edit Transaction'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          if (_recurrenceType != model.RecurrenceType.none)
            IconButton(
              onPressed: _showRecurrenceOptions,
              icon: const Icon(Icons.repeat),
            ),
          IconButton(
            onPressed: _isLoading ? null : _saveTransaction,
            icon: _isLoading 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.check),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Transaction Type Indicator
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _transactionType == model.TransactionType.income
                    ? AppTheme.incomeColor.withOpacity(0.1)
                    : AppTheme.expenseColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _transactionType == model.TransactionType.income
                      ? AppTheme.incomeColor
                      : AppTheme.expenseColor,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _transactionType == model.TransactionType.income
                        ? Icons.trending_up
                        : Icons.trending_down,
                    color: _transactionType == model.TransactionType.income
                        ? AppTheme.incomeColor
                        : AppTheme.expenseColor,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _transactionType == model.TransactionType.income ? 'Income' : 'Expense',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: _transactionType == model.TransactionType.income
                          ? AppTheme.incomeColor
                          : AppTheme.expenseColor,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Title Field
            Text(
              'Title',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: theme.colorScheme.onSurface),
            ),
            const SizedBox(height: 8),
            CupertinoTextField(
              controller: _titleController,
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
              placeholderStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5)),
            ),
            
            const SizedBox(height: 16),
            
            // Amount Field
            Text(
              'Amount',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: theme.colorScheme.onSurface),
            ),
            const SizedBox(height: 8),
            TransactionAmountInput(
              key: _amountInputKey,
              amountControllers: _amountControllers,
              allowMultiple: true,
            ),
            
            const SizedBox(height: 16),
            
            // Category Field
            Text(
              'Category',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: theme.colorScheme.onSurface),
            ),
            const SizedBox(height: 8),
            TransactionCategoryInput(
              controller: _categoryController,
              transactionType: _transactionType,
            ),
            
            const SizedBox(height: 16),
            
            // Date Field
            Text(
              'Date',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: theme.colorScheme.onSurface),
            ),
            const SizedBox(height: 8),
            TransactionDateInput(
              selectedDate: _selectedDate,
              onTap: _selectDate,
            ),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
} 