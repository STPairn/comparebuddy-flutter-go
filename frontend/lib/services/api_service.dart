import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import '../models/category.dart';
import '../models/item.dart';
import '../models/user.dart';

class ApiService {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8080/api';
    } else if (Platform.isAndroid) {
      return 'http://10.0.2.2:8080/api';
    } else {
      // iOS, macOS, desktop
      return 'http://localhost:8080/api';
    }
  }

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

  // Auth methods
  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': username,
          'email': email,
          'password': password,
          'display_name': displayName ?? username,
        }),
      );

      final body = json.decode(response.body);
      if (response.statusCode == 201) {
        return {'success': true, 'user': User.fromJson(body['user'])};
      }
      return {'success': false, 'error': body['error'] ?? 'Registration failed'};
    } catch (e) {
      return {'success': false, 'error': 'Connection error: $e'};
    }
  }

  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': username,
          'password': password,
        }),
      );

      final body = json.decode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'user': User.fromJson(body['user'])};
      }
      return {'success': false, 'error': body['error'] ?? 'Login failed'};
    } catch (e) {
      return {'success': false, 'error': 'Connection error: $e'};
    }
  }

  Future<Map<String, dynamic>> googleLogin({required String idToken}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/google'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'id_token': idToken}),
      );

      final body = json.decode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'user': User.fromJson(body['user'])};
      }
      return {'success': false, 'error': body['error'] ?? 'Google login failed'};
    } catch (e) {
      return {'success': false, 'error': 'Connection error: $e'};
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
