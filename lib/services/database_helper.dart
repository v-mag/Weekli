import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/transaction.dart' as model;
import '../models/category_budget.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'weekli.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE transactions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT,
        amount REAL NOT NULL,
        type INTEGER NOT NULL,
        date INTEGER NOT NULL,
        category TEXT,
        recurrenceType INTEGER NOT NULL DEFAULT 0,
        recurrenceEndDate INTEGER,
        parentTransactionId INTEGER,
        FOREIGN KEY (parentTransactionId) REFERENCES transactions (id)
      )
    ''');
    
    await db.execute('''
      CREATE TABLE category_budgets(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category TEXT NOT NULL,
        expected_amount REAL NOT NULL,
        type INTEGER NOT NULL,
        week_start_date TEXT NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion == 1 && newVersion == 2) {
      // Add the category_budgets table for existing databases
      await db.execute('''
        CREATE TABLE category_budgets(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          category TEXT NOT NULL,
          expected_amount REAL NOT NULL,
          type INTEGER NOT NULL,
          week_start_date TEXT NOT NULL,
          is_active INTEGER NOT NULL DEFAULT 1,
          created_at TEXT NOT NULL
        )
      ''');
    }
  }

  Future<int> insertTransaction(model.Transaction transaction) async {
    final db = await database;
    return await db.insert('transactions', transaction.toMap());
  }

  Future<List<model.Transaction>> getAllTransactions() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      orderBy: 'date DESC',
    );
    return List.generate(maps.length, (i) => model.Transaction.fromMap(maps[i]));
  }

  Future<List<model.Transaction>> getTransactionsByDateRange(
      DateTime start, DateTime end) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'date >= ? AND date <= ?',
      whereArgs: [start.millisecondsSinceEpoch, end.millisecondsSinceEpoch],
      orderBy: 'date DESC',
    );
    return List.generate(maps.length, (i) => model.Transaction.fromMap(maps[i]));
  }

  Future<List<model.Transaction>> getTransactionsByType(model.TransactionType type) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'type = ?',
      whereArgs: [type.index],
      orderBy: 'date DESC',
    );
    return List.generate(maps.length, (i) => model.Transaction.fromMap(maps[i]));
  }

  Future<int> updateTransaction(model.Transaction transaction) async {
    final db = await database;
    return await db.update(
      'transactions',
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  Future<int> deleteTransaction(int id) async {
    final db = await database;
    // Also delete any child recurrent transactions
    await db.delete(
      'transactions',
      where: 'parentTransactionId = ?',
      whereArgs: [id],
    );
    return await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<double> getTotalIncome(DateTime start, DateTime end) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT SUM(amount) as total 
      FROM transactions 
      WHERE type = ? AND date >= ? AND date <= ?
    ''', [model.TransactionType.income.index, start.millisecondsSinceEpoch, end.millisecondsSinceEpoch]);
    
    return (result.first['total'] as double?) ?? 0.0;
  }

  Future<double> getTotalExpense(DateTime start, DateTime end) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT SUM(amount) as total 
      FROM transactions 
      WHERE type = ? AND date >= ? AND date <= ?
    ''', [model.TransactionType.expense.index, start.millisecondsSinceEpoch, end.millisecondsSinceEpoch]);
    
    return (result.first['total'] as double?) ?? 0.0;
  }

  Future<Map<String, double>> getMonthlyTotals(DateTime start, DateTime end) async {
    final incomeResult = await getTotalIncome(start, end);
    final expenseResult = await getTotalExpense(start, end);
    
    return {
      'income': incomeResult,
      'expense': expenseResult,
      'balance': incomeResult - expenseResult,
    };
  }

  // CategoryBudget CRUD operations
  Future<int> insertCategoryBudget(CategoryBudget budget) async {
    final db = await database;
    return await db.insert('category_budgets', budget.toMap());
  }

  Future<List<CategoryBudget>> getAllCategoryBudgets() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'category_budgets',
      where: 'is_active = ?',
      whereArgs: [1],
      orderBy: 'week_start_date DESC',
    );

    return List.generate(maps.length, (i) {
      return CategoryBudget.fromMap(maps[i]);
    });
  }

  Future<List<CategoryBudget>> getCategoryBudgetsByWeek(DateTime weekStart) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'category_budgets',
      where: 'week_start_date = ? AND is_active = ?',
      whereArgs: [weekStart.toIso8601String(), 1],
      orderBy: 'category ASC',
    );

    return List.generate(maps.length, (i) {
      return CategoryBudget.fromMap(maps[i]);
    });
  }

  Future<int> updateCategoryBudget(CategoryBudget budget) async {
    final db = await database;
    return await db.update(
      'category_budgets',
      budget.toMap(),
      where: 'id = ?',
      whereArgs: [budget.id],
    );
  }

  Future<int> deleteCategoryBudget(int id) async {
    final db = await database;
    return await db.update(
      'category_budgets',
      {'is_active': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
} 