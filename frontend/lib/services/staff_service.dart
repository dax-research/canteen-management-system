import '../core/constants/api_constants.dart';
import '../models/food_item.dart';
import '../models/order.dart';
import 'api_service.dart';

class StaffService {
  static Future<List<Order>> getOrders({String? status}) async {
    final response = await ApiService.get(
      ApiConstants.staffOrders,
      queryParams:
          status == null || status.isEmpty ? null : {'status': status},
    );
    if (response is! List) return [];
    return response
        .map((item) => Order.fromJson((item as Map).cast<String, dynamic>()))
        .toList();
  }

  static Future<Order> getOrder(String orderId) async {
    final response =
        await ApiService.get('${ApiConstants.staffOrders}/$orderId');
    return Order.fromJson((response as Map).cast<String, dynamic>());
  }

  static Future<Order> updateOrderStatus(
    String orderId,
    String status,
  ) async {
    final response = await ApiService.patch(
      '${ApiConstants.staffOrders}/$orderId/status',
      {'status': status},
    );
    return Order.fromJson((response as Map).cast<String, dynamic>());
  }

  static Future<Order> confirmCashPayment(String orderId) async {
    final response = await ApiService.patch(
      '${ApiConstants.staffOrders}/$orderId/payment',
      {'status': 'PAID'},
    );
    return Order.fromJson((response as Map).cast<String, dynamic>());
  }

  static Future<List<FoodItem>> getInventory() async {
    final response = await ApiService.get(ApiConstants.inventory);
    if (response is! List) return [];
    return response
        .map((item) => FoodItem.fromJson((item as Map).cast<String, dynamic>()))
        .toList();
  }

  static Future<FoodItem> updateStock(String itemId, int stock) async {
    final response = await ApiService.patch(
      '${ApiConstants.inventory}/$itemId',
      {'stock': stock},
    );
    return FoodItem.fromJson((response as Map).cast<String, dynamic>());
  }
}
