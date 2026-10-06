import '../core/constants/api_constants.dart';
import '../models/order.dart';
import 'api_service.dart';

class OrderService {
  static Future<Order> placeOrder({
    String orderType = 'PICKUP',
    String? pickupTime,
    int? etaMinutes,
  }) async {
    try {
      final body = <String, dynamic>{
        'order_type': orderType,
        if (pickupTime != null) 'pickup_time': pickupTime,
        if (etaMinutes != null) 'eta_minutes': etaMinutes,
      };
      final response = await ApiService.post(ApiConstants.orders, body);
      return Order.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  static Future<List<Order>> getOrders() async {
    try {
      final response = await ApiService.get(ApiConstants.orders);
      List<dynamic> jsonList = response as List<dynamic>;
      return jsonList
          .map((json) => Order.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  static Future<Order> getOrder(String orderId) async {
    try {
      final response = await ApiService.get('${ApiConstants.orders}/$orderId');
      return Order.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }
}
