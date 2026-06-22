import '../models/menu_item.dart';

/// Centralised menu data for all restaurants.
/// IDs follow the pattern <restaurantId>_<index> so they match the user app.
class MenuRepository {
  static final Map<String, List<MenuItem>> _byRestaurant = {
    // ── Tim Hortons (r001) ────────────────────────────────────────────────
    'r001': [
      MenuItem(id: 'r001_m01', name: 'Original Blend Coffee', description: 'Freshly brewed medium-roast blend, served hot', price: 10.50, category: 'Coffee', tags: ['Best Seller'], prepMinutes: 2, calories: 5),
      MenuItem(id: 'r001_m02', name: 'Double Double', description: 'Classic coffee with two creams and two sugars', price: 12.00, category: 'Coffee', tags: ['Featured', 'Best Seller'], prepMinutes: 2, calories: 130),
      MenuItem(id: 'r001_m03', name: 'French Vanilla Cappuccino', description: 'Smooth espresso blended with sweet French vanilla', price: 15.00, category: 'Coffee', tags: ['Featured'], prepMinutes: 3, calories: 200),
      MenuItem(id: 'r001_m04', name: 'Iced Capp', description: 'Creamy blended iced coffee — refreshingly thick', price: 16.00, category: 'Cold Drinks', tags: ['Featured', 'Top Rated'], prepMinutes: 3, calories: 250),
      MenuItem(id: 'r001_m05', name: 'Steeped Tea', description: 'Premium black tea steeped fresh, served hot or iced', price: 10.00, category: 'Drinks', tags: [], prepMinutes: 2, calories: 0),
      MenuItem(id: 'r001_m06', name: 'Boston Cream Donut', description: 'Yeast donut filled with vanilla custard, dipped in chocolate glaze', price: 7.00, category: 'Bakery', tags: ['Best Seller'], prepMinutes: 1, calories: 290),
      MenuItem(id: 'r001_m07', name: 'Honey Glazed Donut', description: 'Classic ring donut with a sweet honey glaze', price: 6.00, category: 'Bakery', tags: [], prepMinutes: 1, calories: 250),
      MenuItem(id: 'r001_m08', name: 'Chocolate Glazed Donut', description: 'Yeast donut topped with rich chocolate glaze', price: 6.00, category: 'Bakery', tags: [], prepMinutes: 1, calories: 270),
      MenuItem(id: 'r001_m09', name: 'Timbits (10 Pack)', description: 'Ten bite-sized assorted donut holes — mix of glazed, chocolate & honey', price: 12.00, category: 'Bakery', tags: ['Featured'], prepMinutes: 1, calories: 420),
      MenuItem(id: 'r001_m10', name: 'Turkey BLT Sandwich', description: 'Sliced turkey, bacon, lettuce & tomato on a toasted bagel', price: 25.00, category: 'Food', tags: [], prepMinutes: 5, calories: 490),
      MenuItem(id: 'r001_m11', name: 'Grilled Chicken Wrap', description: 'Herb-marinated chicken, lettuce, tomato & ranch sauce in a flour tortilla', price: 28.00, category: 'Food', tags: ['New'], prepMinutes: 6, calories: 520),
      MenuItem(id: 'r001_m12', name: 'Blueberry Muffin', description: 'Freshly baked, loaded with blueberries', price: 9.00, category: 'Bakery', tags: [], prepMinutes: 1, calories: 340),
    ],

    // ── Oakberry (r002) ───────────────────────────────────────────────────
    'r002': [
      MenuItem(id: 'r002_m01', name: 'Original Açaí Bowl', description: 'Blended açaí, granola, sliced banana & drizzle of honey', price: 28.00, category: 'Bowls', tags: ['Featured', 'Best Seller'], prepMinutes: 5, calories: 420),
      MenuItem(id: 'r002_m02', name: 'Protein Power Bowl', description: 'Açaí blended with whey protein, granola, banana & mixed berries', price: 34.00, category: 'Bowls', tags: ['Featured', 'Top Rated'], prepMinutes: 5, calories: 510),
      MenuItem(id: 'r002_m03', name: 'Tropical Açaí Bowl', description: 'Açaí, mango chunks, pineapple, coconut flakes & granola', price: 30.00, category: 'Bowls', tags: ['Featured'], prepMinutes: 5, calories: 440),
      MenuItem(id: 'r002_m04', name: 'Mango Pitaya Bowl', description: 'Dragon fruit & mango blend, kiwi, granola & chia seeds', price: 32.00, category: 'Bowls', tags: ['New'], prepMinutes: 5, calories: 380),
      MenuItem(id: 'r002_m05', name: 'Green Detox Smoothie', description: 'Spinach, green apple, cucumber, ginger & lemon juice', price: 22.00, category: 'Drinks', tags: [], prepMinutes: 4, calories: 140),
      MenuItem(id: 'r002_m06', name: 'Mixed Berry Smoothie', description: 'Strawberry, blueberry & raspberry blended with coconut water', price: 22.00, category: 'Drinks', tags: ['Top Rated'], prepMinutes: 4, calories: 160),
      MenuItem(id: 'r002_m07', name: 'Granola Pot', description: 'Layers of Greek yoghurt, crunchy granola & fresh berries', price: 16.00, category: 'Snacks', tags: [], prepMinutes: 2, calories: 280),
      MenuItem(id: 'r002_m08', name: 'Guaraná Soda', description: 'Brazilian guaraná-flavoured sparkling drink, 330 ml', price: 9.00, category: 'Drinks', tags: [], prepMinutes: 1, calories: 120),
    ],

    // ── Edge Cafe (r003) ──────────────────────────────────────────────────
    'r003': [
      MenuItem(id: 'r003_m01', name: 'Spanish Latte', description: 'Double espresso poured over sweet condensed milk & fresh milk', price: 18.00, category: 'Coffee', tags: ['Featured', 'Best Seller'], prepMinutes: 4, calories: 210),
      MenuItem(id: 'r003_m02', name: 'Flat White', description: 'Double ristretto with velvety steamed microfoam', price: 16.00, category: 'Coffee', tags: [], prepMinutes: 3, calories: 120),
      MenuItem(id: 'r003_m03', name: 'Iced Matcha Latte', description: 'Premium Japanese matcha whisked with oat milk over ice', price: 20.00, category: 'Cold Drinks', tags: ['New'], prepMinutes: 4, calories: 180),
      MenuItem(id: 'r003_m04', name: 'Iced Latte', description: 'Double espresso over ice with cold full-cream milk', price: 19.00, category: 'Cold Drinks', tags: ['Top Rated'], prepMinutes: 3, calories: 150),
      MenuItem(id: 'r003_m05', name: 'Cappuccino', description: 'Classic espresso with rich steamed foam', price: 15.00, category: 'Coffee', tags: [], prepMinutes: 3, calories: 100),
      MenuItem(id: 'r003_m06', name: 'Avocado Toast', description: 'Smashed avocado on sourdough, topped with a poached egg & chilli flakes', price: 24.00, category: 'Food', tags: ['Featured'], prepMinutes: 8, calories: 420),
      MenuItem(id: 'r003_m07', name: 'Butter Croissant', description: 'Freshly baked, flaky all-butter pastry', price: 9.00, category: 'Bakery', tags: [], prepMinutes: 1, calories: 280),
      MenuItem(id: 'r003_m08', name: 'Club Sandwich', description: 'Triple-decker with chicken, turkey, lettuce, tomato & mayo on toast', price: 26.00, category: 'Food', tags: ['Top Rated'], prepMinutes: 8, calories: 560),
      MenuItem(id: 'r003_m09', name: 'Granola Bowl', description: 'Yoghurt base with mixed berries, honey & crunchy granola', price: 18.00, category: 'Food', tags: [], prepMinutes: 3, calories: 310),
    ],

    // ── Caribou Coffee (r004) ─────────────────────────────────────────────
    'r004': [
      MenuItem(id: 'r004_m01', name: 'Campfire Mocha', description: 'Espresso, dark chocolate & toasted marshmallow syrup with steamed milk', price: 20.00, category: 'Coffee', tags: ['Featured', 'Best Seller'], prepMinutes: 4, calories: 310),
      MenuItem(id: 'r004_m02', name: 'Caramel Macchiato', description: 'Vanilla-sweetened espresso with caramel drizzle & steamed milk', price: 22.00, category: 'Coffee', tags: ['Featured', 'Top Rated'], prepMinutes: 4, calories: 270),
      MenuItem(id: 'r004_m03', name: 'Iced Cold Press', description: 'Slow-steeped cold brew, bold & smooth over ice', price: 16.00, category: 'Cold Drinks', tags: [], prepMinutes: 2, calories: 20),
      MenuItem(id: 'r004_m04', name: 'White Chocolate Mocha', description: 'Espresso with white chocolate sauce & velvety steamed milk', price: 21.00, category: 'Coffee', tags: [], prepMinutes: 4, calories: 340),
      MenuItem(id: 'r004_m05', name: 'Snickerdoodle Latte', description: 'Espresso with cinnamon-vanilla syrup & steamed milk', price: 22.00, category: 'Coffee', tags: ['New'], prepMinutes: 4, calories: 260),
      MenuItem(id: 'r004_m06', name: 'Chai Tea Latte', description: 'Spiced chai concentrate with steamed milk', price: 19.00, category: 'Drinks', tags: [], prepMinutes: 3, calories: 240),
      MenuItem(id: 'r004_m07', name: 'Blueberry Muffin', description: 'Moist muffin bursting with blueberries', price: 12.00, category: 'Bakery', tags: [], prepMinutes: 1, calories: 380),
      MenuItem(id: 'r004_m08', name: 'Chocolate Chip Cookie', description: 'Freshly baked, chewy with premium chocolate chips', price: 8.00, category: 'Bakery', tags: [], prepMinutes: 1, calories: 280),
    ],

    // ── JamKai (r005) ─────────────────────────────────────────────────────
    'r005': [
      MenuItem(id: 'r005_m01', name: 'Teriyaki Chicken Bowl', description: 'Grilled teriyaki chicken over steamed rice with mixed vegetables & sesame', price: 26.00, category: 'Bowls', tags: ['Featured', 'Best Seller'], prepMinutes: 12, calories: 620),
      MenuItem(id: 'r005_m02', name: 'Crispy Gyoza (6 pcs)', description: 'Pan-fried pork & cabbage dumplings with ponzu dipping sauce', price: 18.00, category: 'Starters', tags: ['Top Rated'], prepMinutes: 8, calories: 330),
      MenuItem(id: 'r005_m03', name: 'Ramen Noodles', description: 'Rich miso broth with noodles, soft-boiled egg, sweetcorn & nori', price: 30.00, category: 'Noodles', tags: ['Featured'], prepMinutes: 15, calories: 680),
      MenuItem(id: 'r005_m04', name: 'Pad Thai', description: 'Stir-fried rice noodles with egg, bean sprouts, peanuts & tamarind sauce', price: 28.00, category: 'Noodles', tags: [], prepMinutes: 12, calories: 650),
      MenuItem(id: 'r005_m05', name: 'Edamame', description: 'Salted steamed soybeans — light & protein-packed', price: 12.00, category: 'Starters', tags: ['Vegan'], prepMinutes: 4, calories: 155),
      MenuItem(id: 'r005_m06', name: 'Bubble Tea — Brown Sugar', description: 'Fresh milk with brown sugar syrup & chewy tapioca pearls', price: 16.00, category: 'Drinks', tags: ['Featured', 'Top Rated'], prepMinutes: 5, calories: 320),
      MenuItem(id: 'r005_m07', name: 'Bubble Tea — Taro', description: 'Creamy taro milk tea with tapioca pearls', price: 16.00, category: 'Drinks', tags: ['New'], prepMinutes: 5, calories: 300),
      MenuItem(id: 'r005_m08', name: 'Tom Yum Soup', description: 'Spicy & sour Thai broth with shrimp, mushrooms & lemongrass', price: 22.00, category: 'Starters', tags: [], prepMinutes: 8, calories: 180),
      MenuItem(id: 'r005_m09', name: 'Spring Rolls (4 pcs)', description: 'Crispy vegetable spring rolls with sweet chilli dipping sauce', price: 15.00, category: 'Starters', tags: ['Vegan'], prepMinutes: 6, calories: 260),
    ],

    // ── Bold Café (r006) ──────────────────────────────────────────────────
    'r006': [
      MenuItem(id: 'r006_m01', name: 'Chicken Panini', description: 'Grilled chicken breast, mozzarella, sun-dried tomato pesto — pressed hot', price: 22.00, category: 'Food', tags: ['Featured', 'Best Seller'], prepMinutes: 8, calories: 540),
      MenuItem(id: 'r006_m02', name: 'Club Sandwich', description: 'Triple-decker with turkey, bacon, egg, lettuce, tomato & mayo', price: 24.00, category: 'Food', tags: ['Top Rated'], prepMinutes: 8, calories: 580),
      MenuItem(id: 'r006_m03', name: 'Caesar Salad', description: 'Romaine hearts, parmesan, croutons & bold Caesar dressing', price: 19.00, category: 'Healthy', tags: [], prepMinutes: 5, calories: 340),
      MenuItem(id: 'r006_m04', name: 'Crispy Beef Wrap', description: 'Seasoned beef strips, caramelised onion & garlic aioli in a warm tortilla', price: 26.00, category: 'Food', tags: [], prepMinutes: 8, calories: 590),
      MenuItem(id: 'r006_m05', name: 'Latte', description: 'Double espresso with silky steamed milk', price: 16.00, category: 'Coffee', tags: [], prepMinutes: 3, calories: 130),
      MenuItem(id: 'r006_m06', name: 'Iced Americano', description: 'Double espresso over ice with cold water', price: 14.00, category: 'Cold Drinks', tags: [], prepMinutes: 2, calories: 15),
      MenuItem(id: 'r006_m07', name: 'Cheesecake Slice', description: 'New York-style baked cheesecake on a graham cracker base', price: 18.00, category: 'Desserts', tags: ['Top Rated'], prepMinutes: 2, calories: 450),
      MenuItem(id: 'r006_m08', name: 'Fresh Fruit Salad', description: 'Seasonal mixed fruits with a light honey-mint dressing', price: 15.00, category: 'Healthy', tags: ['Vegan'], prepMinutes: 3, calories: 140),
    ],

    // ── L'Hardy (r007) ────────────────────────────────────────────────────
    'r007': [
      MenuItem(id: 'r007_m01', name: 'Machboos Dajaj', description: 'Traditional spiced basmati rice slow-cooked with tender chicken, dried lemon & rose water', price: 35.00, category: 'Mains', tags: ['Featured', 'Best Seller'], prepMinutes: 20, calories: 780),
      MenuItem(id: 'r007_m02', name: 'Machboos Laham', description: 'Fragrant spiced rice with slow-cooked lamb, baharat & caramelised onions', price: 45.00, category: 'Mains', tags: ['Featured', 'Chef\'s Special'], prepMinutes: 25, calories: 950),
      MenuItem(id: 'r007_m03', name: 'Harees', description: 'Slow-cooked cracked wheat & tender lamb blended to a creamy porridge', price: 28.00, category: 'Mains', tags: [], prepMinutes: 15, calories: 620),
      MenuItem(id: 'r007_m04', name: 'Thareed', description: 'Layered Qatari bread soaked in rich lamb & vegetable stew', price: 30.00, category: 'Mains', tags: [], prepMinutes: 18, calories: 700),
      MenuItem(id: 'r007_m05', name: 'Balaleet', description: 'Sweet saffron vermicelli with a savoury egg omelette — a classic Qatari breakfast', price: 18.00, category: 'Starters', tags: ['New'], prepMinutes: 10, calories: 380),
      MenuItem(id: 'r007_m06', name: 'Luqaimat (10 pcs)', description: 'Deep-fried dough balls drizzled with date syrup & sesame seeds', price: 15.00, category: 'Desserts', tags: ['Top Rated'], prepMinutes: 8, calories: 420),
      MenuItem(id: 'r007_m07', name: 'Chai Karak', description: 'Strong milky spiced tea brewed with cardamom, saffron & evaporated milk', price: 8.00, category: 'Drinks', tags: ['Best Seller'], prepMinutes: 4, calories: 110),
      MenuItem(id: 'r007_m08', name: 'Dates & Cream', description: 'Medjool dates served with whipped cream & crushed pistachios', price: 22.00, category: 'Desserts', tags: [], prepMinutes: 3, calories: 340),
    ],

    // ── Ennabi 92 (r008) ──────────────────────────────────────────────────
    'r008': [
      MenuItem(id: 'r008_m01', name: 'Machboos Dajaj', description: 'Ennabi-style spiced rice with juicy chicken, dried lime & mixed spices', price: 35.00, category: 'Mains', tags: ['Featured', 'Best Seller'], prepMinutes: 20, calories: 780),
      MenuItem(id: 'r008_m02', name: 'Jareesh', description: 'Crushed wheat cooked down with chicken broth, butter & fried onions', price: 30.00, category: 'Mains', tags: ['Featured'], prepMinutes: 18, calories: 650),
      MenuItem(id: 'r008_m03', name: 'Saloona Khadra', description: 'Hearty vegetable & chicken stew with tomatoes, turmeric & coriander', price: 28.00, category: 'Mains', tags: [], prepMinutes: 15, calories: 520),
      MenuItem(id: 'r008_m04', name: 'Shakshuka', description: 'Eggs poached in spiced tomato & pepper sauce, served with khoubz', price: 24.00, category: 'Starters', tags: ['New'], prepMinutes: 12, calories: 380),
      MenuItem(id: 'r008_m05', name: 'Foul Medames', description: 'Slow-cooked fava beans with lemon, cumin & olive oil, served with bread', price: 18.00, category: 'Starters', tags: ['Vegan'], prepMinutes: 8, calories: 320),
      MenuItem(id: 'r008_m06', name: 'Samboosa (6 pcs)', description: 'Crispy pastry parcels filled with spiced minced meat & onion', price: 20.00, category: 'Starters', tags: ['Top Rated'], prepMinutes: 8, calories: 370),
      MenuItem(id: 'r008_m07', name: 'Chai Karak', description: 'Ennabi\'s signature karak: strong, spiced & creamy', price: 8.00, category: 'Drinks', tags: ['Best Seller'], prepMinutes: 4, calories: 110),
      MenuItem(id: 'r008_m08', name: 'Luqaimat (10 pcs)', description: 'Golden fried dough balls with date syrup & toasted sesame', price: 15.00, category: 'Desserts', tags: ['Top Rated'], prepMinutes: 8, calories: 420),
    ],
  };

  final String restaurantId;

  MenuRepository({this.restaurantId = 'r001'});

  List<MenuItem> getAll() =>
      List.from(_byRestaurant[restaurantId] ?? _byRestaurant['r001']!);

  List<MenuItem> getForRestaurant(String id) =>
      List.from(_byRestaurant[id] ?? []);

  List<String> getCategories() {
    final items = _byRestaurant[restaurantId] ?? [];
    final seen = <String>{};
    return items.map((i) => i.category).where(seen.add).toList();
  }

  List<MenuItem> getByCategory(String category) =>
      (_byRestaurant[restaurantId] ?? [])
          .where((i) => i.category == category)
          .toList();

  List<MenuItem> getFeatured() =>
      (_byRestaurant[restaurantId] ?? [])
          .where((i) => i.isFeatured)
          .toList();
}
