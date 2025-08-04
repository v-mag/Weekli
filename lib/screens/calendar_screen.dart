import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../providers/transaction_provider.dart';
import '../models/transaction.dart' as model;
import '../theme/app_theme.dart';

enum CalendarView { month, week, trimester }

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  CalendarView _selectedView = CalendarView.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
        ],
      ),
      body: Consumer<TransactionProvider>(
        builder: (context, provider, child) {
          final transactionsByDay = provider.getTransactionsByDay();
          
          return Column(
            children: [
              if (_selectedView != CalendarView.trimester)
                Card(
                  margin: const EdgeInsets.all(8.0),
                  child: TableCalendar<model.Transaction>(
                    firstDay: DateTime.utc(2020, 1, 1),
                    lastDay: DateTime.utc(2030, 12, 31),
                    focusedDay: _focusedDay,
                    calendarFormat: _calendarFormat,
                    eventLoader: (day) {
                      return transactionsByDay[DateTime(day.year, day.month, day.day)] ?? [];
                    },
                    startingDayOfWeek: StartingDayOfWeek.monday,
                    calendarStyle: CalendarStyle(
                      outsideDaysVisible: false,
                      weekendTextStyle: const TextStyle(color: Colors.red),
                      holidayTextStyle: const TextStyle(color: Colors.red),
                      defaultTextStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                      // Today's date styling
                      todayDecoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      todayTextStyle: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                      // Selected day styling
                      selectedDecoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        shape: BoxShape.circle,
                      ),
                      selectedTextStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    headerStyle: HeaderStyle(
                      // Header text styling
                      titleTextStyle: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      // Format button styling (Month/Week toggle)
                      formatButtonTextStyle: TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                      formatButtonDecoration: BoxDecoration(
                        border: Border.all(color: AppTheme.primaryColor),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      // Navigation arrows
                      leftChevronIcon: Icon(
                        Icons.chevron_left,
                        color: AppTheme.primaryColor,
                      ),
                      rightChevronIcon: Icon(
                        Icons.chevron_right,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    onDaySelected: (selectedDay, focusedDay) {
                      if (!isSameDay(_selectedDay, selectedDay)) {
                        setState(() {
                          _selectedDay = selectedDay;
                          _focusedDay = focusedDay;
                        });
                        provider.setSelectedDate(selectedDay);
                      }
                    },
                    selectedDayPredicate: (day) {
                      return isSameDay(_selectedDay, day);
                    },
                    onFormatChanged: (format) {
                      if (_calendarFormat != format) {
                        setState(() {
                          _calendarFormat = format;
                        });
                      }
                    },
                    onPageChanged: (focusedDay) {
                      _focusedDay = focusedDay;
                    },
                    calendarBuilders: CalendarBuilders(
                      markerBuilder: (context, day, events) {
                        if (events.isNotEmpty) {
                          return Positioned(
                            right: 1,
                            bottom: 1,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: AppTheme.primaryColor,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '${events.length}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        }
                        return null;
                      },
                    ),
                  ),
                )
              else
                _buildTrimesterView(provider),
              
              const SizedBox(height: 8),
              
              // Selected day transactions
              Expanded(
                child: _buildTransactionsList(provider),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTrimesterView(TransactionProvider provider) {
    final now = DateTime.now();
    final months = List.generate(3, (index) => DateTime(now.year, now.month - 1 + index, 1));
    
    return SizedBox(
      height: 300,
      child: Row(
        children: months.map((month) => Expanded(
          child: Card(
            margin: const EdgeInsets.all(4),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    DateFormat('MMMM yyyy').format(month),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Expanded(
                  child: _buildMonthGrid(month, provider),
                ),
              ],
            ),
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildMonthGrid(DateTime month, TransactionProvider provider) {
    final transactionsByDay = provider.getTransactionsByDay();
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final firstDayWeekday = DateTime(month.year, month.month, 1).weekday;
    
    return GridView.builder(
      padding: const EdgeInsets.all(4),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1,
      ),
      itemCount: daysInMonth + firstDayWeekday - 1,
      itemBuilder: (context, index) {
        if (index < firstDayWeekday - 1) {
          return Container(); // Empty space for days before month starts
        }
        
        final day = index - firstDayWeekday + 2;
        final date = DateTime(month.year, month.month, day);
        final transactions = transactionsByDay[date] ?? [];
        
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedDay = date;
              _focusedDay = date;
            });
            provider.setSelectedDate(date);
          },
          child: Container(
            margin: const EdgeInsets.all(1),
            decoration: BoxDecoration(
              color: isSameDay(_selectedDay, date) ? AppTheme.primaryColor.withOpacity(0.3) : null,
              border: Border.all(color: Colors.grey.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Stack(
              children: [
                Center(
                  child: Text(
                    '$day',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSameDay(_selectedDay, date) ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
                if (transactions.isNotEmpty)
                  Positioned(
                    right: 2,
                    bottom: 2,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTransactionsList(TransactionProvider provider) {
    if (_selectedDay == null) {
      return const Center(child: Text('Select a day to view transactions'));
    }

    final selectedDayTransactions = provider.getTransactionsForDateRange(
      DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day),
      DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day, 23, 59, 59),
    );

    if (selectedDayTransactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_note, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 8),
            Text(
              'No transactions on ${DateFormat('MMM dd, yyyy').format(_selectedDay!)}',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: selectedDayTransactions.length,
      itemBuilder: (context, index) {
        final transaction = selectedDayTransactions[index];
        return _buildTransactionTile(transaction);
      },
    );
  }

  Widget _buildTransactionTile(model.Transaction transaction) {
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: transaction.isIncome 
              ? Colors.green.withOpacity(0.1) 
              : Colors.red.withOpacity(0.1),
          child: Icon(
            transaction.isIncome ? Icons.trending_up : Icons.trending_down,
            color: transaction.isIncome ? Colors.green : Colors.red,
          ),
        ),
        title: Text(
          transaction.title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: transaction.description?.isNotEmpty == true 
            ? Text(transaction.description!)
            : null,
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