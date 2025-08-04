import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../providers/transaction_provider.dart';
import '../models/transaction.dart' as model;
import '../models/category_budget.dart';
import '../theme/app_theme.dart';
import '../widgets/transaction_form_components.dart';
import 'wizard_steps/type_selection_step.dart';
import 'wizard_steps/manual_entry_step.dart';
import 'wizard_steps/confirmation_step.dart';
import 'wizard_steps/budget_entry_step.dart';

// Button states for confirmation step
enum ButtonState { normal, loading, confirmed }

class AddTransactionWizard extends StatefulWidget {
  const AddTransactionWizard({super.key});

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

  File? _receiptImage;
  
  final _titleController = TextEditingController();
  final _categoryController = TextEditingController();
  
  // Amount controllers for multiple amounts
  final List<TextEditingController> _amountControllers = [TextEditingController()];
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  
  DateTime _selectedDate = DateTime.now();
  model.RecurrenceType _recurrenceType = model.RecurrenceType.none;
  DateTime? _recurrenceEndDate;
  ButtonState _buttonState = ButtonState.normal;
  
  // Loading screen state
  bool _showSuccessCheck = false;

  final List<String> _incomeCategories = [
    'Salary',
    'Freelance',
    'Investment',
    'Business',
    'Gift',
    'Other Income',
  ];

  final List<String> _expenseCategories = [
    'Food & Dining',
    'Transportation',
    'Shopping',
    'Entertainment',
    'Bills & Utilities',
    'Healthcare',
    'Education',
    'Travel',
    'Groceries',
    'Rent',
    'Other Expense',
  ];



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

  void _showRecurrenceOptions() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => _RecurrencePopup(
        currentType: _recurrenceType,
        endDate: _recurrenceEndDate,
        onRecurrenceChanged: (type, endDate) {
          setState(() {
            _recurrenceType = type;
            _recurrenceEndDate = endDate;
          });
        },
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source);
    
