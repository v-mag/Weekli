import 'transaction.dart';

class CategoryBudget {
  final int? id;
  final String category;
  final double expectedAmount;
  final TransactionType type;
  final DateTime weekStartDate; // Monday of the week this budget applies to
  final bool isActive;
  final DateTime createdAt;

  CategoryBudget({
    this.id,
    required this.category,
    required this.expectedAmount,
    required this.type,
    required this.weekStartDate,
    this.isActive = true,
    required this.createdAt,
  });

  CategoryBudget copyWith({
    int? id,
    String? category,
    double? expectedAmount,
    TransactionType? type,
    DateTime? weekStartDate,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return CategoryBudget(
      id: id ?? this.id,
      category: category ?? this.category,
      expectedAmount: expectedAmount ?? this.expectedAmount,
      type: type ?? this.type,
      weekStartDate: weekStartDate ?? this.weekStartDate,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category': category,
      'expected_amount': expectedAmount,
      'type': type.index,
      'week_start_date': weekStartDate.toIso8601String(),
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory CategoryBudget.fromMap(Map<String, dynamic> map) {
    return CategoryBudget(
      id: map['id'],
      category: map['category'],
      expectedAmount: map['expected_amount'].toDouble(),
      type: TransactionType.values[map['type']],
      weekStartDate: DateTime.parse(map['week_start_date']),
      isActive: map['is_active'] == 1,
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}

class CategoryBudgetSummary {
  final CategoryBudget budget;
  final double actualAmount;
  final int transactionCount;

  CategoryBudgetSummary({
    required this.budget,
    required this.actualAmount,
    required this.transactionCount,
  });

  double get remainingAmount => budget.expectedAmount - actualAmount;
  double get progressPercentage => (actualAmount / budget.expectedAmount).clamp(0.0, 1.0);
  bool get isOverBudget => actualAmount > budget.expectedAmount;
  bool get isCompleted => actualAmount >= budget.expectedAmount;
} 