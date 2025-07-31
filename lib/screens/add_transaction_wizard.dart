import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../providers/transaction_provider.dart';
import '../models/transaction.dart' as model;

class AddTransactionWizard extends StatefulWidget {
  const AddTransactionWizard({super.key});

  @override
  State<AddTransactionWizard> createState() => _AddTransactionWizardState();
}

class _AddTransactionWizardState extends State<AddTransactionWizard> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  final int _totalSteps = 4;

  // Transaction data
  model.TransactionType _transactionType = model.TransactionType.income;
  bool _isManualEntry = true;
  File? _receiptImage;
  
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _categoryController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now();
  model.RecurrenceType _recurrenceType = model.RecurrenceType.none;
  DateTime? _recurrenceEndDate;
  bool _isLoading = false;

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
    _descriptionController.dispose();
    _amountController.dispose();
    _categoryController.dispose();
    super.dispose();
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

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);
    
    if (image != null) {
      setState(() {
        _receiptImage = File(image.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Transaction (${_currentStep + 1}/$_totalSteps)'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: _currentStep > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _previousStep,
              )
            : IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
        actions: [
          if (_currentStep >= 2)
            IconButton(
              icon: Icon(
                _recurrenceType != model.RecurrenceType.none
                    ? Icons.repeat
                    : Icons.repeat_outlined,
                color: _recurrenceType != model.RecurrenceType.none
                    ? Colors.blue
                    : null,
              ),
              onPressed: _showRecurrenceOptions,
            ),
        ],
      ),
      body: Column(
        children: [
          // Progress indicator
          Container(
            padding: const EdgeInsets.all(16),
            child: LinearProgressIndicator(
              value: (_currentStep + 1) / _totalSteps,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                _transactionType == model.TransactionType.income
                    ? Colors.green
                    : Colors.red,
              ),
            ),
          ),
          
          // Page content
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildTypeSelectionStep(),
                _buildInputMethodStep(),
                _buildManualEntryStep(),
                _buildConfirmationStep(),
              ],
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'What type of transaction?',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _transactionType = model.TransactionType.income;
                    });
                    _nextStep();
                  },
                  child: Container(
                    height: 150,
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.green,
                        width: 2,
                      ),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_circle, color: Colors.green, size: 48),
                        SizedBox(height: 8),
                        Text(
                          'Income',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        Text(
                          'Money coming in',
                          style: TextStyle(color: Colors.green),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              const SizedBox(width: 16),
              
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _transactionType = model.TransactionType.expense;
                    });
                    _nextStep();
                  },
                  child: Container(
                    height: 150,
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.red,
                        width: 2,
                      ),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.remove_circle, color: Colors.red, size: 48),
                        SizedBox(height: 8),
                        Text(
                          'Expense',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                        Text(
                          'Money going out',
                          style: TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
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
              setState(() {
                _isManualEntry = true;
              });
              _nextStep();
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blue, width: 2),
              ),
              child: const Column(
                children: [
                  Icon(Icons.edit, color: Colors.blue, size: 48),
                  SizedBox(height: 12),
                  Text(
                    'Manual Entry',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  Text(
                    'Fill in the details yourself',
                    style: TextStyle(color: Colors.blue),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Automatic with photo option
          GestureDetector(
            onTap: () {
              setState(() {
                _isManualEntry = false;
              });
              _pickImage();
              _nextStep();
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.purple, width: 2),
              ),
              child: const Column(
                children: [
                  Icon(Icons.camera_alt, color: Colors.purple, size: 48),
                  SizedBox(height: 12),
                  Text(
                    'Scan Receipt',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple,
                    ),
                  ),
                  Text(
                    'Take a photo and auto-fill',
                    style: TextStyle(color: Colors.purple),
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
          if (!_isManualEntry && _receiptImage != null) ...[
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
          
          // Title field
          const Text(
            'Title',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          CupertinoTextField(
            controller: _titleController,
            placeholder: 'Enter transaction title',
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: CupertinoColors.systemGrey4),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 16),
          
          // Amount field
          const Text(
            'Amount',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          CupertinoTextField(
            controller: _amountController,
            placeholder: '0.00',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            prefix: const Padding(
              padding: EdgeInsets.only(left: 16),
              child: Text('\$', style: TextStyle(fontSize: 18)),
            ),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: CupertinoColors.systemGrey4),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 16),
          
          // Category field
          const Text(
            'Category',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          _buildCategoryAutocomplete(),
          const SizedBox(height: 16),
          
          // Description field
          const Text(
            'Description (Optional)',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          CupertinoTextField(
            controller: _descriptionController,
            placeholder: 'Add a note...',
            maxLines: 3,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: CupertinoColors.systemGrey4),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 16),
          
          // Date field
          const Text(
            'Date',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => _selectDate(),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: CupertinoColors.systemGrey4),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(CupertinoIcons.calendar),
                  const SizedBox(width: 12),
                  Text(DateFormat('MMM dd, yyyy').format(_selectedDate)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          
          // Next button
          SizedBox(
            width: double.infinity,
            child: CupertinoButton.filled(
              onPressed: _validateAndNext,
              child: const Text(
                'Continue',
                style: TextStyle(color: CupertinoColors.white),
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
              color: (_transactionType == model.TransactionType.income
                  ? Colors.green
                  : Colors.red).withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _transactionType == model.TransactionType.income
                    ? Colors.green
                    : Colors.red,
                width: 2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _transactionType == model.TransactionType.income
                          ? Icons.add_circle
                          : Icons.remove_circle,
                      color: _transactionType == model.TransactionType.income
                          ? Colors.green
                          : Colors.red,
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
                                  ? Colors.green
                                  : Colors.red,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      currencyFormat.format(double.tryParse(_amountController.text) ?? 0),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: _transactionType == model.TransactionType.income
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                if (_categoryController.text.isNotEmpty) ...[
                  _buildDetailRow('Category', _categoryController.text),
                  const SizedBox(height: 8),
                ],
                
                if (_descriptionController.text.isNotEmpty) ...[
                  _buildDetailRow('Description', _descriptionController.text),
                  const SizedBox(height: 8),
                ],
                
                _buildDetailRow('Date', DateFormat('MMM dd, yyyy').format(_selectedDate)),
                
                if (_recurrenceType != model.RecurrenceType.none) ...[
                  const SizedBox(height: 8),
                  _buildDetailRow('Recurrence', _getRecurrenceText(_recurrenceType)),
                ],
              ],
            ),
          ),
          
          const Spacer(),
          
          // Action buttons
          Row(
            children: [
              Expanded(
                child: CupertinoButton(
                  onPressed: _previousStep,
                  child: const Text('Back'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: CupertinoButton.filled(
                  onPressed: _isLoading ? null : _saveTransaction,
                  child: _isLoading
                      ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                      : const Text(
                          'Add Transaction',
                          style: TextStyle(color: CupertinoColors.white),
                        ),
                ),
              ),
            ],
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
              color: CupertinoColors.secondaryLabel,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
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
                          color: CupertinoColors.systemBackground.resolveFrom(context),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: CupertinoColors.systemGrey4),
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
                                      color: CupertinoColors.systemGrey5.resolveFrom(context),
                                      width: 0.5,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      _getCategoryIcon(option),
                                      size: 20,
                                      color: _transactionType == model.TransactionType.income
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        option,
                                        style: const TextStyle(fontSize: 16),
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

  void _selectDate() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 250,
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: CupertinoDatePicker(
          mode: CupertinoDatePickerMode.date,
          initialDateTime: _selectedDate,
          onDateTimeChanged: (date) {
            setState(() {
              _selectedDate = date;
            });
          },
        ),
      ),
    );
  }

  void _validateAndNext() {
    if (_titleController.text.trim().isEmpty ||
        _amountController.text.trim().isEmpty ||
        double.tryParse(_amountController.text) == null ||
        double.tryParse(_amountController.text)! <= 0) {
      
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
    setState(() {
      _isLoading = true;
    });

    try {
      final transaction = model.Transaction(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isNotEmpty 
            ? _descriptionController.text.trim() 
            : null,
        amount: double.parse(_amountController.text),
        type: _transactionType,
        date: _selectedDate,
        category: _categoryController.text.isNotEmpty ? _categoryController.text : null,
        recurrenceType: _recurrenceType,
        recurrenceEndDate: _recurrenceEndDate,
      );

      await context.read<TransactionProvider>().addTransaction(transaction);

      if (mounted) {
        Navigator.pop(context);
        // Show success message
      }
    } catch (e) {
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Error'),
            content: Text('Failed to save transaction: $e'),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
                  child: Text(_getRecurrenceText(type)),
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
                child: CupertinoButton.filled(
                  onPressed: () {
                    widget.onRecurrenceChanged(_selectedType, _selectedEndDate);
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Save',
                    style: TextStyle(color: CupertinoColors.white),
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