    if (image != null) {
      setState(() {
        _receiptImage = File(image.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final double progressValue = _totalSteps <= 1 ? 0.0 : _currentStep / (_totalSteps - 1);
    final theme = Theme.of(context);

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

  Widget _buildTypeSelectionStep() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'What type of entry?',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 32),
          
          // Actual Transaction Card
          _buildSelectionCard(
            title: 'Actual Transaction',
            subtitle: 'Record a real transaction that happened',
            icon: Icons.receipt_long,
            color: AppTheme.primaryColor,
            isSelected: _transactionMode == TransactionMode.actual,
            onTap: () {
              setState(() {
                _transactionMode = TransactionMode.actual;
              });
              _showTransactionTypeSelector();
            },
          ),
          
          const SizedBox(height: 16),
          
          // Budget Entry Card
          _buildSelectionCard(
            title: 'Budget Entry',
            subtitle: 'Set expected amount for a category this week',
            icon: Icons.trending_up,
            color: AppTheme.primaryColor,
            isSelected: _transactionMode == TransactionMode.budget,
            onTap: () {
              setState(() {
                _transactionMode = TransactionMode.budget;
                // Initialize to current week start for budget entries
                _selectedDate = _getWeekStart(DateTime.now());
              });
              _showTransactionTypeSelector();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : AppTheme.backgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : AppTheme.borderColor,
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppTheme.secondaryTextColor,
                    ),
                  ),
                ],
              ),
            ),

          ],
        ),
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
                        color: AppTheme.incomeColor.withOpacity(0.1),
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
                        color: AppTheme.expenseColor.withOpacity(0.1),
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

  Widget _buildInputMethodStep() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'How would you like to add this transaction?',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          
          // Manual entry option
          GestureDetector(
            onTap: () {
              // Manual entry selected
              _nextStep();
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.primaryBlue, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryBlue.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Column(
                children: [
                  Icon(Icons.edit, color: AppTheme.primaryBlue, size: 48),
                  SizedBox(height: 12),
                  Text(
                    'Manual Entry',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                  Text(
                    'Fill in the details yourself',
                    style: TextStyle(color: AppTheme.secondaryTextColor),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Automatic with photo option
          GestureDetector(
            onTap: () {
              // Receipt capture selected
              _pickImage(ImageSource.camera);
              _nextStep();
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.primaryPurple, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryPurple.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Column(
                children: [
                  Icon(Icons.camera_alt, color: AppTheme.primaryPurple, size: 48),
                  SizedBox(height: 12),
                  Text(
                    'Scan Receipt',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryPurple,
                    ),
                  ),
                  Text(
                    'Take a photo and auto-fill',
                    style: TextStyle(color: AppTheme.secondaryTextColor),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManualEntryStep() {
    return GestureDetector(
      onTap: () {
        // Dismiss keyboard when tapping outside input fields
        FocusScope.of(context).unfocus();
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          // Show receipt photo only for actual transactions with auto capture
          if (_transactionMode == TransactionMode.actual && _receiptImage != null) ...[
            const Text(
              'Receipt Photo',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                image: DecorationImage(
                  image: FileImage(_receiptImage!),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Auto-detected information:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
          ],
          
          // Title field - only for actual transactions
          if (_transactionMode == TransactionMode.actual) ...[
            const Text(
              'Title',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppTheme.primaryTextColor),
            ),
            const SizedBox(height: 8),
            CupertinoTextField(
              controller: _titleController,
              placeholder: 'Enter transaction title',
              maxLength: 64,
              padding: const EdgeInsets.all(16),
              decoration: AppTheme.cupertinoTextFieldDecoration,
              style: const TextStyle(color: AppTheme.primaryTextColor),
              placeholderStyle: const TextStyle(color: AppTheme.placeholderTextColor),
            ),
            const SizedBox(height: 16),
          ],
          
          // Amount fields
          Row(
            children: [
              Text(
                _transactionMode == TransactionMode.budget ? 'Expected Amount' : 'Amount',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppTheme.primaryTextColor),
              ),
              const Spacer(),
              if (_amountControllers.length > 1)
                Text(
                  'Total: \$${_getTotalAmount().toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          _buildAmountFields(),

          // Category field
          const Text(
            'Category',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppTheme.primaryTextColor),
          ),
          const SizedBox(height: 8),
          _buildCategoryAutocomplete(),
          const SizedBox(height: 16),
                  
          // Date field
          const Text(
            'Date',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppTheme.primaryTextColor),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => _selectDate(),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: AppTheme.cupertinoTextFieldDecoration,
              child: Row(
                children: [
                  const Icon(CupertinoIcons.calendar, color: AppTheme.primaryColor),
                  const SizedBox(width: 12),
                  Text(
                    DateFormat('MMM dd, yyyy').format(_selectedDate),
                    style: const TextStyle(color: AppTheme.primaryTextColor),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          
          // Next button
          SizedBox(
            width: double.infinity,
            child: CupertinoButton(
              onPressed: _validateAndNext,
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(12),
              child: Text(
                _transactionMode == TransactionMode.budget ? 'Set Budget' : 'Continue',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildConfirmationStep() {
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Confirm Transaction',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          
          // Preview card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _transactionType == model.TransactionType.income
                    ? AppTheme.incomeColor
                    : AppTheme.expenseColor,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: (_transactionType == model.TransactionType.income
                      ? AppTheme.incomeColor
                      : AppTheme.expenseColor).withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _transactionType == model.TransactionType.income
                          ? Icons.trending_up
                          : Icons.trending_down,
                      color: _transactionType == model.TransactionType.income
                          ? AppTheme.incomeColor
                          : AppTheme.expenseColor,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _titleController.text,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _transactionType == model.TransactionType.income
                                ? 'Income'
                                : 'Expense',
                            style: TextStyle(
                              color: _transactionType == model.TransactionType.income
                                  ? AppTheme.incomeColor
                                  : AppTheme.expenseColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      currencyFormat.format(_getTotalAmount()),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: _transactionType == model.TransactionType.income
                            ? AppTheme.incomeColor
                            : AppTheme.expenseColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                if (_categoryController.text.isNotEmpty) ...[
                  _buildDetailRow('Category', _categoryController.text),
                  const SizedBox(height: 8),
                ],
                
                const SizedBox(height: 8),
                
                _buildDetailRow('Date', DateFormat('MMM dd, yyyy').format(_selectedDate)),
                const SizedBox(height: 8),
                _buildDetailRow('Recurrence', _getRecurrenceText(_recurrenceType)),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Recurrence settings section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderColor, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.repeat, color: AppTheme.primaryColor),
                    const SizedBox(width: 8),
                    const Text(
                      'Recurrence',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryTextColor,
                      ),
                    ),
                    const Spacer(),
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      minSize: 0,
                      onPressed: _showRecurrenceOptions,
                      child: Text(
                        _getRecurrenceText(_recurrenceType),
                        style: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                if (_recurrenceType != model.RecurrenceType.none) ...[
                  const SizedBox(height: 8),
                  Text(
                    'This transaction will repeat ${_getRecurrenceText(_recurrenceType).toLowerCase()}',
                    style: const TextStyle(
                      color: AppTheme.secondaryTextColor,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          const Spacer(),
          
          // Action button - only add transaction button
          SizedBox(
            width: double.infinity,
            child: CupertinoButton(
              onPressed: _saveTransaction,
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(12),
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: const Text(
                'Add Transaction',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
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
                            color: AppTheme.incomeColor.withOpacity(0.3),
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



  Widget _buildBudgetEntryStep() {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Expected Amount field
            const Text(
              'Expected Amount',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppTheme.primaryTextColor),
            ),
            const SizedBox(height: 8),
            CupertinoTextField(
              controller: _amountControllers[0],
              placeholder: 'Expected amount',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              padding: const EdgeInsets.all(16),
              decoration: AppTheme.cupertinoTextFieldDecoration,
              style: const TextStyle(color: AppTheme.primaryTextColor),
              placeholderStyle: const TextStyle(color: AppTheme.placeholderTextColor),
            ),
            const SizedBox(height: 16),

            // Category field
            const Text(
              'Category',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppTheme.primaryTextColor),
            ),
            const SizedBox(height: 8),
            _buildCategoryAutocomplete(),
            const SizedBox(height: 16),
            
            // Week selector
            const Text(
              'Week',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppTheme.primaryTextColor),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => _selectWeek(context),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: AppTheme.cupertinoTextFieldDecoration,
                child: Row(
                  children: [
                    const Icon(CupertinoIcons.calendar, color: AppTheme.primaryColor),
                    const SizedBox(width: 12),
                    Text(
                      _getWeekRangeText(_selectedDate),
                      style: const TextStyle(color: AppTheme.primaryTextColor),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            
            // Continue button
            SizedBox(
              width: double.infinity,
              child: CupertinoButton(
                onPressed: _validateBudgetAndNext,
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(12),
                child: const Text(
                  'Review Budget',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetConfirmationStep() {
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Review Budget Entry',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.cardBackground,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _transactionType == model.TransactionType.income
                                ? 'Expected Income Budget' 
                                : 'Expected Expense Budget',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Category: ${_categoryController.text}',
                            style: const TextStyle(
                              fontSize: 16,
                              color: AppTheme.secondaryTextColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      currencyFormat.format(double.tryParse(_amountControllers[0].text) ?? 0),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: _transactionType == model.TransactionType.income
                            ? AppTheme.incomeColor
                            : AppTheme.expenseColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                _buildDetailRow('Week', _getWeekRangeText(_selectedDate)),
                const SizedBox(height: 8),
                _buildDetailRow('Type', _transactionType == model.TransactionType.income ? 'Expected Income' : 'Expected Expense'),
              ],
            ),
          ),
          
          const Spacer(),
          
          // Recurrence section (if needed)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Repeat Budget',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryTextColor,
                      ),
                    ),
                    const Spacer(),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: _showRecurrenceOptions,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _getRecurrenceText(_recurrenceType),
                            style: const TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            CupertinoIcons.chevron_right,
                            size: 16,
                            color: AppTheme.primaryColor,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Create Budget button
          SizedBox(
            width: double.infinity,
            child: CupertinoButton(
              onPressed: _saveTransaction,
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(12),
              child: const Text(
                'Create Budget',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
                      child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: AppTheme.secondaryTextColor,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: AppTheme.primaryTextColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryAutocomplete() {
    final categories = _transactionType == model.TransactionType.income
        ? _incomeCategories
        : _expenseCategories;
    
    return GestureDetector(
      onTap: () {
        // Dismiss keyboard and unfocus when tapping outside
        FocusScope.of(context).unfocus();
      },
      child: RawAutocomplete<String>(
        optionsBuilder: (TextEditingValue textEditingValue) {
          if (textEditingValue.text.isEmpty) {
            return categories;
          }
          return categories.where((String option) {
            return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
          });
        },
        onSelected: (String selection) {
          _categoryController.text = selection;
          FocusScope.of(context).unfocus(); // Dismiss after selection
        },
        fieldViewBuilder: (BuildContext context, TextEditingController controller, FocusNode focusNode, VoidCallback onFieldSubmitted) {
          // Sync the autocomplete controller with our category controller
          if (_categoryController.text != controller.text) {
            controller.text = _categoryController.text;
          }
          
          return Focus(
            onFocusChange: (hasFocus) {
              if (!hasFocus) {
                // Update our controller when focus is lost
                _categoryController.text = controller.text;
              }
            },
            child: CupertinoTextField(
              controller: controller,
              focusNode: focusNode,
              placeholder: 'Type or select category',
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: CupertinoColors.systemGrey4),
                borderRadius: BorderRadius.circular(8),
              ),
              onChanged: (value) {
                _categoryController.text = value;
              },
              onSubmitted: (value) {
                _categoryController.text = value;
                onFieldSubmitted();
                FocusScope.of(context).unfocus();
              },
            ),
          );
        },
        optionsViewBuilder: (BuildContext context, AutocompleteOnSelected<String> onSelected, Iterable<String> options) {
          return Positioned.fill(
            child: GestureDetector(
              onTap: () {
                // Dismiss when tapping outside the options
                FocusScope.of(context).unfocus();
              },
              child: Container(
                color: Colors.transparent,
                child: Align(
                  alignment: Alignment.topLeft,
                  child: GestureDetector(
                    onTap: () {
                      // Prevent dismissal when tapping on the options
                    },
                    child: Material(
                      elevation: 4.0,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        constraints: const BoxConstraints(maxHeight: 200),
                        width: MediaQuery.of(context).size.width - 48, // Account for padding
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.borderColor),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          itemCount: options.length,
                          itemBuilder: (BuildContext context, int index) {
                            final String option = options.elementAt(index);
                            return GestureDetector(
                              onTap: () {
                                onSelected(option);
                              },
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: AppTheme.borderColor,
                                    width: 0.5,
                                  ),
                                ),
                              ),
                                child: Row(
                                  children: [
                                    Icon(
                                      _getCategoryIcon(option),
                                      size: 20,
                                      color: AppTheme.primaryColor,
                                    ),
                                    const SizedBox(width: 12),
                                                                      Expanded(
                                    child: Text(
                                      option,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: AppTheme.primaryTextColor,
                                      ),
                                    ),
                                  ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      // Income categories
      case 'salary':
        return CupertinoIcons.money_dollar;
      case 'freelance':
        return CupertinoIcons.briefcase;
      case 'investment':
        return CupertinoIcons.chart_bar;
      case 'business':
        return CupertinoIcons.building_2_fill;
      case 'gift':
        return CupertinoIcons.gift;
      
      // Expense categories
      case 'food & dining':
        return CupertinoIcons.square_favorites_alt;
      case 'transportation':
        return CupertinoIcons.car;
      case 'shopping':
        return CupertinoIcons.shopping_cart;
      case 'entertainment':
        return CupertinoIcons.game_controller;
      case 'bills & utilities':
        return CupertinoIcons.house;
      case 'healthcare':
        return CupertinoIcons.heart;
      case 'education':
        return CupertinoIcons.book;
      case 'travel':
        return CupertinoIcons.airplane;
      case 'groceries':
        return CupertinoIcons.cart;
      case 'rent':
        return CupertinoIcons.home;
      
      default:
        return CupertinoIcons.tag;
    }
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

  String _getWeekRangeText(DateTime weekStart) {
    DateTime weekEnd = weekStart.add(const Duration(days: 6));
    
    if (weekStart.year == weekEnd.year && weekStart.month == weekEnd.month) {
      return '${DateFormat('MMM dd').format(weekStart)} - ${DateFormat('dd, yyyy').format(weekEnd)}';
    } else if (weekStart.year == weekEnd.year) {
      return '${DateFormat('MMM dd').format(weekStart)} - ${DateFormat('MMM dd, yyyy').format(weekEnd)}';
    } else {
      return '${DateFormat('MMM dd, yyyy').format(weekStart)} - ${DateFormat('MMM dd, yyyy').format(weekEnd)}';
    }
  }



  bool _isCurrentWeek(DateTime weekStart) {
    DateTime now = DateTime.now();
    DateTime currentWeekStart = _getWeekStart(now);
    return weekStart.year == currentWeekStart.year &&
           weekStart.month == currentWeekStart.month &&
           weekStart.day == currentWeekStart.day;
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
        return 'None';
    }
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

  Widget _buildAmountFields() {
    return Column(
      children: [
        AnimatedList(
          key: _listKey,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          initialItemCount: _amountControllers.length,
          itemBuilder: (context, index, animation) {
            // Safety check to prevent RangeError
            if (index >= _amountControllers.length) {
              return const SizedBox.shrink();
            }
            return _buildAmountFieldItem(index, animation);
          },
        ),
      ],
    );
  }

  Widget _buildAmountFieldItem(int index, Animation<double> animation) {
    return SlideTransition(
      position: animation.drive(
        Tween<Offset>(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.easeOut)),
      ),
      child: FadeTransition(
        opacity: animation,
        child: Container(
          margin: index != 0 ? const EdgeInsets.only(bottom: 8) : const EdgeInsets.only(bottom: 0),
          child: Row(
            children: [
              // Remove button on the left for additional inputs
              if (index > 0) ...[
                GestureDetector(
                  onTap: () => _removeAmountField(index),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    child: const Icon(
                      Icons.trending_down,
                      size: 20,
                      color: AppTheme.expenseColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              
              // Amount input field
              Expanded(
                child: CupertinoTextField(
                  controller: _amountControllers[index],
                  placeholder: _transactionMode == TransactionMode.budget 
                      ? 'Expected amount' 
                      : '0.00',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                  ],
                  suffix: index == 0 && _amountControllers.length < 5 && _transactionMode == TransactionMode.actual
                      ? Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: _addAmountField,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              child: const Icon(
                                Icons.add_circle_outline,
                                size: 20,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ),
                        )
                      : null,
                  padding: const EdgeInsets.all(16),
                  decoration: AppTheme.cupertinoTextFieldDecoration,
                  style: const TextStyle(color: AppTheme.primaryTextColor),
                  placeholderStyle: const TextStyle(color: AppTheme.placeholderTextColor),
                  onChanged: (value) => setState(() {}), // Update total
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addAmountField() {
    if (_amountControllers.length < 5) {
      final newIndex = _amountControllers.length;
      _amountControllers.add(TextEditingController());
      
      _listKey.currentState?.insertItem(
        newIndex,
        duration: const Duration(milliseconds: 300),
      );
      
      // Add haptic feedback for better UX
      HapticFeedback.lightImpact();
      
      // Trigger rebuild to update the first field's suffix
      setState(() {});
    }
  }

  void _removeAmountField(int index) {
    if (_amountControllers.length > 1 && index < _amountControllers.length) {
      final controller = _amountControllers[index];
      
      // Remove from our data lists first
      controller.dispose();
      _amountControllers.removeAt(index);
      
      // Then trigger the animation
      _listKey.currentState?.removeItem(
        index,
        (context, animation) => SlideTransition(
          position: animation.drive(
            Tween<Offset>(
              begin: Offset.zero,
              end: const Offset(1.0, 0.0),
            ).chain(CurveTween(curve: Curves.easeOut)),
          ),
          child: FadeTransition(
            opacity: animation,
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              height: 60, // Fixed height for smooth animation
              child: const SizedBox(),
            ),
          ),
        ),
        duration: const Duration(milliseconds: 300),
      );
      
      // Trigger rebuild to update the first field's suffix
      setState(() {});
      
      // Add haptic feedback for better UX
      HapticFeedback.lightImpact();
    }
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