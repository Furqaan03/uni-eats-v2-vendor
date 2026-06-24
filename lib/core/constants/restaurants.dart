/// The 8 seeded campus restaurants, shared across signup, legacy-account
/// migration, and the offline/no-Firebase test-mode default restaurant.
/// Single source of truth — this list used to be hand-duplicated in three
/// separate files (firestore_order_service.dart, auth_provider.dart,
/// signup_screen.dart), so adding a restaurant meant editing all three and
/// risking them drifting out of sync.
const kCampusRestaurants = [
  (id: 'r001', name: 'Tim Hortons', location: 'Building B3'),
  (id: 'r002', name: 'Oakberry', location: 'Building B3'),
  (id: 'r003', name: 'Edge Cafe', location: 'Building B9'),
  (id: 'r004', name: 'Caribou Coffee', location: 'Building E4'),
  (id: 'r005', name: 'JamKai', location: 'Building B20'),
  (id: 'r006', name: 'Bold Café', location: 'Atrium 5'),
  (id: 'r007', name: "L'Hardy", location: 'Building B12'),
  (id: 'r008', name: 'Ennabi 92', location: 'Building B4'),
];

/// Lookup map keyed by restaurant id, for code that only needs name/location.
final kCampusRestaurantInfo = <String, (String name, String location)>{
  for (final r in kCampusRestaurants) r.id: (r.name, r.location),
};

/// Starting catalog-profile values for each restaurant — category,
/// description, delivery time/min-order estimates, and campus map position.
/// These are the values vendors see pre-filled in Restaurant Settings the
/// first time they open it, and what the customer app falls back to for any
/// field a vendor hasn't edited yet. campusX/Y aren't vendor-editable yet
/// (needs a map-pin-placement UI — separate future work), so they always
/// come from here regardless of what's in Firestore.
class RestaurantProfileDefaults {
  final String category;
  final String description;
  final int deliveryTimeMin;
  final double minOrder;
  final bool offersDelivery;
  final bool offersPickup;
  final double campusX;
  final double campusY;
  const RestaurantProfileDefaults({
    required this.category,
    required this.description,
    required this.deliveryTimeMin,
    required this.minOrder,
    required this.offersDelivery,
    required this.offersPickup,
    required this.campusX,
    required this.campusY,
  });
}

final kCampusRestaurantDefaults = <String, RestaurantProfileDefaults>{
  'r001': const RestaurantProfileDefaults(
    category: 'Coffee & Bakery',
    description: 'Canadian coffeehouse & baked goods',
    deliveryTimeMin: 8,
    minOrder: 10.0,
    offersDelivery: true,
    offersPickup: true,
    campusX: 0.18,
    campusY: 0.22,
  ),
  'r002': const RestaurantProfileDefaults(
    category: 'Açaí & Healthy',
    description: 'Fresh açaí bowls and healthy snacks',
    deliveryTimeMin: 5,
    minOrder: 18.0,
    offersDelivery: true,
    offersPickup: true,
    campusX: 0.22,
    campusY: 0.18,
  ),
  'r003': const RestaurantProfileDefaults(
    category: 'Café',
    description: 'Specialty coffee & light bites',
    deliveryTimeMin: 15,
    minOrder: 12.0,
    offersDelivery: true,
    offersPickup: true,
    campusX: 0.55,
    campusY: 0.20,
  ),
  'r004': const RestaurantProfileDefaults(
    category: 'Coffee',
    description: 'Coffee & espresso drinks',
    deliveryTimeMin: 2,
    minOrder: 8.0,
    offersDelivery: true,
    offersPickup: true,
    campusX: 0.42,
    campusY: 0.55,
  ),
  'r005': const RestaurantProfileDefaults(
    category: 'Asian Fusion',
    description: 'Asian bowls, noodles & bubble tea',
    deliveryTimeMin: 12,
    minOrder: 20.0,
    offersDelivery: true,
    offersPickup: true,
    campusX: 0.40,
    campusY: 0.75,
  ),
  'r006': const RestaurantProfileDefaults(
    category: 'Café',
    description: 'Campus café with sandwiches & salads',
    deliveryTimeMin: 8,
    minOrder: 15.0,
    offersDelivery: true,
    offersPickup: true,
    campusX: 0.50,
    campusY: 0.60,
  ),
  'r007': const RestaurantProfileDefaults(
    category: 'Qatari Cuisine',
    description: 'Traditional Qatari dishes',
    deliveryTimeMin: 18,
    minOrder: 25.0,
    offersDelivery: false,
    offersPickup: true,
    campusX: 0.65,
    campusY: 0.35,
  ),
  'r008': const RestaurantProfileDefaults(
    category: 'Qatari Cuisine',
    description: 'Authentic local flavors',
    deliveryTimeMin: 14,
    minOrder: 22.0,
    offersDelivery: false,
    offersPickup: true,
    campusX: 0.48,
    campusY: 0.68,
  ),
};
