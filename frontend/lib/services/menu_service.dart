import '../core/constants/api_constants.dart';
import '../models/category.dart';
import '../models/food_item.dart';
import 'api_service.dart';

class MenuService {
  static Future<List<Category>> getCategories() async {
    try {
      final dynamic response = await ApiService.get(ApiConstants.categories);
      if (response is List) {
        return response.map((json) => Category.fromJson(json as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  static Future<List<FoodItem>> getFoodItems({
    String? search,
    String? categoryId,
  }) async {
    try {
      final Map<String, String> queryParams = {};
      if (search != null && search.trim().isNotEmpty) {
        queryParams['search'] = search.trim();
      }
      if (categoryId != null && categoryId.isNotEmpty) {
        queryParams['category_id'] = categoryId;
      }

      final dynamic response = await ApiService.get(
        ApiConstants.foodItems,
        queryParams: queryParams.isEmpty ? null : queryParams,
      );

      if (response is List) {
        return response.map((json) => FoodItem.fromJson(json as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }
}
