import 'package:flutter/material.dart';
import '../models/category.dart';
import '../models/item.dart';
import '../services/api_service.dart';
import '../widgets/category_button.dart';
import '../widgets/item_card.dart';

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

  @override
  void initState() {
    super.initState();
    _loadMainCategories();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Column(
          children: [
            Text(
              'CompareBuddy',
              style: TextStyle(
                color: Colors.black,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'เปรียบเทียบทุกอย่างได้ง่ายๆ',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.black))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildSection(
                    'เลือกหมวดหมู่หลัก',
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
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
                  const SizedBox(height: 24),
                  if (_subCategories.isNotEmpty)
                    _buildSection(
                      'เลือกหมวดย่อย',
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
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
                  const SizedBox(height: 24),
                  _buildSection(
                    'รายการ (${_items.length})',
                    _items.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32),
                              child: Text('ไม่มีข้อมูล', style: TextStyle(color: Colors.grey)),
                            ),
                          )
                        : Column(
                            children: _items.map((item) => ItemCard(item: item)).toList(),
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSection(String title, Widget child) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
