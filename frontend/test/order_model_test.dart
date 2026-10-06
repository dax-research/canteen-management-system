import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/order.dart';

void main() {
  group('Order and OrderItem Model Tests', () {
    test(
      'OrderItem.fromJson correctly parses valid JSON with food_item_id',
      () {
        final json = {
          'id': 'item-1',
          'order_id': 'order-1',
          'food_item_id': 'food-1',
          'item_name': 'Test Pizza',
          'unit_price': 12.5,
          'quantity': 2,
          'subtotal': 25.0,
          'created_at': '2026-10-01T12:00:00Z',
        };

        final item = OrderItem.fromJson(json);

        expect(item.id, 'item-1');
        expect(item.orderId, 'order-1');
        expect(item.foodItemId, 'food-1');
        expect(item.itemName, 'Test Pizza');
        expect(item.unitPrice, 12.5);
        expect(item.quantity, 2);
        expect(item.subtotal, 25.0);
        expect(item.createdAt, DateTime.parse('2026-10-01T12:00:00Z'));
      },
    );

    test(
      'OrderItem.fromJson correctly parses valid JSON with null food_item_id',
      () {
        final json = {
          'id': 'item-2',
          'order_id': 'order-1',
          'food_item_id': null,
          'item_name': 'Deleted Pizza',
          'unit_price': 15.0,
          'quantity': 1,
          'subtotal': 15.0,
          'created_at': '2026-10-01T12:00:00Z',
        };

        final item = OrderItem.fromJson(json);

        expect(item.id, 'item-2');
        expect(item.orderId, 'order-1');
        expect(item.foodItemId, isNull);
        expect(item.itemName, 'Deleted Pizza');
        expect(item.unitPrice, 15.0);
        expect(item.quantity, 1);
        expect(item.subtotal, 15.0);
      },
    );

    test('Order.fromJson correctly parses a created order response', () {
      final json = {
        'id': 'order-1',
        'user_id': 'user-1',
        'status': 'PLACED',
        'order_type': 'PICKUP',
        'pickup_time': '1:30 PM',
        'eta_minutes': 25,
        'total_amount': 40.0,
        'created_at': '2026-10-01T12:00:00Z',
        'updated_at': '2026-10-01T12:00:00Z',
        'items': [
          {
            'id': 'item-1',
            'order_id': 'order-1',
            'food_item_id': 'food-1',
            'item_name': 'Test Pizza',
            'unit_price': 12.5,
            'quantity': 2,
            'subtotal': 25.0,
            'created_at': '2026-10-01T12:00:00Z',
          },
          {
            'id': 'item-2',
            'order_id': 'order-1',
            'food_item_id': null,
            'item_name': 'Deleted Pizza',
            'unit_price': 15.0,
            'quantity': 1,
            'subtotal': 15.0,
            'created_at': '2026-10-01T12:00:00Z',
          },
        ],
      };

      final order = Order.fromJson(json);

      expect(order.id, 'order-1');
      expect(order.userId, 'user-1');
      expect(order.status, 'PLACED');
      expect(order.orderType, 'PICKUP');
      expect(order.pickupTime, '1:30 PM');
      expect(order.etaMinutes, 25);
      expect(order.totalAmount, 40.0);
      expect(order.items.length, 2);
      expect(order.items[0].itemName, 'Test Pizza');
      expect(order.items[1].itemName, 'Deleted Pizza');
      expect(order.items[1].foodItemId, isNull);
    });

    test('Order.fromJson list parsing simulates getOrders() behavior', () {
      final jsonList = [
        {
          'id': 'order-1',
          'user_id': 'user-1',
          'status': 'PLACED',
          'total_amount': 10.0,
          'created_at': '2026-10-01T12:00:00Z',
          'updated_at': '2026-10-01T12:00:00Z',
          'items': [],
        },
        {
          'id': 'order-2',
          'user_id': 'user-1',
          'status': 'COMPLETED',
          'total_amount': 20.0,
          'created_at': '2026-10-02T12:00:00Z',
          'updated_at': '2026-10-02T12:00:00Z',
          'items': [],
        },
      ];

      final orders = jsonList.map((json) => Order.fromJson(json)).toList();

      expect(orders.length, 2);
      expect(orders[0].id, 'order-1');
      expect(orders[1].id, 'order-2');
      expect(orders[1].status, 'COMPLETED');
    });
  });
}
