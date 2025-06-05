class Category {
  final String name;
  final String icon;
  final int color;

  const Category({
    required this.name,
    required this.icon,
    required this.color,
  });
}

class Categories {
  static const List<Category> expense = [
    Category(name: 'Їжа', icon: 'fastfood', color: 0xFFFF5722),
    Category(name: 'Транспорт', icon: 'directions_car', color: 0xFF2196F3),
    Category(name: 'Розваги', icon: 'movie', color: 0xFF9C27B0),
    Category(name: 'Комунальні', icon: 'home', color: 0xFF4CAF50),
    Category(name: 'Покупки', icon: 'shopping_bag', color: 0xFFFF9800),
    Category(name: 'Здоров\'я', icon: 'local_hospital', color: 0xFFF44336),
    Category(name: 'Освіта', icon: 'school', color: 0xFF607D8B),
    Category(name: 'Інше', icon: 'category', color: 0xFF795548),
  ];

  static const List<Category> income = [
    Category(name: 'Зарплата', icon: 'work', color: 0xFF4CAF50),
    Category(name: 'Бонус', icon: 'card_giftcard', color: 0xFF2196F3),
    Category(name: 'Інвестиції', icon: 'trending_up', color: 0xFF9C27B0),
    Category(name: 'Інше', icon: 'attach_money', color: 0xFF607D8B),
  ];
}