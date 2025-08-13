import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/transaction_provider.dart';
import '../models/transaction.dart' as model;
import '../models/category_budget.dart';
import '../theme/app_theme.dart';
import 'wizard_steps/type_selection_step.dart';
import 'wizard_steps/manual_entry_step.dart';
import 'wizard_steps/confirmation_step.dart';
import 'wizard_steps/budget_entry_step.dart';

// Button states for confirmation step
enum ButtonState { normal, loading, confirmed }

class AddTransactionWizard extends StatefulWidget {
  final String? initialCategory;
  final model.TransactionType? initialTransactionType;

  const AddTransactionWizard({
    super.key,
    this.initialCategory,
    this.initialTransactionType,
  });

  @override
  State<AddTransactionWizard> createState() => _AddTransactionWizardState();
}

class _AddTransactionWizardState extends State<AddTransactionWizard> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  // Dynamic total steps based on transaction mode
  int get _totalSteps {
    if (_transactionMode == null) return 1;
    return _transactionMode == TransactionMode.budget ? 4 : 4;
  }

  // Transaction data
  model.TransactionType _transactionType = model.TransactionType.income;
  TransactionMode? _transactionMode;

  final _titleController = TextEditingController();
  final _categoryController = TextEditingController();
  
  // Amount controllers for multiple amounts
  final List<TextEditingController> _amountControllers = [TextEditingController()];
  
  DateTime _selectedDate = DateTime.now();
  model.RecurrenceType _recurrenceType = model.RecurrenceType.none;
  DateTime? _recurrenceEndDate;
  
  @override
  void initState() {
    super.initState();
    if (widget.initialCategory != null && widget.initialTransactionType != null) {
      _transactionMode = TransactionMode.actual;
      _transactionType = widget.initialTransactionType!;
      _categoryController.text = widget.initialCategory!;
      _currentStep = 1;
      
      // Use a post-frame callback to safely transition after the first frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _pageController.jumpToPage(1);
      });
    }
  }

  // Loading screen state
  bool _showSuccessCheck = false;

  @override
  void dispose() {
    _pageController.dispose();
    _titleController.dispose();
    _categoryController.dispose();
    
    // Dispose all amount controllers
    for (var controller in _amountControllers) {
      controller.dispose();
    }
    
    super.dispose();
  }

  List<Widget> _buildPages() {
    if (_transactionMode == null) {
      return [
        TypeSelectionStep(
          selectedMode: _transactionMode,
          onModeSelected: (mode) {
            setState(() {
              _transactionMode = mode;
              if (mode == TransactionMode.budget) {
                _selectedDate = _getWeekStart(DateTime.now());
              } else {
                _selectedDate = DateTime.now();
              }
            });
            _showTransactionTypeSelector();
          },
        ),
      ];
    } else if (_transactionMode == TransactionMode.budget) {
      return [
        TypeSelectionStep(
          selectedMode: _transactionMode,
          onModeSelected: (mode) {
            setState(() {
              _transactionMode = mode;
              if (mode == TransactionMode.budget) {
                _selectedDate = _getWeekStart(DateTime.now());
              } else {
                _selectedDate = DateTime.now();
              }
            });
            _showTransactionTypeSelector();
          },
        ),
        BudgetEntryStep(
          transactionType: _transactionType,
          categoryController: _categoryController,
          amountControllers: _amountControllers,
          selectedDate: _selectedDate,
          onWeekTap: _selectWeek,
          onNext: _validateBudgetAndNext,
        ),
        ConfirmationStep(
          transactionMode: _transactionMode!,
          transactionType: _transactionType,
          title: _titleController.text.trim(),
          totalAmount: _getTotalAmount(),
          category: _categoryController.text.isNotEmpty ? _categoryController.text : null,
          selectedDate: _selectedDate,
          recurrenceType: _recurrenceType,
          recurrenceEndDate: _recurrenceEndDate,
          onSave: _saveTransaction,
          onBack: _previousStep,
        ),
        _buildLoadingStep(),
      ];
    } else {
      return [
        TypeSelectionStep(
          selectedMode: _transactionMode,
          onModeSelected: (mode) {
            setState(() {
              _transactionMode = mode;
              if (mode == TransactionMode.budget) {
                _selectedDate = _getWeekStart(DateTime.now());
              } else {
                _selectedDate = DateTime.now();
              }
            });
            _showTransactionTypeSelector();
          },
        ),
        ManualEntryStep(
          transactionMode: _transactionMode!,
          transactionType: _transactionType,
          titleController: _titleController,
          categoryController: _categoryController,
          amountControllers: _amountControllers,
          selectedDate: _selectedDate,
          onDateTap: _selectDate,
          onNext: _validateAndNext,
        ),
        ConfirmationStep(
          transactionMode: _transactionMode!,
          transactionType: _transactionType,
          title: _titleController.text.trim(),
          totalAmount: _getTotalAmount(),
          category: _categoryController.text.isNotEmpty ? _categoryController.text : null,
          selectedDate: _selectedDate,
          recurrenceType: _recurrenceType,
          recurrenceEndDate: _recurrenceEndDate,
          onSave: _saveTransaction,
          onBack: _previousStep,
        ),
        _buildLoadingStep(),
      ];
    }
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      setState(() {
        _currentStep++;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  String _getAppBarTitle() {
    if (_transactionMode == null || _currentStep == 0) {
      return 'Add Entry';
    } else if (_transactionMode == TransactionMode.budget) {
      return 'Add Budget Entry';
    } else {
      return 'Add Transaction';
    }
  }


  @override
  Widget build(BuildContext context) {
    final double progressValue = _totalSteps <= 1 ? 0.0 : _currentStep / (_totalSteps - 1);

    return Scaffold(
      appBar: AppBar(
        title: Text(_getAppBarTitle()),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        leading: _currentStep > 0
            ? IconButton(
                icon: Icon(Icons.adaptive.arrow_back),
                onPressed: _previousStep,
              )
            : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress indicator
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              border: Border(
                bottom: BorderSide(color: Theme.of(context).dividerColor, width: 0.5),
              ),
            ),
            child: LinearProgressIndicator(
              value: progressValue,
              backgroundColor: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey.shade800
                  : Colors.grey.shade300,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppTheme.primaryColor,
              ),
            ),
          ),
          
          // Page content
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: _buildPages(),
            ),
          ),
        ],
      ),
    );
  }



  void _showTransactionTypeSelector() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return Material(
          color: Colors.transparent,
          child: Container(
            height: 300,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Column(
              children: [
                Text(
                  _transactionMode == TransactionMode.actual 
                      ? 'Transaction Type' 
                      : 'Budget Type',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 20),
                
                // Income Option
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                                      setState(() {
                    _transactionType = model.TransactionType.income;
                    // Force rebuild of pages when transaction type changes
                    _currentStep = _currentStep;
                  });
                  Navigator.pop(context);
                  _nextStep();
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.incomeColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.incomeColor),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.trending_up, color: AppTheme.incomeColor),
                          const SizedBox(width: 12),
                          Text(
                            _transactionMode == TransactionMode.actual ? 'Income' : 'Expected Income',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Expense Option
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                                      setState(() {
                    _transactionType = model.TransactionType.expense;
                    // Force rebuild of pages when transaction type changes
                    _currentStep = _currentStep;
                  });
                  Navigator.pop(context);
                  _nextStep();
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.expenseColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.expenseColor),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.trending_down, color: AppTheme.expenseColor),
                          const SizedBox(width: 12),
                          Text(
                            _transactionMode == TransactionMode.actual ? 'Expense' : 'Expected Expense',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }


  Widget _buildLoadingStep() {
    return Container(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          
          // Loading animation area
          SizedBox(
            width: 120,
            height: 120,
                         child: AnimatedSwitcher(
               duration: const Duration(milliseconds: 600),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return ScaleTransition(
                  scale: animation,
                  child: FadeTransition(
                    opacity: animation,
                    child: child,
                  ),
                );
              },
              child: _showSuccessCheck
                  ? Container(
                      key: const ValueKey('success'),
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: AppTheme.incomeColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.incomeColor.withValues(alpha: 0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 60,
                      ),
                    )
                  : Container(
                      key: const ValueKey('loading'),
                      width: 120,
                      height: 120,
                      padding: const EdgeInsets.all(30),
                      child: CircularProgressIndicator(
                        strokeWidth: 6,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppTheme.primaryColor,
                        ),
                      ),
                    ),
            ),
          ),
          
          const SizedBox(height: 32),
          
                     // Status text
           AnimatedSwitcher(
             duration: const Duration(milliseconds: 400),
            child: Text(
              _showSuccessCheck 
                  ? (_transactionMode == TransactionMode.budget ? 'Budget Created!' : 'Transaction Added!')
                  : (_transactionMode == TransactionMode.budget ? 'Creating Budget...' : 'Adding Transaction...'),
              key: ValueKey(_showSuccessCheck),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _showSuccessCheck 
                    ? AppTheme.incomeColor 
                    : Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          const SizedBox(height: 8),
          
          Text(
            _showSuccessCheck 
                ? 'Redirecting to dashboard...' 
                : (_transactionMode == TransactionMode.budget 
                    ? 'Please wait while we create your budget entry'
                    : 'Please wait while we process your transaction'),
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
            textAlign: TextAlign.center,
          ),
          
          const Spacer(),
        ],
      ),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        final theme = Theme.of(context);
        return Theme(
          data: Theme.of(context).copyWith(
            dialogBackgroundColor: theme.brightness == Brightness.light ? Colors.white : null,
            colorScheme: theme.colorScheme.copyWith(
              primary: AppTheme.primaryColor, // header background color
              onPrimary: Colors.white, // header text color
              onSurface: theme.colorScheme.onSurface, // body text color
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primaryColor, // button text color
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

  // Budget-specific helper methods
  Future<void> _selectWeek(BuildContext context) async {
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
    if (picked != null) {
      setState(() {
        _selectedDate = _getWeekStart(picked);
      });
    }
  }

  DateTime _getWeekStart(DateTime date) {
    int daysFromMonday = date.weekday - 1;
    return date.subtract(Duration(days: daysFromMonday));
  }

  void _validateBudgetAndNext() {
    final amount = double.tryParse(_amountControllers[0].text) ?? 0;
    
    if (amount <= 0 || _categoryController.text.trim().isEmpty) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Missing Information'),
          content: const Text('Please fill in the expected amount and category.'),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
      return;
    }
    
    _nextStep();
  }

  void _validateAndNext() {
    final totalAmount = _getTotalAmount();
    
    // For budget entries, title is not required
    bool titleRequired = _transactionMode == TransactionMode.actual;
    bool missingTitle = titleRequired && _titleController.text.trim().isEmpty;
    
    if (missingTitle ||
        totalAmount <= 0 ||
        _categoryController.text.trim().isEmpty ||
        _amountControllers.any((controller) => 
          controller.text.trim().isNotEmpty && 
          (double.tryParse(controller.text) == null || double.tryParse(controller.text)! <= 0))) {
      
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Missing Information'),
          content: const Text('Please fill in all required fields with valid values.'),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
      return;
    }
    
    _nextStep();
  }

  Future<void> _saveTransaction() async {
    // Navigate to loading step
    _nextStep();
    
    try {
      // Show loading circle for 1.2 seconds
      await Future.delayed(const Duration(milliseconds: 1200));
      
      // Show success check
      if (mounted) {
        setState(() {
          _showSuccessCheck = true;
        });
        
        // Add haptic feedback
        HapticFeedback.mediumImpact();
      }
      
      if (_transactionMode == TransactionMode.budget) {
        // Handle budget entry creation
        await _saveBudgetEntry();
      } else {
        // Handle regular transaction creation
        await _saveRegularTransaction();
      }
      
      // Wait additional 1.5 seconds to show success, then navigate to dashboard
      await Future.delayed(const Duration(milliseconds: 1500));
      
      if (mounted) {
        // Navigate back to dashboard (HomeScreen)
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        // Reset state and go back to confirmation step on error
        setState(() {
          _showSuccessCheck = false;
        });
        _previousStep();
        
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Error'),
            content: Text('Failed to save ${_transactionMode == TransactionMode.budget ? 'budget entry' : 'transaction'}: $e'),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _saveRegularTransaction() async {
    final transaction = model.Transaction(
      title: _titleController.text.trim(),
      description: null,
      amount: _getTotalAmount(),
      type: _transactionType,
      date: _selectedDate,
      category: _categoryController.text.isNotEmpty ? _categoryController.text : null,
      recurrenceType: _recurrenceType,
      recurrenceEndDate: _recurrenceEndDate,
    );

    await context.read<TransactionProvider>().addTransaction(transaction);
  }

  Future<void> _saveBudgetEntry() async {
    final categoryBudget = CategoryBudget(
      category: _categoryController.text.trim(),
      expectedAmount: double.parse(_amountControllers[0].text),
      type: _transactionType,
      weekStartDate: _getWeekStart(_selectedDate),
      createdAt: DateTime.now(),
    );

    await context.read<TransactionProvider>().addCategoryBudget(categoryBudget);
  }

  double _getTotalAmount() {
    double total = 0.0;
    for (var controller in _amountControllers) {
      if (controller.text.trim().isNotEmpty) {
        total += double.tryParse(controller.text) ?? 0.0;
      }
    }
    return total;
  }
}

class _RecurrencePopup extends StatefulWidget {
  final model.RecurrenceType currentType;
  final DateTime? endDate;
  final Function(model.RecurrenceType, DateTime?) onRecurrenceChanged;

  const _RecurrencePopup({
    required this.currentType,
    required this.endDate,
    required this.onRecurrenceChanged,
  });

  @override
  State<_RecurrencePopup> createState() => _RecurrencePopupState();
}

class _RecurrencePopupState extends State<_RecurrencePopup> {
  late model.RecurrenceType _selectedType;
  DateTime? _selectedEndDate;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.currentType;
    _selectedEndDate = widget.endDate;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 400,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          const Text(
            'Recurrence Settings',
            style: TextStyle(
              fontSize: 20, 
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryTextColor,
            ),
          ),
          const SizedBox(height: 20),
          
          Expanded(
            child: CupertinoPicker(
              itemExtent: 40,
              onSelectedItemChanged: (index) {
                setState(() {
                  _selectedType = model.RecurrenceType.values[index];
                });
              },
              children: model.RecurrenceType.values.map((type) {
                return Center(
                  child: Text(
                    _getRecurrenceText(type),
                    style: const TextStyle(color: AppTheme.primaryTextColor),
                  ),
                );
              }).toList(),
            ),
          ),
          
          if (_selectedType != model.RecurrenceType.none) ...[
            const SizedBox(height: 16),
            CupertinoButton(
              onPressed: () => _selectEndDate(),
              child: Text(
                _selectedEndDate != null
                    ? 'End Date: ${DateFormat('MMM dd, yyyy').format(_selectedEndDate!)}'
                    : 'Set End Date (Optional)',
              ),
            ),
          ],
          
          const SizedBox(height: 20),
          
          Row(
            children: [
              Expanded(
                child: CupertinoButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ),
              Expanded(
                child: CupertinoButton(
                  onPressed: () {
                    widget.onRecurrenceChanged(_selectedType, _selectedEndDate);
                    Navigator.pop(context);
                  },
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(12),
                  child: const Text(
                    'Save',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _selectEndDate() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 250,
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: CupertinoDatePicker(
          mode: CupertinoDatePickerMode.date,
          initialDateTime: _selectedEndDate ?? DateTime.now().add(const Duration(days: 30)),
          minimumDate: DateTime.now(),
          onDateTimeChanged: (date) {
            setState(() {
              _selectedEndDate = date;
            });
          },
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
} 