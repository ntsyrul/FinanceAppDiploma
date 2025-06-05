import 'package:finance_app/models/transaction.dart';
import 'package:finance_app/services/data_service.dart';
import 'package:finance_app/widgets/add_transaction_dialog.dart';
import 'package:flutter/material.dart';


class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({Key? key}) : super(key: key);

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final DataService _dataService = DataService();
  String _filterType = 'all'; 
  String _sortBy = 'date'; 

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

  List<Transaction> get _filteredTransactions {
    var transactions = _dataService.transactions;

    if (_filterType == 'income') {
      transactions = transactions.where((t) => t.type == TransactionType.income).toList();
    } else if (_filterType == 'expense') {
      transactions = transactions.where((t) => t.type == TransactionType.expense).toList();
    }

    switch (_sortBy) {
      case 'date':
        transactions.sort((a, b) => b.date.compareTo(a.date));
        break;
      case 'amount':
        transactions.sort((a, b) => b.amount.compareTo(a.amount));
        break;
      case 'category':
        transactions.sort((a, b) => a.category.compareTo(b.category));
        break;
    }

    return transactions;
  }

  @override
  Widget build(BuildContext context) {
    final transactions = _filteredTransactions;
    final totalIncome = _dataService.transactions
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (sum, t) => sum + t.amount);
    final totalExpense = _dataService.transactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Транзакції'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: (value) {
              setState(() {
                _sortBy = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'date',
                child: Text('Сортувати за датою'),
              ),
              const PopupMenuItem(
                value: 'amount',
                child: Text('Сортувати за сумою'),
              ),
              const PopupMenuItem(
                value: 'category',
                child: Text('Сортувати за категорією'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        title: 'Доходи',
                        amount: totalIncome,
                        color: Colors.green,
                        icon: Icons.trending_up,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        title: 'Витрати',
                        amount: totalExpense,
                        color: Colors.red,
                        icon: Icons.trending_down,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'all',
                      label: Text('Всі'),
                      icon: Icon(Icons.list),
                    ),
                    ButtonSegment(
                      value: 'income',
                      label: Text('Доходи'),
                      icon: Icon(Icons.add_circle_outline),
                    ),
                    ButtonSegment(
                      value: 'expense',
                      label: Text('Витрати'),
                      icon: Icon(Icons.remove_circle_outline),
                    ),
                  ],
                  selected: {_filterType},
                  onSelectionChanged: (Set<String> newSelection) {
                    setState(() {
                      _filterType = newSelection.first;
                    });
                  },
                ),
              ],
            ),
          ),
            Expanded(
            child: transactions.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 64,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _filterType == 'all'
                              ? 'Поки що немає транзакцій'
                              : _filterType == 'income'
                                  ? 'Немає доходів'
                                  : 'Немає витрат',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                        ),
                        const SizedBox(height: 8),
                        const Text('Додайте першу транзакцію'),
                        const SizedBox(height: 24),
                        FilledButton.icon(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => const AddTransactionDialog(),
                            );
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Додати транзакцію'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    itemCount: transactions.length,
                    itemBuilder: (context, index) {
                      final transaction = transactions[index];
                      return _TransactionCard(
                        transaction: transaction,
                        onDelete: () => _deleteTransaction(transaction.id),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _deleteTransaction(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Видалити транзакцію'),
        content: const Text('Ви впевнені, що хочете видалити цю транзакцію?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Скасувати'),
          ),
          FilledButton(
            onPressed: () {
              _dataService.removeTransaction(id);
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Транзакцію видалено'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            child: const Text('Видалити'),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final double amount;
  final Color color;
  final IconData icon;

  const _StatCard({
    Key? key,
    required this.title,
    required this.amount,
    required this.color,
    required this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${amount.toStringAsFixed(0)} грн',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback onDelete;

  const _TransactionCard({
    Key? key,
    required this.transaction,
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
      case 'Освіта':
        return Icons.school;
      case 'Зарплата':
        return Icons.work;
      case 'Бонус':
        return Icons.card_giftcard;
      case 'Інвестиції':
        return Icons.trending_up;
      default:
        return Icons.category;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == TransactionType.income;
    final color = isIncome ? Colors.green : Colors.red;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            _getCategoryIcon(transaction.category),
            color: color,
            size: 24,
          ),
        ),
        title: Text(
          transaction.title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(transaction.category),
            Text(
              '${transaction.date.day.toString().padLeft(2, '0')}.${transaction.date.month.toString().padLeft(2, '0')}.${transaction.date.year}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
            ),
            if (transaction.description != null)
              Text(
                transaction.description!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
              ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${isIncome ? '+' : '-'}${transaction.amount.toStringAsFixed(0)} грн',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
            PopupMenuButton(
              icon: const Icon(Icons.more_vert, size: 20),
              itemBuilder: (context) => [
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
      ),
    );
  }
}