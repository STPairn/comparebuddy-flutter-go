import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import '../models/car.dart';
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

  // Car API methods
  Future<List<CarBrand>> getCarBrands() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/cars/brands'));
      if (response.statusCode == 200) {
        List<dynamic> body = json.decode(response.body);
        return body.map((item) => CarBrand.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching car brands: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> getCarBrandById(int id) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/cars/brands/$id'));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      print('Error fetching car brand: $e');
      return null;
    }
  }

  Future<List<CarModel>> getCarModels({int? brandId, String? powertrainType, String? bodyType}) async {
    try {
      final params = <String, String>{};
      if (brandId != null) params['brand_id'] = brandId.toString();
      if (powertrainType != null) params['powertrain_type'] = powertrainType;
      if (bodyType != null) params['body_type'] = bodyType;

      final uri = Uri.parse('$baseUrl/cars/models').replace(queryParameters: params.isNotEmpty ? params : null);
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        List<dynamic> body = json.decode(response.body);
        return body.map((item) => CarModel.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching car models: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> getCarModelById(int id) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/cars/models/$id'));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      print('Error fetching car model: $e');
      return null;
    }
  }

  Future<CarVariant?> getCarVariantById(int id) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/cars/variants/$id'));
      if (response.statusCode == 200) {
        return CarVariant.fromJson(json.decode(response.body));
      }
      return null;
    } catch (e) {
      print('Error fetching car variant: $e');
      return null;
    }
  }

  Future<List<CarVariant>> compareCarVariants(List<int> ids) async {
    try {
      final idsStr = ids.join(',');
      final response = await http.get(Uri.parse('$baseUrl/cars/compare?ids=$idsStr'));
      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        List<dynamic> variants = body['variants'];
        return variants.map((item) => CarVariant.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      print('Error comparing car variants: $e');
      return [];
    }
  }

  Future<List<CarSearchResult>> searchCars(String q) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/cars/search?q=${Uri.encodeComponent(q)}'));
      if (response.statusCode == 200) {
        List<dynamic> body = json.decode(response.body);
        return body.map((item) => CarSearchResult.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      print('Error searching cars: $e');
      return [];
    }
  }

  Future<List<CarSearchResult>> browseCarsByPrice({double? minPrice, double? maxPrice, String? powertrainType, int? minRange, double? minFuelEfficiency}) async {
    try {
      final params = <String, String>{};
      if (minPrice != null) params['min_price'] = minPrice.toInt().toString();
      if (maxPrice != null) params['max_price'] = maxPrice.toInt().toString();
      if (powertrainType != null) params['powertrain_type'] = powertrainType;
      if (minRange != null && minRange > 0) params['min_range'] = minRange.toString();
      if (minFuelEfficiency != null && minFuelEfficiency > 0) params['min_fuel_efficiency'] = minFuelEfficiency.toString();

      final uri = Uri.parse('$baseUrl/cars/browse').replace(queryParameters: params.isNotEmpty ? params : null);
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        if (body == null) return [];
        List<dynamic> list = body;
        return list.map((item) => CarSearchResult.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      print('Error browsing cars by price: $e');
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
