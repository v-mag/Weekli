import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart' as model;

class TransactionAmountInput extends StatefulWidget {
  final List<TextEditingController> amountControllers;
  final VoidCallback? onAmountChanged;
  final bool allowMultiple;

  const TransactionAmountInput({
    super.key,
    required this.amountControllers,
    this.onAmountChanged,
    this.allowMultiple = true,
  });

  @override
  State<TransactionAmountInput> createState() => _TransactionAmountInputState();
}

class _TransactionAmountInputState extends State<TransactionAmountInput> {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();

  double getTotalAmount() {
    return widget.amountControllers.fold(0.0, (sum, controller) {
      return sum + (double.tryParse(controller.text) ?? 0.0);
    });
  }

  Widget _buildAmountFieldItem(int index, Animation<double> animation) {
    if (index >= widget.amountControllers.length) {
      return const SizedBox.shrink();
    }
    final theme = Theme.of(context);

    return SlideTransition(
      position: animation.drive(Tween(begin: const Offset(1, 0), end: Offset.zero)),
      child: Row(
        children: [            
          // Amount input
          Expanded(
            flex: 2,
            child: CupertinoTextField(
              controller: widget.amountControllers[index],
              decoration: BoxDecoration(
                color: theme.inputDecorationTheme.fillColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.inputDecorationTheme.enabledBorder?.borderSide.color ?? theme.dividerColor,
                  width: 1.0,
                ),
              ),
              placeholder: 'Amount',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              padding: const EdgeInsets.all(16),
              style: TextStyle(color: theme.colorScheme.onSurface),
              placeholderStyle: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
              onChanged: (_) => widget.onAmountChanged?.call(),
            ),
          ),
          
          // const SizedBox(width: 12),
          
          // Add button (only show on first field if multiple allowed)
          // if (widget.allowMultiple && index == 0 && widget.amountControllers.length < 5)
          //   IconButton(
          //     onPressed: _addAmountField,
          //     icon: const Icon(Icons.add_circle_outline, size: 20),
          //     color: AppTheme.primaryColor,
          //     constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          //   ),
      
          //   // Remove button (only show for additional fields)
          // if (index > 0)
          //   IconButton(
          //     onPressed: () => _removeAmountField(index),
          //     icon: const Icon(Icons.remove_circle_outline, size: 20),
          //     color: AppTheme.primaryColor,
          //     constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          //   ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedList(
          key: _listKey,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          initialItemCount: widget.amountControllers.length,
          itemBuilder: (context, index, animation) {
            return _buildAmountFieldItem(index, animation);
          },
        ),
      ],
    );
  }
}

class TransactionCategoryInput extends StatefulWidget {
  final TextEditingController controller;
  final model.TransactionType transactionType;
  final String? placeholder;

  const TransactionCategoryInput({
    super.key,
    required this.controller,
    required this.transactionType,
    this.placeholder,
  });

  @override
  State<TransactionCategoryInput> createState() => _TransactionCategoryInputState();
}

class _TransactionCategoryInputState extends State<TransactionCategoryInput> {
  final FocusNode _focusNode = FocusNode();
  final GlobalKey _fieldKey = GlobalKey();
  
  final List<String> _incomeCategories = [
    'Salary', 'Freelance', 'Investment', 'Business', 'Gift', 'Other Income',
  ];

  final List<String> _expenseCategories = [
    'Food & Dining', 'Transportation', 'Shopping', 'Entertainment', 'Bills & Utilities',
    'Healthcare', 'Education', 'Travel', 'Groceries', 'Rent', 'Other Expense',
  ];

  List<String> get _categories => 
      widget.transactionType == model.TransactionType.income 
          ? _incomeCategories 
          : _expenseCategories;

