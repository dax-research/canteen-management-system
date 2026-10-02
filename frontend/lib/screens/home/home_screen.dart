import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../models/category.dart';
import '../../models/food_item.dart';
import '../../services/menu_service.dart';
import '../../widgets/app_network_image.dart';
import '../../widgets/app_shimmer.dart';
import '../../widgets/food_item_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = true;
  String? _error;
  List<Category> _cats = [];
  List<FoodItem> _items = [];
  String? _selectedCat;
  final _search = TextEditingController();
  Timer? _debounce;
  int _reqCount = 0;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    final req = ++_reqCount;
    setState(() { _isLoading = true; _error = null; });
    try {
      final c = await MenuService.getCategories();
      final i = await MenuService.getFoodItems();
      if (!mounted || req != _reqCount) return;
      setState(() { _cats = c; _items = i; _isLoading = false; });
    } catch (_) {
      if (!mounted || req != _reqCount) return;
      setState(() { _error = 'Could not load menu'; _isLoading = false; });
    }
  }

  Future<void> _loadItems() async {
    final req = ++_reqCount;
    setState(() { _isLoading = true; _error = null; });
    try {
      final i = await MenuService.getFoodItems(
          search: _search.text, categoryId: _selectedCat);
      if (!mounted || req != _reqCount) return;
      setState(() { _items = i; _isLoading = false; });
    } catch (_) {
      if (!mounted || req != _reqCount) return;
      setState(() { _error = 'Failed to load items'; _isLoading = false; });
    }
  }

  void _onSearch(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _loadItems);
  }

  void _onCat(String? id) {
    if (_selectedCat == id) return;
    setState(() => _selectedCat = id);
    _loadItems();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _loadAll,
        color: AppColors.primary,
        child: CustomScrollView(
          slivers: [
            _buildHeader(),
            SliverToBoxAdapter(child: _buildSearch()),
            SliverToBoxAdapter(child: _buildPromo()),
            SliverToBoxAdapter(child: _buildCategoryBar()),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    Text(
                      _selectedCat == null && _search.text.isEmpty
                          ? 'All Items'
                          : 'Results',
                      style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary),
                    ),
                    const Spacer(),
                    Text('${_items.length} items',
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ),
            _buildList(),
          ],
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────
  Widget _buildHeader() {
    return SliverAppBar(
      expandedHeight: 100,
      collapsedHeight: 64,
      floating: true,
      snap: true,
      backgroundColor: AppColors.background,
      elevation: 0,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        background: Padding(
          padding: const EdgeInsets.fromLTRB(20, 48, 20, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded,
                            color: AppColors.primary, size: 16),
                        const SizedBox(width: 4),
                        Text('Copper Spoon Canteen',
                            style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500)),
                        const Icon(Icons.keyboard_arrow_down_rounded,
                            color: AppColors.textSecondary, size: 16),
                      ],
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'What\'s for today? 🍽️',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary),
                    ),
                  ],
                ),
              ),
              // Avatar
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      width: 1.5),
                ),
                child: const Icon(Icons.person_rounded,
                    color: AppColors.primary, size: 22),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Search ─────────────────────────────────────────────────
  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _search,
              onChanged: _onSearch,
              decoration: InputDecoration(
                hintText: 'Search dishes...',
                prefixIcon: const Icon(Icons.search_rounded,
                    color: AppColors.textHint, size: 20),
                suffixIcon: _search.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18),
                        onPressed: () {
                          _search.clear();
                          _loadItems();
                          setState(() {});
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                filled: true,
                fillColor: AppColors.surface,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.divider, width: 0.8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.tune_rounded,
                color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }

  // ── Promo banner ───────────────────────────────────────────
  Widget _buildPromo() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      height: 130,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: AppColors.espresso,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background coffee image
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            width: 160,
            child: AppNetworkImage(
              imageUrl:
                  'https://images.unsplash.com/photo-1509042239860-f550ce710b93?w=400&q=80',
              width: 160,
              height: 130,
              fit: BoxFit.cover,
              borderRadius: BorderRadius.zero,
              fallbackIcon: Icons.local_cafe_rounded,
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF3E2723), Color(0x663E2723)],
                stops: [0.45, 1.0],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('Promo',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700)),
                ),
                const SizedBox(height: 8),
                const Text('Buy one get\none FREE',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        height: 1.2)),
                const SizedBox(height: 6),
                Text('Valid on selected items',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Category bar ───────────────────────────────────────────
  Widget _buildCategoryBar() {
    if (_isLoading && _cats.isEmpty) return const CategoryBarSkeleton();
    if (_cats.isEmpty) return const SizedBox(height: 16);

    return SizedBox(
      height: 56,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
        itemCount: _cats.length + 1,
        itemBuilder: (context, i) {
          final isAll = i == 0;
          final cat = isAll ? null : _cats[i - 1];
          final selected = isAll
              ? _selectedCat == null
              : _selectedCat == cat!.id;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _CatChip(
              label: isAll ? 'All' : cat!.name,
              selected: selected,
              onTap: () => _onCat(isAll ? null : cat!.id),
            ),
          );
        },
      ),
    );
  }

  // ── Food list ──────────────────────────────────────────────
  Widget _buildList() {
    if (_isLoading && _items.isEmpty) {
      return SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => const FoodCardSkeleton(),
          childCount: 5,
        ),
      );
    }
    if (_error != null && _items.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off_rounded,
                  size: 60, color: AppColors.textHint),
              const SizedBox(height: 16),
              Text('Could not load menu',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadAll,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    if (_items.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.no_food_rounded,
                  size: 60, color: AppColors.textHint),
              const SizedBox(height: 12),
              Text('Nothing found',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 4),
              Text('Try different filters',
                  style: TextStyle(
                      fontSize: 13, color: AppColors.textSecondary)),
            ],
          ),
        ),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.only(bottom: 32),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, i) {
            if (i == 0 && _isLoading) {
              return const LinearProgressIndicator(
                minHeight: 2,
                color: AppColors.primary,
                backgroundColor: AppColors.primaryLight,
              );
            }
            final idx = _isLoading ? i - 1 : i;
            if (idx < 0 || idx >= _items.length) return null;
            return FoodItemCard(foodItem: _items[idx]);
          },
          childCount: _items.length + (_isLoading ? 1 : 0),
        ),
      ),
    );
  }
}

// ── Category chip ──────────────────────────────────────────────────────────
class _CatChip extends StatelessWidget {
  const _CatChip(
      {required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface,
          borderRadius: AppRadius.full,
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.divider,
            width: 1.2,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 3))
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.textSecondary,
            fontWeight:
                selected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
