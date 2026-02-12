import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/category.dart';
import '../models/item.dart';

class ApiService {
  // สำหรับ Android Emulator ใช้ 10.0.2.2 แทน 127.0.0.1
  static const String baseUrl = 'http://10.0.2.2:8080/api';

  Future<List<MainCategory>> getMainCategories() async {
    try {
      print('🔍 Fetching main categories from: $baseUrl/categories/main');
      final response = await http.get(Uri.parse('$baseUrl/categories/main'));
      
      print('✅ Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        List<dynamic> body = json.decode(response.body);
        return body.map((item) => MainCategory.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      print('❌ Error: $e');
      return [];
    }
  }

  Future<List<Category>> getSubCategories(int mainCategoryId) async {
    try {
      final url = '$baseUrl/categories/sub?main_category_id=$mainCategoryId';
      print('🔍 Fetching sub categories from: $url');
      final response = await http.get(Uri.parse(url));
      
      print('✅ Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        List<dynamic> body = json.decode(response.body);
        return body.map((item) => Category.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      print('❌ Error: $e');
      return [];
    }
  }

  Future<List<Item>> getItems({int? categoryId}) async {
    try {
      String url = '$baseUrl/items';
      if (categoryId != null) {
        url += '?category_id=$categoryId';
      }
      
      print('🔍 Fetching items from: $url');
      final response = await http.get(Uri.parse(url));
      
      print('✅ Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        List<dynamic> body = json.decode(response.body);
        return body.map((item) => Item.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      print('❌ Error: $e');
      return [];
    }
  }
}