  IconData _getCategoryIcon(String category) {
    switch (category) {
      // Income categories
      case 'Salary':
        return Icons.work;
      case 'Freelance':
        return Icons.laptop;
      case 'Investment':
        return Icons.trending_up;
      case 'Business':
        return Icons.business;
      case 'Gift':
        return Icons.card_giftcard;
      case 'Other Income':
        return Icons.add_circle;
      
      // Expense categories
      case 'Food & Dining':
        return Icons.restaurant;
      case 'Transportation':
        return Icons.directions_car;
      case 'Shopping':
        return Icons.shopping_bag;
      case 'Entertainment':
        return Icons.movie;
      case 'Bills & Utilities':
        return Icons.receipt;
      case 'Healthcare':
        return Icons.local_hospital;
      case 'Education':
        return Icons.school;
      case 'Travel':
        return Icons.flight;
      case 'Groceries':
        return Icons.local_grocery_store;
      case 'Rent':
        return Icons.home;
      case 'Other Expense':
        return Icons.remove_circle;
      
      default:
        return Icons.category;
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Focus(
      child: GestureDetector(
        onTap: () => _focusNode.unfocus(),
        child: RawAutocomplete<String>(
          focusNode: _focusNode,
          textEditingController: widget.controller,
          optionsBuilder: (TextEditingValue textEditingValue) {
            if (textEditingValue.text.isEmpty) {
              return _categories;
            }
            return _categories.where((String option) {
              return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
            });
          },
          fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
            return CupertinoTextField(
              key: _fieldKey,
              controller: textEditingController,
              focusNode: focusNode,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.inputDecorationTheme.fillColor,
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(
                  color: focusNode.hasFocus
                      ? theme.primaryColor
                      : (theme.inputDecorationTheme.enabledBorder?.borderSide.color ?? theme.dividerColor),
                  width: focusNode.hasFocus ? 2.0 : 1.0,
                ),
              ),
              placeholder: widget.placeholder ?? 'Category',
              style: TextStyle(color: theme.colorScheme.onSurface),
              placeholderStyle: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
              onSubmitted: (String value) => onFieldSubmitted(),
            );
          },
          optionsViewBuilder: (context, onSelected, options) {
            final RenderBox? fieldBox = _fieldKey.currentContext?.findRenderObject() as RenderBox?;
            final fieldWidth = fieldBox?.size.width ?? MediaQuery.of(context).size.width;

            return Positioned.fill(
              child: GestureDetector(
                onTap: () => _focusNode.unfocus(),
                child: Container(
                  color: Colors.transparent,
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: SizedBox(
                      width: fieldWidth,
                      child: Material(
                        elevation: 4.0,
                        borderRadius: BorderRadius.circular(12),
                        color: theme.cardColor,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 200),
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            itemCount: options.length,
                            itemBuilder: (context, index) {
                              final option = options.elementAt(index);
                              return InkWell(
                                onTap: () => onSelected(option),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(color: theme.dividerColor.withValues(alpha: 0.5)),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        _getCategoryIcon(option),
                                        color: theme.brightness == Brightness.light ? theme.primaryColor : theme.colorScheme.onSurface,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        option,
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: theme.colorScheme.onSurface,
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
      ),
    );
  }
}

class TransactionDateInput extends StatelessWidget {
  final DateTime selectedDate;
  final VoidCallback onTap;
  final String label;
  final String Function(DateTime)? displayFormat;

  const TransactionDateInput({
    super.key,
    required this.selectedDate,
    required this.onTap,
    this.label = 'Date',
    this.displayFormat,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.inputDecorationTheme.fillColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.inputDecorationTheme.enabledBorder?.borderSide.color ?? theme.dividerColor,
            width: 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(CupertinoIcons.calendar, color: theme.brightness == Brightness.light ? theme.primaryColor : theme.colorScheme.onSurface),
            const SizedBox(width: 12),
            Text(
              displayFormat?.call(selectedDate) ?? DateFormat('MMM dd, yyyy').format(selectedDate),
              style: TextStyle(color: theme.colorScheme.onSurface),
            ),
          ],
        ),
      ),
    );
  }
}

class LoadingSuccessAnimation extends StatefulWidget {
  final String loadingText;
  final String successText;
  final VoidCallback onComplete;

  const LoadingSuccessAnimation({
    super.key,
    required this.loadingText,
    required this.successText,
    required this.onComplete,
  });

  @override
  State<LoadingSuccessAnimation> createState() => _LoadingSuccessAnimationState();
}

class _LoadingSuccessAnimationState extends State<LoadingSuccessAnimation> {
  bool _showSuccessCheck = false;

  @override
  void initState() {
    super.initState();
    _startAnimation();
  }

  void _startAnimation() async {
    // Show loading for 1 second
    await Future.delayed(const Duration(milliseconds: 1000));
    
    if (mounted) {
      setState(() => _showSuccessCheck = true);
      await Future.delayed(const Duration(milliseconds: 1500));
      
      if (mounted) {
        widget.onComplete();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Loading/Success icon
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            child: _showSuccessCheck
                ? const ScaleTransition(
                    scale: AlwaysStoppedAnimation(1.2),
                    child: Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 80,
                    ),
                  )
                : const CupertinoActivityIndicator(radius: 30),
          ),
          
          const SizedBox(height: 32),
          
          // Status text
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: Text(
              _showSuccessCheck ? widget.successText : widget.loadingText,
              key: ValueKey(_showSuccessCheck),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
} 