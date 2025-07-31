import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/transaction.dart' as model;

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
      version: 1,
      onCreate: _onCreate,
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
    final db = await database;
    final incomeResult = await getTotalIncome(start, end);
    final expenseResult = await getTotalExpense(start, end);
    
    return {
      'income': incomeResult,
      'expense': expenseResult,
      'balance': incomeResult - expenseResult,
    };
  }
} 