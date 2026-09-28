import '../core/constants/api_constants.dart';
import '../models/cart.dart';
import 'api_service.dart';

class CartService {
  static Future<Cart> getCart() async {
    try {
      final response = await ApiService.get(ApiConstants.cart);
      return Cart.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  static Future<Cart> addItem(String foodItemId, int quantity) async {
    try {
      final response = await ApiService.post(ApiConstants.cartItems, {
        'food_item_id': foodItemId,
        'quantity': quantity,
      });
      return Cart.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  static Future<Cart> updateItem(String cartItemId, int quantity) async {
    try {
      final response = await ApiService.patch(
        '${ApiConstants.cartItems}/$cartItemId',
        {'quantity': quantity},
      );
      return Cart.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  static Future<Cart> removeItem(String cartItemId) async {
    try {
      final response = await ApiService.delete(
        '${ApiConstants.cartItems}/$cartItemId',
      );
      return Cart.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  static Future<Cart> clearCart() async {
    try {
      final response = await ApiService.delete(ApiConstants.cart);
      return Cart.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }
}
