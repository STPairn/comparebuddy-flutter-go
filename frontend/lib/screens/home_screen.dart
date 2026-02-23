import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/category.dart';
import '../models/item.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../widgets/item_card.dart';
import 'car_browse_screen.dart';
import 'car_compare_screen.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();

  List<MainCategory> _mainCategories = [];
  Map<int, List<Category>> _subCatsByMain = {}; // mainCatId → sub-categories
  bool _isLoading = true;

  Category? _selectedSubCat;
  List<Item> _items = [];
  bool _isLoadingItems = false;

  User? _currentUser;
  List<int> _pendingComparisonIds = [];
  Map<int, String> _pendingComparisonLabels = {};

  @override
  void initState() {
    super.initState();
    _loadAllCategories();
    _loadUser();
    _loadPendingComparison();
  }

  // ── Data loading ─────────────────────────────────────────────────────────

  Future<void> _loadAllCategories() async {
    setState(() => _isLoading = true);
    try {
      final mains = await _apiService.getMainCategories();
      // load all sub-categories in parallel
      final futures = mains.map((m) => _apiService.getSubCategories(m.id));
      final results = await Future.wait(futures);
      final map = <int, List<Category>>{};
      for (int i = 0; i < mains.length; i++) {
        map[mains[i].id] = results[i];
      }
      setState(() {
        _mainCategories = mains;
        _subCatsByMain = map;
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _onSubCategoryTap(Category cat) async {
    if (cat.nameEn == 'car') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const CarBrowseScreen()),
      ).then((_) => _loadPendingComparison());
      return;
    }
    setState(() {
      _selectedSubCat = cat;
      _items = [];
      _isLoadingItems = true;
    });
    try {
      final items = await _apiService.getItems(categoryId: cat.id);
      setState(() => _items = items);
    } finally {
      setState(() => _isLoadingItems = false);
    }
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user');
    if (userData != null) {
      setState(() => _currentUser = User.fromJson(json.decode(userData)));
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user');
    setState(() => _currentUser = null);
  }

  Future<bool> _requireLogin() async {
    if (_currentUser != null) return true;
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
    if (result == true) {
      await _loadUser();
      return true;
    }
    return false;
  }

  Future<void> _loadPendingComparison() async {
    final prefs = await SharedPreferences.getInstance();
    const prefKeyIds = 'pending_comparison_ids';
    const prefKeyLabels = 'pending_comparison_labels';
    final idsJson = prefs.getString(prefKeyIds);
    final labelsJson = prefs.getString(prefKeyLabels);
    final ids = idsJson != null
        ? (json.decode(idsJson) as List).map((e) => e as int).toList()
        : <int>[];
    final labels = <int, String>{};
    if (labelsJson != null) {
      final raw = json.decode(labelsJson) as Map<String, dynamic>;
      for (final entry in raw.entries) {
        labels[int.parse(entry.key)] = entry.value as String;
      }
    }
    setState(() {
      _pendingComparisonIds = ids;
      _pendingComparisonLabels = labels;
    });
  }

  Future<void> _clearPendingComparison() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('pending_comparison_ids');
    await prefs.remove('pending_comparison_labels');
    setState(() {
      _pendingComparisonIds = [];
      _pendingComparisonLabels = {};
    });
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  IconData _iconFor(String? nameEn) {
    switch ((nameEn ?? '').toLowerCase()) {
      case 'car':               return Icons.directions_car;
      case 'phone':
      case 'mobile':
      case 'smartphone':        return Icons.phone_android;
      case 'laptop':
      case 'notebook':          return Icons.laptop;
      case 'tablet':            return Icons.tablet_android;
      case 'tv':
      case 'television':        return Icons.tv;
      case 'camera':            return Icons.camera_alt;
      case 'headphone':
      case 'earphone':          return Icons.headphones;
      case 'refrigerator':
      case 'fridge':            return Icons.kitchen;
      case 'washing':
      case 'washer':            return Icons.local_laundry_service;
      case 'ac':
      case 'air':               return Icons.air;
      default:                  return Icons.category;
    }
  }

  // ── Side menu (bottom sheet) ──────────────────────────────────────────────

  void _showMenuSheet() {
    final topPadding = MediaQuery.of(context).padding.top + kToolbarHeight + 8;
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.15),
      builder: (_) => Align(
        alignment: Alignment.topRight,
        child: Padding(
          padding: EdgeInsets.only(top: topPadding, right: 12),
          child: _MenuPanel(
            currentUser: _currentUser,
            onLogin: () async {
              Navigator.pop(context);
              final result = await Navigator.of(context).push<bool>(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
              if (result == true) await _loadUser();
            },
            onRegister: () async {
              Navigator.pop(context);
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const RegisterScreen()),
              );
            },
            onLogout: () async {
              Navigator.pop(context);
              await _logout();
            },
          ),
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAF6F3),
        foregroundColor: const Color(0xFF3E2723),
        elevation: 0,
        scrolledUnderElevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: const Color(0xFF795548).withValues(alpha: 0.25),
            height: 1,
          ),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF795548).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF795548).withValues(alpha: 0.3),
                ),
              ),
              child: const Icon(Icons.compare_arrows, color: Color(0xFF795548), size: 20),
            ),
            const SizedBox(width: 10),
            const Text(
              'CompareBuddy',
              style: TextStyle(
                color: Color(0xFF3E2723),
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _showMenuSheet,
            icon: const Icon(Icons.menu_rounded, color: Color(0xFF795548), size: 26),
            tooltip: 'เมนู',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF795548)))
                : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Sub-category flat grid ───────────────────────────
                  _buildSubCategoryGrid(
                    _mainCategories.expand((m) => _subCatsByMain[m.id] ?? <Category>[]).toList(),
                  ),

                  // ── Items section (when sub-cat selected with items) ─
                  if (_selectedSubCat != null && _selectedSubCat!.nameEn != 'car') ...[
                    const SizedBox(height: 8),
                    _buildItemsSection(),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _pendingComparisonIds.length >= 2
          ? _buildPendingBottomBar()
          : null,
    );
  }

  Widget _buildSubCategoryGrid(List<Category> subs) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.88,
      ),
      itemCount: subs.length,
      itemBuilder: (_, i) => _buildSubCategoryCard(subs[i]),
    );
  }

  Widget _buildSubCategoryCard(Category cat) {
    final isSelected = _selectedSubCat?.id == cat.id;
    final icon = _iconFor(cat.nameEn);

    return GestureDetector(
      onTap: () => _onSubCategoryTap(cat),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF795548)
                : const Color(0xFF795548).withOpacity(0.25),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 22,
              color: isSelected ? const Color(0xFF795548) : const Color(0xFF795548).withOpacity(0.6),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                cat.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: const Color(0xFF3E2723),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 1),
        const SizedBox(height: 20),
        Row(
          children: [
            const Icon(Icons.list_alt_outlined, size: 18, color: Color(0xFF795548)),
            const SizedBox(width: 8),
            Text(
              '${_selectedSubCat!.name} (${_items.length})',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF3E2723)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_isLoadingItems)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(color: Color(0xFF795548)),
            ),
          )
        else if (_items.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(Icons.inbox_outlined, size: 48, color: Colors.grey.shade300),
                  const SizedBox(height: 8),
                  Text('ไม่มีข้อมูล', style: TextStyle(color: Colors.grey.shade400, fontSize: 15)),
                ],
              ),
            ),
          )
        else
          ...(_items.map((item) => ItemCard(
                item: item,
                onTap: () async {
                  final loggedIn = await _requireLogin();
                  if (!loggedIn) return;
                },
              ))),
      ],
    );
  }

  Widget _buildPendingBottomBar() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFAF6F3),
        border: Border(
          top: BorderSide(color: const Color(0xFF795548).withValues(alpha: 0.35), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF795548).withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        16, 12, 16,
        12 + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header row ──────────────────────────────────────────────
          Row(
            children: [
              const Icon(Icons.compare_arrows, color: Color(0xFF795548), size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'เปรียบเทียบที่ค้างไว้ · ${_pendingComparisonIds.length} คัน',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF795548),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              GestureDetector(
                onTap: _clearPendingComparison,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(
                    'ล้าง',
                    style: TextStyle(fontSize: 11, color: Colors.red.shade400, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // ── Scrollable variant chips ─────────────────────────────────
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: _pendingComparisonIds.map((id) {
                final label = _pendingComparisonLabels[id] ?? 'รุ่น #$id';
                return Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF795548).withValues(alpha: 0.35),
                    ),
                  ),
                  child: Text(
                    label,
                    style: const TextStyle(fontSize: 11, color: Color(0xFF3E2723)),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 10),

          // ── Compare button ───────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => CarCompareScreen(variantIds: _pendingComparisonIds),
                  ),
                ).then((_) => _loadPendingComparison());
              },
              icon: const Icon(Icons.compare_arrows, size: 16),
              label: const Text(
                'เปรียบเทียบเลย',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF795548),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 11),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Menu dropdown panel (top-right)
// ─────────────────────────────────────────────────────────────────────────────
class _MenuPanel extends StatelessWidget {
  final User? currentUser;
  final VoidCallback onLogin;
  final VoidCallback onRegister;
  final VoidCallback onLogout;

  const _MenuPanel({
    required this.currentUser,
    required this.onLogin,
    required this.onRegister,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 270,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF795548).withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Profile section ─────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFAF6F3),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                border: Border(
                  bottom: BorderSide(color: const Color(0xFF795548).withValues(alpha: 0.15)),
                ),
              ),
              child: currentUser != null
                  ? Row(
                      children: [
                        const CircleAvatar(
                          radius: 20,
                          backgroundColor: Color(0xFF795548),
                          child: Icon(Icons.person, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                currentUser!.username,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF3E2723),
                                ),
                              ),
                              const Text(
                                'เข้าสู่ระบบแล้ว',
                                style: TextStyle(fontSize: 11, color: Color(0xFF795548)),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: onLogout,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Text(
                              'ออกจากระบบ',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.red.shade400,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        Row(
                          children: [
                            Icon(Icons.account_circle_outlined, size: 20, color: Colors.grey.shade400),
                            const SizedBox(width: 8),
                            Text(
                              'ยังไม่ได้เข้าสู่ระบบ',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: onLogin,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF795548),
                                  side: const BorderSide(color: Color(0xFF795548)),
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                child: const Text('เข้าสู่ระบบ', style: TextStyle(fontSize: 12)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: onRegister,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF795548),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                child: const Text('สมัครสมาชิก', style: TextStyle(fontSize: 12)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
            ),

            // ── Menu items ──────────────────────────────────────────────
            _MenuItem(
              icon: Icons.info_outline_rounded,
              label: 'เกี่ยวกับ CompareBuddy',
              onTap: () => Navigator.pop(context),
            ),
            _MenuItem(
              icon: Icons.star_outline_rounded,
              label: 'ให้คะแนนแอป',
              isLast: true,
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isLast;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: isLast
          ? const BorderRadius.vertical(bottom: Radius.circular(16))
          : BorderRadius.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          children: [
            Icon(icon, size: 18, color: const Color(0xFF795548)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 13, color: Color(0xFF3E2723)),
              ),
            ),
            Icon(Icons.chevron_right, size: 16, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}
