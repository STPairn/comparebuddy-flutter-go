import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/category.dart';
import '../models/item.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../widgets/category_button.dart';
import '../widgets/item_card.dart';
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
  List<Category> _subCategories = [];
  List<Item> _items = [];

  int? _selectedMainCategoryId;
  int? _selectedSubCategoryId;
  bool _isLoading = false;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadMainCategories();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user');
    if (userData != null) {
      setState(() {
        _currentUser = User.fromJson(json.decode(userData));
      });
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

  Future<void> _loadMainCategories() async {
    setState(() => _isLoading = true);
    try {
      final categories = await _apiService.getMainCategories();
      setState(() {
        _mainCategories = categories;
        if (categories.isNotEmpty) {
          _selectedMainCategoryId = categories[0].id;
          _loadSubCategories(categories[0].id);
        }
      });
    } catch (e) {
      print('Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadSubCategories(int mainCategoryId) async {
    setState(() => _isLoading = true);
    try {
      final categories = await _apiService.getSubCategories(mainCategoryId);
      setState(() {
        _subCategories = categories;
        if (categories.isNotEmpty) {
          _selectedSubCategoryId = categories[0].id;
          _loadItems(categories[0].id);
        }
      });
    } catch (e) {
      print('Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadItems(int categoryId) async {
    setState(() => _isLoading = true);
    try {
      final items = await _apiService.getItems(categoryId: categoryId);
      setState(() => _items = items);
    } catch (e) {
      print('Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showProfileMenu() {
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;

    showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromLTWH(
          overlay.size.width - 48,
          kToolbarHeight + MediaQuery.of(context).padding.top,
          0,
          0,
        ),
        Offset.zero & overlay.size,
      ),
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 8,
      items: _currentUser != null
          ? [
              PopupMenuItem(
                enabled: false,
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 16,
                      backgroundColor: Color(0xFF795548),
                      child: Icon(Icons.person, color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _currentUser!.username,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3E2723),
                      ),
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 20, color: Colors.redAccent),
                    SizedBox(width: 8),
                    Text('ออกจากระบบ', style: TextStyle(color: Colors.redAccent)),
                  ],
                ),
              ),
            ]
          : [
              const PopupMenuItem(
                value: 'login',
                child: Row(
                  children: [
                    Icon(Icons.login, size: 20, color: Color(0xFF795548)),
                    SizedBox(width: 8),
                    Text('เข้าสู่ระบบ'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'register',
                child: Row(
                  children: [
                    Icon(Icons.person_add_outlined, size: 20, color: Color(0xFF795548)),
                    SizedBox(width: 8),
                    Text('สมัครสมาชิก'),
                  ],
                ),
              ),
            ],
    ).then((value) async {
      if (value == 'login') {
        final result = await Navigator.of(context).push<bool>(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
        if (result == true) await _loadUser();
      } else if (value == 'register') {
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const RegisterScreen()),
        );
      } else if (value == 'logout') {
        await _logout();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF3E2723),
        elevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF795548), Color(0xFFA1887F)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.compare_arrows, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            const Text(
              'CompareBuddy',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _currentUser != null
                ? GestureDetector(
                    onTap: _showProfileMenu,
                    child: const CircleAvatar(
                      radius: 18,
                      backgroundColor: Color(0xFF795548),
                      child: Icon(Icons.person, color: Colors.white, size: 20),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.account_circle_outlined, color: Colors.white70, size: 28),
                    onPressed: _showProfileMenu,
                  ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Hero section
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF3E2723), Color(0xFF4E342E)],
              ),
            ),
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: const Column(
              children: [
                Text(
                  'เปรียบเทียบทุกอย่างได้ง่ายๆ',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF795548)),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _buildSection(
                          'หมวดหมู่หลัก',
                          Icons.category_outlined,
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: _mainCategories.map((cat) {
                              return CategoryButton(
                                text: cat.name,
                                isSelected: _selectedMainCategoryId == cat.id,
                                onPressed: () {
                                  setState(() {
                                    _selectedMainCategoryId = cat.id;
                                    _selectedSubCategoryId = null;
                                    _items = [];
                                  });
                                  _loadSubCategories(cat.id);
                                },
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (_subCategories.isNotEmpty)
                          _buildSection(
                            'หมวดย่อย',
                            Icons.label_outlined,
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: _subCategories.map((cat) {
                                return CategoryButton(
                                  text: cat.name,
                                  isSelected: _selectedSubCategoryId == cat.id,
                                  onPressed: () {
                                    setState(() => _selectedSubCategoryId = cat.id);
                                    _loadItems(cat.id);
                                  },
                                );
                              }).toList(),
                            ),
                          ),
                        const SizedBox(height: 16),
                        _buildSection(
                          'รายการ (${_items.length})',
                          Icons.list_alt_outlined,
                          _items.isEmpty
                              ? Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(40),
                                    child: Column(
                                      children: [
                                        Icon(Icons.inbox_outlined, size: 48, color: Colors.grey.shade300),
                                        const SizedBox(height: 12),
                                        Text(
                                          'ไม่มีข้อมูล',
                                          style: TextStyle(color: Colors.grey.shade400, fontSize: 16),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : Column(
                                  children: _items.map((item) => ItemCard(
                                    item: item,
                                    onTap: () async {
                                      final loggedIn = await _requireLogin();
                                      if (!loggedIn) return;
                                      // TODO: navigate to item detail screen
                                    },
                                  )).toList(),
                                ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: const Color(0xFF795548)),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF3E2723),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
