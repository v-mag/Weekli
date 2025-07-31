enum TransactionType {
  income,
  expense,
}

enum RecurrenceType {
  none,
  daily,
  weekly,
  monthly,
  yearly,
}

class Transaction {
  final int? id;
  final String title;
  final String? description;
  final double amount;
  final TransactionType type;
  final DateTime date;
  final String? category;
  final RecurrenceType recurrenceType;
  final DateTime? recurrenceEndDate;
  final int? parentTransactionId; // For recurrent transactions

  Transaction({
    this.id,
    required this.title,
    this.description,
    required this.amount,
    required this.type,
    required this.date,
    this.category,
    this.recurrenceType = RecurrenceType.none,
    this.recurrenceEndDate,
    this.parentTransactionId,
  });

  Transaction copyWith({
    int? id,
    String? title,
    String? description,
    double? amount,
    TransactionType? type,
    DateTime? date,
    String? category,
    RecurrenceType? recurrenceType,
    DateTime? recurrenceEndDate,
    int? parentTransactionId,
  }) {
    return Transaction(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      date: date ?? this.date,
      category: category ?? this.category,
      recurrenceType: recurrenceType ?? this.recurrenceType,
      recurrenceEndDate: recurrenceEndDate ?? this.recurrenceEndDate,
      parentTransactionId: parentTransactionId ?? this.parentTransactionId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'amount': amount,
      'type': type.index,
      'date': date.millisecondsSinceEpoch,
      'category': category,
      'recurrenceType': recurrenceType.index,
      'recurrenceEndDate': recurrenceEndDate?.millisecondsSinceEpoch,
      'parentTransactionId': parentTransactionId,
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      amount: map['amount'],
      type: TransactionType.values[map['type']],
      date: DateTime.fromMillisecondsSinceEpoch(map['date']),
      category: map['category'],
      recurrenceType: RecurrenceType.values[map['recurrenceType']],
      recurrenceEndDate: map['recurrenceEndDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['recurrenceEndDate'])
          : null,
      parentTransactionId: map['parentTransactionId'],
    );
  }

  bool get isRecurrent => recurrenceType != RecurrenceType.none;
  bool get isIncome => type == TransactionType.income;
  bool get isExpense => type == TransactionType.expense;
} 