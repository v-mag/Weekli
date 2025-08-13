import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/transaction_provider.dart';
import '../providers/settings_provider.dart';
import '../models/transaction.dart' as model;
import '../theme/app_theme.dart';
import 'settings_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weekli Dashboard'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<TransactionProvider>(
        builder: (context, transactionProvider, child) {
          return Consumer<SettingsProvider>(
            builder: (context, settingsProvider, child) {
              final currentBalance = settingsProvider.initialBalance + transactionProvider.totalBalance;
              
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Current Balance Card
                    _buildCurrentBalanceCard(context, currentBalance),
                    const SizedBox(height: 16),
                    
                    // Today Overview Card
                    _buildOverviewCard(
                      context,
                      'Today',
                      transactionProvider.todayIncome,
                      transactionProvider.todayExpense,
                      transactionProvider.todayBalance,
                      transactionProvider,
                    ),
                    const SizedBox(height: 16),
                    
                    // Weekly Overview Card
                    _buildOverviewCard(
                      context,
                      'This Week',
                      transactionProvider.weeklyIncome,
                      transactionProvider.weeklyExpense,
                      transactionProvider.weeklyBalance,
                      transactionProvider,
                    ),
                    const SizedBox(height: 16),

                    // Monthly Overview Card
                    _buildOverviewCard(
                      context,
                      'This Month',
                      transactionProvider.monthlyIncome,
                      transactionProvider.monthlyExpense,
                      transactionProvider.monthlyBalance,
                      transactionProvider,
                    ),
                    const SizedBox(height: 16),
                    _buildChartCard(context, 'Last 30 Days', transactionProvider),
                    const SizedBox(height: 24),
                    
                    // Recent Transactions
                    Text(
                      'Recent Transactions',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    if (transactionProvider.transactions.isEmpty)
                      const Card(
                        child: Padding(
                          padding: EdgeInsets.all(24.0),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(Icons.receipt_long, size: 48, color: Colors.grey),
                                SizedBox(height: 8),
                                Text(
                                  'No transactions yet',
                                  style: TextStyle(color: Colors.grey, fontSize: 16),
                                ),
                                Text(
                                  'Tap the + button to add your first transaction',
                                  style: TextStyle(color: Colors.grey, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    else
                      ...transactionProvider.transactions.take(5).map((transaction) =>
                        _buildTransactionTile(context, transaction)
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildCurrentBalanceCard(BuildContext context, double currentBalance) {
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Current Balance',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              currencyFormat.format(currentBalance),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: currentBalance >= 0 ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewCard(
    BuildContext context,
    String title,
    double income,
    double expense,
    double balance,
    TransactionProvider transactionProvider,
  ) {
    final currencyFormat = NumberFormat.currency(symbol: '\$');

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: _buildAmountColumn(
                    'Income',
                    currencyFormat.format(income),
                    Colors.green,
                    Icons.trending_up,
                  ),
                ),
                Expanded(
                  child: _buildAmountColumn(
                    'Expense',
                    currencyFormat.format(expense),
                    Colors.red,
                    Icons.trending_down,
                  ),
                ),
                Expanded(
                  child: _buildAmountColumn(
                    'Balance',
                    currencyFormat.format(balance),
                    balance >= 0 ? Colors.green : Colors.red,
                    balance >= 0 ? Icons.account_balance_wallet : Icons.warning,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartCard(BuildContext context, String title, TransactionProvider transactionProvider) {
    final chartData = transactionProvider.getChartData(title);
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$title Chart',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: _buildChart(context, chartData),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart(BuildContext context, ChartData data) {
    if (data.realIncome.isEmpty && data.realExpenses.isEmpty &&
        data.budgetIncome.isEmpty && data.budgetExpenses.isEmpty) {
      return const Center(child: Text('No chart data available.'));
    }
      
    return LineChart(
      LineChartData(
        gridData: FlGridData(show: true, drawVerticalLine: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) => _leftTitleWidgets(value, meta, data.maxY),
              reservedSize: 50,
            ),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: _bottomTitleWidgets,
              reservedSize: 30,
              interval: 1,
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minY: 0,
        maxY: data.maxY,
        lineBarsData: [
          _buildLineChartBarData(data.realIncome, Colors.green),
          _buildLineChartBarData(data.realExpenses, Colors.red),
          _buildLineChartBarData(data.budgetIncome, Colors.green, isDashed: true),
          _buildLineChartBarData(data.budgetExpenses, Colors.red, isDashed: true),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final currencyFormat = NumberFormat.currency(symbol: '\$');
                return LineTooltipItem(
                  currencyFormat.format(spot.y),
                  TextStyle(
                    color: spot.bar.color,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  Widget _leftTitleWidgets(double value, TitleMeta meta, double maxY) {
    if (value == 0 || value == maxY) return const SizedBox.shrink();
    
    return Text(
      NumberFormat.compact().format(value),
      style: const TextStyle(fontSize: 10),
      textAlign: TextAlign.left,
    );
  }

  Widget _bottomTitleWidgets(double value, TitleMeta meta) {
    final now = DateTime.now();
    final date = now.subtract(Duration(days: 29 - value.toInt()));
    
    if (value.toInt() % 5 == 0) {
      return Text(DateFormat('d MMM').format(date), style: const TextStyle(fontSize: 10));
    } else {
      return const SizedBox.shrink();
    }
  }

  LineChartBarData _buildLineChartBarData(List<FlSpot> spots, Color color, {bool isDashed = false}) {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      color: color,
      barWidth: 3,
      isStrokeCapRound: true,
      dotData: FlDotData(show: false),
      belowBarData: BarAreaData(show: false),
      dashArray: isDashed ? [5, 5] : null,
    );
  }

  Widget _buildAmountColumn(String label, String amount, Color color, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          amount,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionTile(BuildContext context, model.Transaction transaction) {
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    final dateFormat = DateFormat('MMM dd, yyyy');
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: transaction.isIncome ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
          child: Icon(
            transaction.isIncome ? Icons.trending_up : Icons.trending_down,
            color: transaction.isIncome ? Colors.green : Colors.red,
          ),
        ),
        title: Text(
          transaction.title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (transaction.description != null && transaction.description!.isNotEmpty)
              Text(transaction.description!),
            Text(
              dateFormat.format(transaction.date),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              currencyFormat.format(transaction.amount),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: transaction.isIncome ? Colors.green : Colors.red,
              ),
            ),
            if (transaction.category != null)
              Text(
                transaction.category!,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
          ],
        ),
      ),
    );
  }
} 