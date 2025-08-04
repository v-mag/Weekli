import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../theme/app_theme.dart';

enum TransactionMode { actual, budget }

class TypeSelectionStep extends StatelessWidget {
  final TransactionMode? selectedMode;
  final Function(TransactionMode) onModeSelected;

  const TypeSelectionStep({
    super.key,
    required this.selectedMode,
    required this.onModeSelected,
  });

  @override
  Widget build(BuildContext context) {
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
            context,
            title: 'Actual Transaction',
            subtitle: 'Record a real transaction that happened',
            icon: Icons.receipt_long,
            color: AppTheme.primaryColor,
            isSelected: selectedMode == TransactionMode.actual,
            onTap: () => onModeSelected(TransactionMode.actual),
          ),
          
          const SizedBox(height: 16),
          
          // Budget Entry Card
          _buildSelectionCard(
            context,
            title: 'Budget Entry',
            subtitle: 'Set expected amount for a category this week',
            icon: Icons.trending_up,
            color: AppTheme.primaryColor,
            isSelected: selectedMode == TransactionMode.budget,
            onTap: () => onModeSelected(TransactionMode.budget),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final cardColor = theme.cardColor;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? color
                : (theme.brightness == Brightness.dark
                    ? Colors.grey.shade700
                    : Colors.grey.shade300),
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
                color: isSelected ? color : theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : AppTheme.primaryColor,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? color : theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.textTheme.bodyMedium?.color,
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
} 