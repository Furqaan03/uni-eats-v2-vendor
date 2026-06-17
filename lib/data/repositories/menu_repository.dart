import '../models/menu_item.dart';

class MenuRepository {
  static final List<MenuItem> _items = [
    MenuItem(id: 'm1', name: 'Chicken Shawarma Wrap', description: 'Marinated chicken, garlic sauce, pickles, in warm bread', price: 28.00, category: 'Wraps & Sandwiches', tags: ['Featured', 'Best Seller', 'Halal'], prepMinutes: 8, calories: 620),
    MenuItem(id: 'm2', name: 'Beef Burger Combo', description: 'Smash beef patty, cheddar, caramelised onions, special sauce', price: 35.00, category: 'Burgers', tags: ['Featured', 'Top Rated'], prepMinutes: 12, calories: 780),
    MenuItem(id: 'm3', name: 'Veggie Burger', description: 'Crispy falafel patty, tahini, fresh veg, brioche bun', price: 24.00, category: 'Burgers', tags: ['Vegetarian'], prepMinutes: 10, calories: 510),
    MenuItem(id: 'm4', name: 'Grilled Chicken Plate', description: 'Herb-marinated grilled chicken with rice and salad', price: 32.00, category: 'Mains', tags: ['Halal', 'Chef\'s Special'], prepMinutes: 15, calories: 650),
    MenuItem(id: 'm5', name: 'Falafel Wrap', description: 'Crispy falafel, hummus, tabbouleh, chilli sauce', price: 18.00, category: 'Wraps & Sandwiches', tags: ['Vegan', 'Halal'], prepMinutes: 6, calories: 480),
    MenuItem(id: 'm6', name: 'Caesar Salad', description: 'Romaine, parmesan, croutons, anchovy-free Caesar dressing', price: 18.00, category: 'Salads', tags: ['Vegetarian'], prepMinutes: 5, calories: 320),
    MenuItem(id: 'm7', name: 'Mixed Salad', description: 'Garden fresh vegetables, olive oil and lemon dressing', price: 16.00, category: 'Salads', tags: ['Vegan', 'Gluten Free'], prepMinutes: 4, calories: 210),
    MenuItem(id: 'm8', name: 'Hummus Plate', description: 'Creamy hummus, olive oil, paprika, served with pita', price: 15.00, category: 'Starters', tags: ['Vegan', 'Halal'], prepMinutes: 3, calories: 380),
    MenuItem(id: 'm9', name: 'Large Fries', description: 'Crispy seasoned fries, ketchup', price: 12.00, category: 'Sides', tags: ['Vegan', 'Gluten Free'], prepMinutes: 6, calories: 420),
    MenuItem(id: 'm10', name: 'Onion Rings', description: 'Beer-battered onion rings with dipping sauce', price: 14.00, category: 'Sides', tags: [], prepMinutes: 7, calories: 390),
    MenuItem(id: 'm11', name: 'Fresh Orange Juice', description: 'Freshly squeezed, served chilled', price: 14.00, category: 'Drinks', tags: ['New'], prepMinutes: 2, calories: 120),
    MenuItem(id: 'm12', name: 'Milkshake', description: 'Choice of chocolate, vanilla or strawberry', price: 18.00, category: 'Drinks', tags: ['Top Rated'], prepMinutes: 4, calories: 450),
    MenuItem(id: 'm13', name: 'Pepsi Can', description: '330ml chilled can', price: 5.00, category: 'Drinks', tags: [], prepMinutes: 1, calories: 140),
    MenuItem(id: 'm14', name: 'Water Bottle', description: '500ml still water', price: 4.00, category: 'Drinks', tags: [], prepMinutes: 1, calories: 0),
    MenuItem(id: 'm15', name: 'Chocolate Lava Cake', description: 'Warm chocolate cake, vanilla ice cream', price: 22.00, category: 'Desserts', tags: [], prepMinutes: 10, calories: 580, isAvailable: false),
  ];

  List<MenuItem> getAll() => List.from(_items);

  List<String> getCategories() {
    final seen = <String>{};
    return _items.map((i) => i.category).where(seen.add).toList();
  }

  List<MenuItem> getByCategory(String category) =>
      _items.where((i) => i.category == category).toList();

  List<MenuItem> getFeatured() => _items.where((i) => i.isFeatured).toList();
}
