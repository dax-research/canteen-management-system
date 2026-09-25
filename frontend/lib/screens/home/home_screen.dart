import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/category.dart';
import '../../models/food_item.dart';
import '../../services/auth_service.dart';
import '../../services/menu_service.dart';
import '../../widgets/food_item_card.dart';
import '../auth/login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = true;
  String? _errorMessage;

  List<Category> _categories = [];
  List<FoodItem> _foodItems = [];

  String? _selectedCategoryId;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;

  int _requestCounter = 0;

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchInitialData() async {
    final int currentRequest = ++_requestCounter;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final categories = await MenuService.getCategories();
      final foodItems = await MenuService.getFoodItems();

      if (!mounted) return;
      if (currentRequest != _requestCounter) return;

      setState(() {
        _categories = categories;
        _foodItems = foodItems;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      if (currentRequest != _requestCounter) return;

      setState(() {
        _errorMessage = 'Failed to load menu. Please check your connection.';
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchFoodItems() async {
    final int currentRequest = ++_requestCounter;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final foodItems = await MenuService.getFoodItems(
        search: _searchController.text,
        categoryId: _selectedCategoryId,
      );

      if (!mounted) return;
      if (currentRequest != _requestCounter) return; // Ignore stale request

      setState(() {
        _foodItems = foodItems;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      if (currentRequest != _requestCounter) return; // Ignore stale request

      setState(() {
        _errorMessage = 'Failed to load food items.';
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged(String query) {
    if (_debounceTimer?.isActive ?? false) {
      _debounceTimer!.cancel();
    }
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      _fetchFoodItems();
    });
  }

  void _onCategorySelected(String? categoryId) {
    if (_selectedCategoryId == categoryId) return;
    
    setState(() {
      _selectedCategoryId = categoryId;
    });
    _fetchFoodItems();
  }

  Future<void> _logout(BuildContext context) async {
    await AuthService.logout();
    if (context.mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
            tooltip: 'Logout',
          )
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildCategorySelector(),
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          hintText: 'Search food...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
        ),
      ),
    );
  }

  Widget _buildCategorySelector() {
    if (_categories.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _categories.length + 1,
        itemBuilder: (context, index) {
          final isAll = index == 0;
          final category = isAll ? null : _categories[index - 1];
          final isSelected = isAll ? _selectedCategoryId == null : _selectedCategoryId == category!.id;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: Text(isAll ? 'All' : category!.name),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  _onCategorySelected(isAll ? null : category!.id);
                }
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading && _foodItems.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null && _foodItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 60),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchInitialData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_foodItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.restaurant_menu, color: Colors.grey, size: 60),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isNotEmpty || _selectedCategoryId != null
                  ? 'No items found matching your filters.'
                  : 'The menu is currently empty.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        ListView.builder(
          padding: const EdgeInsets.only(bottom: 16),
          itemCount: _foodItems.length,
          itemBuilder: (context, index) {
            return FoodItemCard(foodItem: _foodItems[index]);
          },
        ),
        if (_isLoading)
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(),
          ),
      ],
    );
  }
}
