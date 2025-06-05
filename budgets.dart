import 'package:finance_app/models/transaction.dart';
import 'package:finance_app/services/data_service.dart';
import 'package:flutter/material.dart';


class BudgetsScreen extends StatefulWidget {
  const BudgetsScreen({Key? key}) : super(key: key);

  @override
  State<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends State<BudgetsScreen> {
  final DataService _dataService = DataService();

  final Map<String, double> _budgets = {
    'Їжа': 3000,
    'Транспорт': 800,
    'Розваги': 1200,
    'Комунальні': 1500,
    'Покупки': 2000,
    'Здоров\'я': 1000,
  };

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

  Map<String, double> _getCurrentMonthExpenses() {
    final now = DateTime.now();
    final monthlyTransactions = _dataService.transactions.where((t) =>
        t.type == TransactionType.expense &&
        t.date.year == now.year &&
        t.date.month == now.month);

    Map<String, double> expenses = {};
    for (var transaction in monthlyTransactions) {
      expenses[transaction.category] =
          (expenses[transaction.category] ?? 0) + transaction.amount;
    }
    return expenses;
  }

  @override
  Widget build(BuildContext context) {
    final currentExpenses = _getCurrentMonthExpenses();
    final now = DateTime.now();
    final monthName = _getMonthName(now.month);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Бюджети'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddBudgetDialog(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_month,
                      color: Theme.of(context).colorScheme.primary,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Бюджет на $monthName ${now.year}',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Відстежуйте свої витрати по категоріях',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            _buildOverallStats(currentExpenses),
            
            const SizedBox(height: 16),
            ...(_budgets.entries.map((entry) {
              final category = entry.key;
              final budgetLimit = entry.value;
              final spent = currentExpenses[category] ?? 0;
              final progress = spent / budgetLimit;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _BudgetCard(
                  category: category,
                  spent: spent,
                  limit: budgetLimit,
                  progress: progress,
                  onEdit: () => _showEditBudgetDialog(category, budgetLimit),
                  onDelete: () => _deleteBudget(category),
                ),
              );
            }).toList()),
            Card(
              child: InkWell(
                onTap: () => _showAddBudgetDialog(),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.add,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Додати новий бюджет',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
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

  Widget _buildOverallStats(Map<String, double> currentExpenses) {
    final totalBudget = _budgets.values.fold(0.0, (sum, amount) => sum + amount);
    final totalSpent = currentExpenses.values.fold(0.0, (sum, amount) => sum + amount);
    final remaining = totalBudget - totalSpent;
    final overallProgress = totalSpent / totalBudget;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Загальний огляд',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _StatItem(
                    title: 'Загальний бюджет',
                    amount: totalBudget,
                    color: Colors.blue,
                  ),
                ),
                Expanded(
                  child: _StatItem(
                    title: 'Витрачено',
                    amount: totalSpent,
                    color: Colors.orange,
                  ),
                ),
                Expanded(
                  child: _StatItem(
                    title: 'Залишилось',
                    amount: remaining,
                    color: remaining >= 0 ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            LinearProgressIndicator(
              value: overallProgress.clamp(0.0, 1.0),
              backgroundColor: Colors.grey.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation(
                overallProgress >= 1.0 ? Colors.red : 
                overallProgress >= 0.8 ? Colors.orange : Colors.green,
              ),
              minHeight: 8,
            ),
            
            const SizedBox(height: 8),
            
            Text(
              'Використано ${(overallProgress * 100).toStringAsFixed(1)}% бюджету',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddBudgetDialog() {
    showDialog(
      context: context,
      builder: (context) => _BudgetDialog(
        title: 'Додати бюджет',
        onSave: (category, amount) {
          setState(() {
            _budgets[category] = amount;
          });
        },
      ),
    );
  }

  void _showEditBudgetDialog(String category, double currentAmount) {
    showDialog(
      context: context,
      builder: (context) => _BudgetDialog(
        title: 'Редагувати бюджет',
        initialCategory: category,
        initialAmount: currentAmount,
        onSave: (newCategory, amount) {
          setState(() {
            if (newCategory != category) {
              _budgets.remove(category);
            }
            _budgets[newCategory] = amount;
          });
        },
      ),
    );
  }

  void _deleteBudget(String category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Видалити бюджет'),
        content: Text('Ви впевнені, що хочете видалити бюджет для категорії "$category"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Скасувати'),
          ),
          FilledButton(
            onPressed: () {
              setState(() {
                _budgets.remove(category);
              });
              Navigator.of(context).pop();
            },
            child: const Text('Видалити'),
          ),
        ],
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'Січень', 'Лютий', 'Березень', 'Квітень', 'Травень', 'Червень',
      'Липень', 'Серпень', 'Вересень', 'Жовтень', 'Листопад', 'Грудень'
    ];
    return months[month - 1];
  }
}

class _StatItem extends StatelessWidget {
  final String title;
  final double amount;
  final Color color;

  const _StatItem({
    Key? key,
    required this.title,
    required this.amount,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          '${amount.toStringAsFixed(0)} грн',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _BudgetCard extends StatelessWidget {
  final String category;
  final double spent;
  final double limit;
  final double progress;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _BudgetCard({
    Key? key,
    required this.category,
    required this.spent,
    required this.limit,
    required this.progress,
    required this.onEdit,
    required this.onDelete,
  }) : super(key: key);

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
      default:
        return Icons.category;
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color statusColor = progress >= 1.0
        ? Colors.red
        : progress >= 0.8
            ? Colors.orange
            : Colors.green;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getCategoryIcon(category),
                    color: statusColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        '${spent.toStringAsFixed(0)} з ${limit.toStringAsFixed(0)} грн',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton(
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      onTap: onEdit,
                      child: const Row(
                        children: [
                          Icon(Icons.edit_outlined),
                          SizedBox(width: 8),
                          Text('Редагувати'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      onTap: onDelete,
                      child: const Row(
                        children: [
                          Icon(Icons.delete_outline, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Видалити'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: Colors.grey.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation(statusColor),
              minHeight: 8,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${(progress * 100).toStringAsFixed(1)}% використано',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                ),
                if (progress >= 1.0)
                  Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'Перевищено на ${(spent - limit).toStringAsFixed(0)} грн',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.red,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  )
                else
                  Text(
                    'Залишилось ${(limit - spent).toStringAsFixed(0)} грн',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BudgetDialog extends StatefulWidget {
  final String title;
  final String? initialCategory;
  final double? initialAmount;
  final Function(String category, double amount) onSave;

  const _BudgetDialog({
    Key? key,
    required this.title,
    this.initialCategory,
    this.initialAmount,
    required this.onSave,
  }) : super(key: key);

  @override
  State<_BudgetDialog> createState() => _BudgetDialogState();
}

class _BudgetDialogState extends State<_BudgetDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  String _selectedCategory = 'Їжа';

  final List<String> _categories = [
    'Їжа', 'Транспорт', 'Розваги', 'Комунальні', 'Покупки', 'Здоров\'я', 'Освіта', 'Інше'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialCategory != null) {
      _selectedCategory = widget.initialCategory!;
    }
    if (widget.initialAmount != null) {
      _amountController.text = widget.initialAmount!.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Категорія',
                border: OutlineInputBorder(),
              ),
              items: _categories
                  .map((category) => DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Сума бюджету',
                border: OutlineInputBorder(),
                suffixText: 'грн',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Введіть суму бюджету';
                }
                final amount = double.tryParse(value);
                if (amount == null || amount <= 0) {
                  return 'Введіть коректну суму';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Скасувати'),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              widget.onSave(_selectedCategory, double.parse(_amountController.text));
              Navigator.of(context).pop();
            }
          },
          child: const Text('Зберегти'),
        ),
      ],
    );
  }
}