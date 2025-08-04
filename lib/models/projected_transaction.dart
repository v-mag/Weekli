import 'transaction.dart';

enum DayOfWeek {
  monday,
  tuesday,
  wednesday,
  thursday,
  friday,
  saturday,
  sunday,
}

extension DayOfWeekExtension on DayOfWeek {
  String get displayName {
    switch (this) {
      case DayOfWeek.monday:
        return 'Monday';
      case DayOfWeek.tuesday:
        return 'Tuesday';
      case DayOfWeek.wednesday:
        return 'Wednesday';
      case DayOfWeek.thursday:
        return 'Thursday';
      case DayOfWeek.friday:
        return 'Friday';
      case DayOfWeek.saturday:
        return 'Saturday';
      case DayOfWeek.sunday:
        return 'Sunday';
    }
  }

  int get weekdayNumber {
    switch (this) {
      case DayOfWeek.monday:
        return 1;
      case DayOfWeek.tuesday:
        return 2;
      case DayOfWeek.wednesday:
        return 3;
      case DayOfWeek.thursday:
        return 4;
      case DayOfWeek.friday:
        return 5;
      case DayOfWeek.saturday:
        return 6;
      case DayOfWeek.sunday:
        return 7;
    }
  }
}

class ProjectedTransaction {
  final int? id;
  final String title;
  final String? description;
  final double projectedAmount;
  final double? actualAmount; // null if not yet confirmed
  final TransactionType type;
  final String? category;
  final DayOfWeek dayOfWeek;
  final bool isActive; // can be disabled without deleting
  final DateTime createdAt;
  final DateTime? confirmedAt; // when actual amount was entered
  final int? linkedTransactionId; // actual transaction when confirmed

  ProjectedTransaction({
    this.id,
    required this.title,
    this.description,
    required this.projectedAmount,
    this.actualAmount,
    required this.type,
    this.category,
    required this.dayOfWeek,
    this.isActive = true,
    required this.createdAt,
    this.confirmedAt,
    this.linkedTransactionId,
  });

  bool get isConfirmed => actualAmount != null;
  
  double get displayAmount => actualAmount ?? projectedAmount;

  ProjectedTransaction copyWith({
    int? id,
    String? title,
    String? description,
    double? projectedAmount,
    double? actualAmount,
    TransactionType? type,
    String? category,
    DayOfWeek? dayOfWeek,
    bool? isActive,
    DateTime? createdAt,
    DateTime? confirmedAt,
    int? linkedTransactionId,
  }) {
    return ProjectedTransaction(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      projectedAmount: projectedAmount ?? this.projectedAmount,
      actualAmount: actualAmount ?? this.actualAmount,
      type: type ?? this.type,
      category: category ?? this.category,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      linkedTransactionId: linkedTransactionId ?? this.linkedTransactionId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'projected_amount': projectedAmount,
      'actual_amount': actualAmount,
      'type': type.index,
      'category': category,
      'day_of_week': dayOfWeek.index,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'confirmed_at': confirmedAt?.toIso8601String(),
      'linked_transaction_id': linkedTransactionId,
    };
  }

  factory ProjectedTransaction.fromMap(Map<String, dynamic> map) {
    return ProjectedTransaction(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      projectedAmount: map['projected_amount'].toDouble(),
      actualAmount: map['actual_amount']?.toDouble(),
      type: TransactionType.values[map['type']],
      category: map['category'],
      dayOfWeek: DayOfWeek.values[map['day_of_week']],
      isActive: map['is_active'] == 1,
      createdAt: DateTime.parse(map['created_at']),
      confirmedAt: map['confirmed_at'] != null 
          ? DateTime.parse(map['confirmed_at']) 
          : null,
      linkedTransactionId: map['linked_transaction_id'],
    );
  }
} 