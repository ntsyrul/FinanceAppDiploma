// lib/screens/statistics.dart
import 'package:finance_app/models/transaction.dart';
import 'package:finance_app/services/data_service.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;


class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({Key? key}) : super(key: key);

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final DataService _dataService = DataService();
  String _selectedPeriod = 'month'; 

  @override
  void initState() {
    super.initState();
    _dataService.addListener(_onDataChanged);
  }

  @override
  void dispose() {
    _dataService.removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Map<String, double> _getFilteredExpenses() {
    final now = DateTime.now();
    final transactions = _dataService.transactions.where((t) {
      if (t.type != TransactionType.expense) return false;
      
      switch (_selectedPeriod) {
        case 'month':
          return t.date.year == now.year && t.date.month == now.month;
        case 'year':
          return t.date.year == now.year;
        case 'all':
        default:
          return true;
      }
    }).toList();

    Map<String, double> expenses = {};
    for (var transaction in transactions) {
      expenses[transaction.category] = 
          (expenses[transaction.category] ?? 0) + transaction.amount;
    }
    return expenses;
  }

  @override
  Widget build(BuildContext context) {
    final expenses = _getFilteredExpenses();
    final totalExpense = expenses.values.fold(0.0, (sum, amount) => sum + amount);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Статистика'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Період',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(
                          value: 'month',
                          label: Text('Місяць'),
                          icon: Icon(Icons.calendar_view_month),
                        ),
                        ButtonSegment(
                          value: 'year',
                          label: Text('Рік'),
                          icon: Icon(Icons.calendar_today),
                        ),
                        ButtonSegment(
                          value: 'all',
                          label: Text('Весь час'),
                          icon: Icon(Icons.all_inclusive),
                        ),
                      ],
                      selected: {_selectedPeriod},
                      onSelectionChanged: (Set<String> newSelection) {
                        setState(() {
                          _selectedPeriod = newSelection.first;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),

            if (expenses.isNotEmpty) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Витрати по категоріях',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 250,
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: CustomPaint(
                                painter: PieChartPainter(expenses, totalExpense),
                                child: const SizedBox.expand(),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: _buildLegend(expenses, totalExpense),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Деталізація витрат',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 16),
                      ...expenses.entries
                          .map((entry) => _buildExpenseItem(
                                entry.key,
                                entry.value,
                                totalExpense,
                              ))
                          .toList(),
                    ],
                  ),
                ),
              ),
            ] else
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.pie_chart_outline,
                          size: 64,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Немає даних для відображення',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Додайте транзакції для перегляду статистики',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend(Map<String, double> expenses, double totalExpense) {
    final colors = _getCategoryColors();
    final sortedEntries = expenses.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: sortedEntries.map((entry) {
        final percentage = (entry.value / totalExpense * 100);
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: colors[entry.key] ?? Colors.grey,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.key,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    Text(
                      '${percentage.toStringAsFixed(1)}%',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildExpenseItem(String category, double amount, double totalExpense) {
    final percentage = (amount / totalExpense * 100);
    final colors = _getCategoryColors();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (colors[category] ?? Colors.grey).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getCategoryIcon(category),
              color: colors[category] ?? Colors.grey,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: percentage / 100,
                  backgroundColor: Colors.grey.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation(colors[category] ?? Colors.grey),
                  minHeight: 4,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${amount.toStringAsFixed(0)} грн',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Їжа':
        return Icons.fastfood;
      case 'Транспорт':
        return Icons.directions_car;
      case 'Розваги':
        return Icons.movie;
      case 'Комунальні':
        return Icons.home;
      case 'Покупки':
        return Icons.shopping_bag;
      case 'Здоров\'я':
        return Icons.local_hospital;
      case 'Освіта':
        return Icons.school;
      default:
        return Icons.category;
    }
  }

  Map<String, Color> _getCategoryColors() {
    return {
      'Їжа': Colors.orange,
      'Транспорт': Colors.blue,
      'Розваги': Colors.purple,
      'Комунальні': Colors.green,
      'Покупки': Colors.pink,
      'Здоров\'я': Colors.red,
      'Освіта': Colors.indigo,
      'Інше': Colors.grey,
    };
  }
}

class PieChartPainter extends CustomPainter {
  final Map<String, double> data;
  final double totalValue;

  PieChartPainter(this.data, this.totalValue);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 20;

    final colors = {
      'Їжа': Colors.orange,
      'Транспорт': Colors.blue,
      'Розваги': Colors.purple,
      'Комунальні': Colors.green,
      'Покупки': Colors.pink,
      'Здоров\'я': Colors.red,
      'Освіта': Colors.indigo,
      'Інше': Colors.grey,
    };

    double startAngle = -math.pi / 2;
    
    for (final entry in data.entries) {
      final sweepAngle = (entry.value / totalValue) * 2 * math.pi;
      
      final paint = Paint()
        ..color = colors[entry.key] ?? Colors.grey
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );
      final borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        borderPaint,
      );

      startAngle += sweepAngle;
    }
    final innerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius * 0.4, innerPaint);
    final textPainter = TextPainter(
      text: TextSpan(
        text: '${totalValue.toStringAsFixed(0)}\nгрн',
        style: const TextStyle(
          color: Colors.black,
          fontSize: 16,
          fontWeight: FontWeight.bold,
          height: 1.2,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}