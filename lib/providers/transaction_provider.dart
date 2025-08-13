import 'package:flutter/foundation.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math';

import '../models/transaction.dart' as model;
import '../models/category_budget.dart';
import '../services/database_helper.dart';

class ChartData {
  final List<FlSpot> realIncome;
  final List<FlSpot> realExpenses;
  final List<FlSpot> budgetIncome;
  final List<FlSpot> budgetExpenses;
  final double maxY;

  ChartData({
    required this.realIncome,
    required this.realExpenses,
    required this.budgetIncome,
    required this.budgetExpenses,
    required this.maxY,
  });
}

class TransactionProvider with ChangeNotifier {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  
  List<model.Transaction> _transactions = [];
  List<CategoryBudget> _categoryBudgets = [];
  DateTime _selectedDate = DateTime.now();
  
  List<model.Transaction> get transactions => _transactions;
  List<CategoryBudget> get categoryBudgets => _categoryBudgets;
  DateTime get selectedDate => _selectedDate;
  
  // Get transactions for selected date range
  List<model.Transaction> get todayTransactions {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);
    
    return _transactions.where((transaction) =>
        transaction.date.isAfter(startOfDay.subtract(const Duration(seconds: 1))) &&
        transaction.date.isBefore(endOfDay.add(const Duration(seconds: 1)))
    ).toList();
  }
  
  List<model.Transaction> get weekTransactions {
    final now = DateTime.now();
    
    // In Dart, Monday is 1 and Sunday is 7.
    final startOfWeek = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 7));
    
    return _transactions.where((transaction) {
      return !transaction.date.isBefore(startOfWeek) && transaction.date.isBefore(endOfWeek);
    }).toList();
  }
  
  List<model.Transaction> get monthTransactions {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    
    return _transactions.where((transaction) =>
        transaction.date.isAfter(startOfMonth.subtract(const Duration(seconds: 1))) &&
        transaction.date.isBefore(endOfMonth.add(const Duration(seconds: 1)))
    ).toList();
  }
  
  // Calculate totals
  double get todayIncome {
    return todayTransactions
        .where((t) => t.type == model.TransactionType.income)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get todayExpense {
    return todayTransactions
        .where((t) => t.type == model.TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get todayBalance => todayIncome - todayExpense;

  double get weeklyIncome {
    return weekTransactions
        .where((t) => t.type == model.TransactionType.income)
        .fold(0.0, (sum, t) => sum + t.amount);
  }
  
  double get weeklyExpense {
    return weekTransactions
        .where((t) => t.type == model.TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);
  }
  
  double get weeklyBalance => weeklyIncome - weeklyExpense;
  
  double get monthlyIncome {
    return monthTransactions
        .where((t) => t.type == model.TransactionType.income)
        .fold(0.0, (sum, t) => sum + t.amount);
  }
  
  double get monthlyExpense {
    return monthTransactions
        .where((t) => t.type == model.TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);
  }
  
  double get monthlyBalance => monthlyIncome - monthlyExpense;
  
  double get totalBalance {
    return _transactions.fold(0.0, (sum, t) {
      return sum + (t.type == model.TransactionType.income ? t.amount : -t.amount);
    });
  }

  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }
  
  Future<void> loadTransactions() async {
    _transactions = await _databaseHelper.getAllTransactions();
    notifyListeners();
  }
  
  Future<void> addTransaction(model.Transaction transaction) async {
    final id = await _databaseHelper.insertTransaction(transaction);
    final newTransaction = transaction.copyWith(id: id);
    
    // Handle recurrent transactions
    if (transaction.isRecurrent) {
      final recurrentTransactions = await _generateRecurrentTransactions(newTransaction);
      _transactions.addAll(recurrentTransactions);
    } else {
      _transactions.add(newTransaction);
    }
    
    notifyListeners();
  }
  
  Future<void> updateTransaction(model.Transaction transaction) async {
    await _databaseHelper.updateTransaction(transaction);
    final index = _transactions.indexWhere((t) => t.id == transaction.id);
    if (index != -1) {
      _transactions[index] = transaction;
      notifyListeners();
    }
  }
  
  Future<void> deleteTransaction(int id) async {
    await _databaseHelper.deleteTransaction(id);
    _transactions.removeWhere((t) => t.id == id);
    notifyListeners();
  }
  
  Future<List<model.Transaction>> _generateRecurrentTransactions(model.Transaction parentTransaction) async {
    if (!parentTransaction.isRecurrent || parentTransaction.id == null) return [];
    
    DateTime currentDate = parentTransaction.date;
    final endDate = parentTransaction.recurrenceEndDate ?? 
        DateTime.now().add(const Duration(days: 365)); // Default to 1 year
    
    final recurrentTransactions = <model.Transaction>[];
    while (currentDate.isBefore(endDate)) {
      DateTime nextDate;
      
      switch (parentTransaction.recurrenceType) {
        case model.RecurrenceType.daily:
          nextDate = currentDate.add(const Duration(days: 1));
          break;
        case model.RecurrenceType.weekly:
          nextDate = currentDate.add(const Duration(days: 7));
          break;
        case model.RecurrenceType.monthly:
          nextDate = DateTime(currentDate.year, currentDate.month + 1, currentDate.day);
          break;
        case model.RecurrenceType.yearly:
          nextDate = DateTime(currentDate.year + 1, currentDate.month, currentDate.day);
          break;
        default:
          return [];
      }
      
      if (nextDate.isAfter(endDate)) break;
      
      final recurrentTransaction = parentTransaction.copyWith(
        id: null,
        date: nextDate,
        parentTransactionId: parentTransaction.id,
      );
      
      recurrentTransactions.add(recurrentTransaction);
      currentDate = nextDate;
    }
    return recurrentTransactions;
  }
  
  List<model.Transaction> getTransactionsForDateRange(DateTime start, DateTime end) {
    return _transactions.where((transaction) =>
        transaction.date.isAfter(start.subtract(const Duration(seconds: 1))) &&
        transaction.date.isBefore(end.add(const Duration(seconds: 1)))
    ).toList();
  }
  
  Map<DateTime, List<model.Transaction>> getTransactionsByDay() {
    final Map<DateTime, List<model.Transaction>> transactionsByDay = {};
    
    for (final transaction in _transactions) {
      final date = DateTime(transaction.date.year, transaction.date.month, transaction.date.day);
      if (transactionsByDay[date] == null) {
        transactionsByDay[date] = [];
      }
      transactionsByDay[date]!.add(transaction);
    }
    
    return transactionsByDay;
  }

  // CategoryBudget management methods
  Future<void> loadCategoryBudgets() async {
    _categoryBudgets = await _databaseHelper.getAllCategoryBudgets();
    notifyListeners();
  }

  Future<void> addCategoryBudget(CategoryBudget budget) async {
    final id = await _databaseHelper.insertCategoryBudget(budget);
    final budgetWithId = budget.copyWith(id: id);
    _categoryBudgets.add(budgetWithId);
    notifyListeners();
  }

  Future<void> updateCategoryBudget(CategoryBudget budget) async {
    await _databaseHelper.updateCategoryBudget(budget);
    final index = _categoryBudgets.indexWhere((b) => b.id == budget.id);
    if (index != -1) {
      _categoryBudgets[index] = budget;
      notifyListeners();
    }
  }

  Future<void> deleteCategoryBudget(int id) async {
    await _databaseHelper.deleteCategoryBudget(id);
    _categoryBudgets.removeWhere((budget) => budget.id == id);
    notifyListeners();
  }

  List<CategoryBudget> getCategoryBudgetsByWeek(DateTime weekStart) {
    return _categoryBudgets.where((budget) {
      final budgetWeekStart = DateTime(
        budget.weekStartDate.year,
        budget.weekStartDate.month,
        budget.weekStartDate.day,
      );
      final targetWeekStart = DateTime(
        weekStart.year,
        weekStart.month,
        weekStart.day,
      );
      return budgetWeekStart.isAtSameMomentAs(targetWeekStart);
    }).toList();
  }

  ChartData getChartData(String period) {
    List<model.Transaction> transactions;
    DateTime startDate;
    int days;

    switch (period) {
      case 'Today': // Show last 7 days for context
        transactions = _transactions.where((t) => t.date.isAfter(DateTime.now().subtract(const Duration(days: 7)))).toList();
        startDate = DateTime.now().subtract(const Duration(days: 6));
        days = 7;
        break;
      case 'This Week':
        transactions = weekTransactions;
        startDate = DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1));
        days = 7;
        break;
      case 'This Month':
        transactions = monthTransactions;
        startDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
        days = DateTime(DateTime.now().year, DateTime.now().month + 1, 0).day;
        break;
      case 'Last 30 Days':
        transactions = _transactions.where((t) => t.date.isAfter(DateTime.now().subtract(const Duration(days: 30)))).toList();
        startDate = DateTime.now().subtract(const Duration(days: 29));
        days = 30;
        break;
      default:
        transactions = monthTransactions;
        startDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
        days = DateTime(DateTime.now().year, DateTime.now().month + 1, 0).day;
        break;
    }

    List<FlSpot> realIncome = [];
    List<FlSpot> realExpenses = [];
    List<FlSpot> budgetIncome = [];
    List<FlSpot> budgetExpenses = [];
    double cumulativeRealIncome = 0;
    double cumulativeRealExpense = 0;
    double cumulativeBudgetIncome = 0;
    double cumulativeBudgetExpense = 0;
    double maxY = 0;

    for (int i = 0; i < days; i++) {
      final date = startDate.add(Duration(days: i));
      final dayTransactions = transactions.where((t) => t.date.year == date.year && t.date.month == date.month && t.date.day == date.day).toList();
      final dayBudgets = _categoryBudgets.where((b) => b.weekStartDate.isBefore(date.add(const Duration(days: 1))) && b.weekStartDate.add(const Duration(days: 7)).isAfter(date)).toList();
      
      cumulativeRealIncome += dayTransactions.where((t) => t.type == model.TransactionType.income).fold(0.0, (sum, t) => sum + t.amount);
      cumulativeRealExpense += dayTransactions.where((t) => t.type == model.TransactionType.expense).fold(0.0, (sum, t) => sum + t.amount);
      cumulativeBudgetIncome += dayBudgets.where((b) => b.type == model.TransactionType.income).fold(0.0, (sum, b) => sum + b.expectedAmount) / 7;
      cumulativeBudgetExpense += dayBudgets.where((b) => b.type == model.TransactionType.expense).fold(0.0, (sum, b) => sum + b.expectedAmount) / 7;

      realIncome.add(FlSpot(i.toDouble(), cumulativeRealIncome));
      realExpenses.add(FlSpot(i.toDouble(), cumulativeRealExpense));
      budgetIncome.add(FlSpot(i.toDouble(), cumulativeBudgetIncome));
      budgetExpenses.add(FlSpot(i.toDouble(), cumulativeBudgetExpense));
      
      maxY = [maxY, cumulativeRealIncome, cumulativeRealExpense, cumulativeBudgetIncome, cumulativeBudgetExpense].reduce(max);
    }
    
    return ChartData(
      realIncome: realIncome,
      realExpenses: realExpenses,
      budgetIncome: budgetIncome,
      budgetExpenses: budgetExpenses,
      maxY: maxY > 0 ? maxY * 1.2 : 10.0,
    );
  }
} 