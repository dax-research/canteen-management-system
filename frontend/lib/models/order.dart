class OrderItem {
  final String id;
  final String orderId;
  final String? foodItemId;
  final String itemName;
  final double unitPrice;
  final int quantity;
  final double subtotal;
  final DateTime createdAt;

  OrderItem({
    required this.id,
    required this.orderId,
    this.foodItemId,
    required this.itemName,
    required this.unitPrice,
    required this.quantity,
    required this.subtotal,
    required this.createdAt,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      foodItemId: json['food_item_id'] as String?,
      itemName: json['item_name'] as String,
      unitPrice: (json['unit_price'] as num).toDouble(),
      quantity: json['quantity'] as int,
      subtotal: (json['subtotal'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class Order {
  final String id;
  final String userId;
  final String status;
  final double totalAmount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<OrderItem> items;

  Order({
    required this.id,
    required this.userId,
    required this.status,
    required this.totalAmount,
    required this.createdAt,
    required this.updatedAt,
    required this.items,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    var itemsList = json['items'] as List;
    List<OrderItem> parsedItems = itemsList
        .map((i) => OrderItem.fromJson(i as Map<String, dynamic>))
        .toList();

    return Order(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      status: json['status'] as String,
      totalAmount: (json['total_amount'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      items: parsedItems,
    );
  }
}
