import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/admin_order.dart';
import '../models/menu_item.dart';
import '../models/orders.dart';
import '../models/user_model.dart';

class ApiService {
  static const String _envBaseUrl = String.fromEnvironment('API_BASE_URL');
  static const Duration _requestTimeout = Duration(seconds: 15);

static String get baseUrl {
  if (_envBaseUrl.isNotEmpty) {
    return _normalizeBaseUrl(_envBaseUrl);
  }

  if (kIsWeb) return 'http://localhost:3000/api';

  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
      return 'http://192.168.1.103/FOMS/api';
    case TargetPlatform.iOS:
      return 'http://localhost:3000/FOMS/api';
    default:
      return 'http://localhost:3000/api';
  }
}

  static String _normalizeBaseUrl(String value) {
    if (value.endsWith('/')) {
      return value.substring(0, value.length - 1);
    }
    return value;
  }

  static Uri _buildUri(String endpoint) {
    return Uri.parse('$baseUrl/$endpoint');
  }

  static Exception _networkException(Object error) {
    return Exception(
      'Network error while connecting to $baseUrl. '
      'If you are using a physical device, set --dart-define=API_BASE_URL=http://<YOUR_PC_LAN_IP>:3000/api. '
      'Original error: $error',
    );
  }

  static Future<Map<String, dynamic>> _postJson(
    String endpoint,
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await http
          .post(
            _buildUri(endpoint),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(_requestTimeout);
      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
      return jsonDecode(response.body) as Map<String, dynamic>;
    } on TimeoutException catch (error) {
      throw _networkException(error);
    } on http.ClientException catch (error) {
      throw _networkException(error);
    } catch (error) {
      if (error is Exception &&
          error.toString().startsWith('Exception: HTTP ')) {
        rethrow;
      }
      throw _networkException(error);
    }
  }

  static Future<Map<String, dynamic>> login(
    String phone,
    String password,
  ) async {
    return _postJson('login', {'phone': phone, 'password': password});
  }

  static Future<Map<String, dynamic>> unifiedLogin(
    String identifier,
    String password,
    {
    String key = '',
    String role = '',
  }) async {
    final payload = <String, dynamic>{
      'identifier': identifier,
      'password': password,
      'key': key,
      if (role.isNotEmpty) 'role': role,
    };
    return _postJson('unified', payload);
  }

  static Future<Map<String, dynamic>> adminLogin(
    String username,
    String password,
  ) async {
    return _postJson('admin_login', {
      'username': username,
      'password': password,
    });
  }

  static Future<Map<String, dynamic>> register(
    String name,
    String phone,
    String password,
    String role,
    String location,
  ) async {
    return _postJson('register', {
      'name': name,
      'phone': phone,
      'password': password,
      'role': role,
      'location': location,
    });
  }

  static Future<List<String>> getLocations() async {
    final response = await http
        .get(_buildUri('get_locations'))
        .timeout(_requestTimeout);
    if (response.statusCode != 200) {
      throw Exception('Failed to load locations');
    }

    final body = json.decode(response.body) as Map<String, dynamic>;
    final locations = (body['locations'] ?? []) as List;
    return locations.map((e) => e.toString()).toList();
  }

  static Future<List<MenuItem>> getMenu() async {
    final response = await http
        .get(_buildUri('get_menu'))
        .timeout(_requestTimeout);
    if (response.statusCode == 200) {
      List data = json.decode(response.body)['data'];
      return data.map((e) => MenuItem.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load menu');
    }
  }

  static Future<List<Order>> getOrders(String customerPhone) async {
    final response = await http
        .get(_buildUri('get_orders?phone=$customerPhone'))
        .timeout(_requestTimeout);
    if (response.statusCode == 200) {
      final body = json.decode(response.body) as Map<String, dynamic>;
      final data = (body['orders'] ?? []) as List;
      return data.map((e) => Order.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load orders');
    }
  }

  static Future<bool> placeOrder(String customerPhone, String address, Map<String, int> items, int amount) async {
    final data = await _postJson('place_order', {
      'customer_phone': customerPhone.trim(),
      'address': address,
      'items': json.encode(items),
      'amount': amount,
      'total_amount': amount,
    });
    return data['status'] == 'success';
  }

  static Future<bool> requestCancel(String createdAt) async {
    final response = await http
        .post(
          _buildUri('request_cancel_api'),
          body: {'created_at': createdAt},
        )
        .timeout(_requestTimeout);
    if (response.statusCode != 200) {
      return false;
    }
    try {
      final body = json.decode(response.body) as Map<String, dynamic>;
      return body['status'] == 'success';
    } catch (_) {
      return false;
    }
  }

  static Future<bool> requestCancelApi(String customerPhone, String createdAt) async {
    final data = await _postJson('request_cancel_api', {
      'customer_phone': customerPhone.trim(),
      'created_at': createdAt.trim(),
    });
    return data['status'] == 'success';
  }

  static Future<bool> updateOrder(
    String createdAt,
    String address,
    Map<String, int> items,
  ) async {
    final response = await http
        .post(
          _buildUri('update_order_api'),
          body: {
            'update': '1',
            'created_at': createdAt,
            'address': address,
            'items': json.encode(items),
          },
        )
        .timeout(_requestTimeout);
    return response.statusCode == 200;
  }

  static Future<Map<String, dynamic>> updateOrderApi(
    String customerPhone,
    String createdAt,
    String address,
    dynamic items,
  ) async {
    return _postJson('update_order_api', {
      'customer_phone': customerPhone.trim(),
      'created_at': createdAt.trim(),
      'address': address,
      'items': items,
    });
  }

  static Future<List<AdminOrder>> getAdminOrders() async {
    final response = await http
        .get(_buildUri('admin_orders_api'))
        .timeout(_requestTimeout);
    if (response.statusCode != 200) {
      throw Exception('Failed to load admin orders');
    }
    final body = json.decode(response.body) as Map<String, dynamic>;
    final data = (body['orders'] ?? []) as List;
    return data.map((e) => AdminOrder.fromJson(e)).toList();
  }

  static Future<bool> updateOrderStatus(
    String customerPhone,
    String createdAt,
    String status,
  ) async {
    final data = await _postJson('admin_orders_api', {
      'action': 'update_status',
      'customer_phone': customerPhone,
      'created_at': createdAt,
      'status': status,
    });
    return data['status'] == 'success';
  }

  static Future<bool> approveCancel(
    String customerPhone,
    String createdAt,
  ) async {
    final data = await _postJson('admin_orders_api', {
      'action': 'approve_cancel',
      'customer_phone': customerPhone,
      'created_at': createdAt,
    });
    return data['status'] == 'success';
  }

  static Future<bool> rejectCancel(
    String customerPhone,
    String createdAt,
  ) async {
    final data = await _postJson('admin_orders_api', {
      'action': 'reject_cancel',
      'customer_phone': customerPhone,
      'created_at': createdAt,
    });
    return data['status'] == 'success';
  }

  // --- User Management ---

  static Future<List<UserModel>> getUsers() async {
    final response = await http
        .get(_buildUri('admin_users_api'))
        .timeout(_requestTimeout);
    if (response.statusCode != 200) {
      throw Exception('Failed to load users');
    }
    final body = json.decode(response.body) as Map<String, dynamic>;
    final data = (body['users'] ?? []) as List;
    return data.map((e) => UserModel.fromJson(e)).toList();
  }

  static Future<bool> updateUserRole(String phone, String role) async {
    final data = await _postJson('admin_users_api', {
      'action': 'update_role',
      'phone': phone,
      'role': role,
    });
    return data['status'] == 'success';
  }

  static Future<bool> deleteUser(String phone) async {
    final data = await _postJson('admin_users_api', {
      'action': 'delete_user',
      'phone': phone,
    });
    return data['status'] == 'success';
  }
}
