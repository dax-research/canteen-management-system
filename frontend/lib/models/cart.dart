class CartItem {
  final String id;
  final String foodItemId;
  final String name;
  final String? description;
  final String? imageUrl;
  final double unitPrice;
  final int quantity;
  final double subtotal;
  final bool isAvailable;

  CartItem({
    required this.id,
    required this.foodItemId,
    required this.name,
    this.description,
    this.imageUrl,
    required this.unitPrice,
    required this.quantity,
    required this.subtotal,
    required this.isAvailable,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'] as String,
      foodItemId: json['food_item_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      imageUrl: json['image_url'] as String?,
      unitPrice: (json['unit_price'] as num).toDouble(),
      quantity: json['quantity'] as int,
      subtotal: (json['subtotal'] as num).toDouble(),
      isAvailable: json['is_available'] as bool,
    );
  }
}

class Cart {
  final String id;
  final List<CartItem> items;
  final double total;

  Cart({required this.id, required this.items, required this.total});

  factory Cart.fromJson(Map<String, dynamic> json) {
    var itemsList = json['items'] as List;
    List<CartItem> parsedItems = itemsList
        .map((i) => CartItem.fromJson(i as Map<String, dynamic>))
        .toList();

    return Cart(
      id: json['id'] as String,
      items: parsedItems,
      total: (json['total'] as num).toDouble(),
    );
  }
}
