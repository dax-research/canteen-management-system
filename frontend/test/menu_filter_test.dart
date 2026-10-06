import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/food_item.dart';
import 'package:frontend/services/menu_service.dart';

void main() {
  final items = [
    FoodItem(
      id: 'food-1',
      categoryId: 'cat-1',
      categoryName: 'Hot Drinks',
      name: 'Masala Tea',
      price: 20,
      isAvailable: true,
    ),
    FoodItem(
      id: 'food-2',
      categoryId: 'cat-2',
      categoryName: 'Snacks',
      name: 'Tea Cake',
      price: 35,
      isAvailable: true,
    ),
  ];

  test('search matches food names and category names case-insensitively', () {
    expect(
      MenuService.filterFoodItems(items, search: 'tea').map((item) => item.id),
      ['food-1', 'food-2'],
    );
    expect(
      MenuService.filterFoodItems(
        items,
        search: 'HOT DRINKS',
      ).map((item) => item.id),
      ['food-1'],
    );
  });

  test('category filtering remains combined with search', () {
    expect(
      MenuService.filterFoodItems(
        items,
        search: 'tea',
        categoryId: 'cat-2',
      ).map((item) => item.id),
      ['food-2'],
    );
    expect(MenuService.filterFoodItems(items, categoryId: 'missing'), isEmpty);
  });
}
