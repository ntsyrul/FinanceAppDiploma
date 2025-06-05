// import 'dart:convert';
import 'dart:math';
import 'package:finance_app/models/transaction.dart';

class DataService {
  static final DataService _instance = DataService._internal();
  factory DataService() => _instance;
  DataService._internal();

  final List<Transaction> _transactions = [];
  
  List<Transaction> get transactions => _transactions;

  void addTransaction(Transaction transaction) {
    _transactions.add(transaction);
    _notifyListeners();
  }

  void removeTransaction(String id) {
    _transactions.removeWhere((t) => t.id == id);
    _notifyListeners();
  }

  double get balance {
    double total = 0;
    for (var transaction in _transactions) {
      if (transaction.type == TransactionType.income) {
        total += transaction.amount;
      } else {
        total -= transaction.amount;
      }
    }
    return total;
  }

  Map<String, double> getExpensesByCategory() {
    Map<String, double> expenses = {};
    for (var transaction in _transactions) {
      if (transaction.type == TransactionType.expense) {
        expenses[transaction.category] = 
          (expenses[transaction.category] ?? 0) + transaction.amount;
      }
    }
    return expenses;
  }

  double getMonthlyExpenses(DateTime month) {
    double total = 0;
    for (var transaction in _transactions) {
      if (transaction.type == TransactionType.expense &&
          transaction.date.year == month.year &&
          transaction.date.month == month.month) {
        total += transaction.amount;
      }
    }
    return total;
  }

  double getMonthlyIncome(DateTime month) {
    double total = 0;
    for (var transaction in _transactions) {
      if (transaction.type == TransactionType.income &&
          transaction.date.year == month.year &&
          transaction.date.month == month.month) {
        total += transaction.amount;
      }
    }
    return total;
  }

  void generateSampleData() {
    _transactions.clear();
    
    final random = Random();
    final categories = ['Їжа', 'Транспорт', 'Розваги', 'Комунальні', 'Покупки'];
    
    _transactions.add(Transaction(
      id: 'income_1',
      title: 'Зарплата',
      amount: 15000,
      category: 'Зарплата',
      date: DateTime.now().subtract(const Duration(days: 5)),
      type: TransactionType.income,
    ));
    
    _transactions.add(Transaction(
      id: 'income_2',
      title: 'Бонус',
      amount: 2000,
      category: 'Бонус',
      date: DateTime.now().subtract(const Duration(days: 15)),
      type: TransactionType.income,
    ));

    for (int i = 0; i < 25; i++) {
      final category = categories[random.nextInt(categories.length)];
      final amount = 50 + random.nextInt(500).toDouble();
      
      _transactions.add(Transaction(
        id: 'expense_$i',
        title: _getTitleForCategory(category),
        amount: amount,
        category: category,
        date: DateTime.now().subtract(Duration(days: random.nextInt(30))),
        type: TransactionType.expense,
      ));
    }
    
    _notifyListeners();
  }

  String _getTitleForCategory(String category) {
    switch (category) {
      case 'Їжа':
        return ['Ресторан', 'Продукти', 'Кафе', 'Доставка'][Random().nextInt(4)];
      case 'Транспорт':
        return ['Метро', 'Таксі', 'Бензин', 'Автобус'][Random().nextInt(4)];
      case 'Розваги':
        return ['Кіно', 'Концерт', 'Ігри', 'Книги'][Random().nextInt(4)];
      case 'Комунальні':
        return ['Електрика', 'Газ', 'Вода', 'Інтернет'][Random().nextInt(4)];
      case 'Покупки':
        return ['Одяг', 'Техніка', 'Дім', 'Подарунки'][Random().nextInt(4)];
      default:
        return 'Витрата';
    }
  }

  final List<VoidCallback> _listeners = [];

  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  void _notifyListeners() {
    for (var listener in _listeners) {
      listener();
    }
  }
}

typedef VoidCallback = void Function();