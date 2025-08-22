import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/connectivity.dart';
import 'auth_service.dart';

class ApiService extends GetxService {
  final AuthService authService = Get.find<AuthService>();
  final ConnectivityService connectivityService = Get.find<ConnectivityService>();
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  final String baseUrl = 'https://jsonplaceholder.typicode.com';


  final int maxRetries = 3;
  final Duration retryDelay = Duration(seconds: 2);

  Future<http.Response> _requestWithRetry(
      Future<http.Response> Function() request, {
        int retryCount = 0,
      }) async {
    try {
      if (!(await connectivityService.isConnectedAsync)) {
        throw Exception('No internet connection');
      }

      final response = await request();

      if (response.statusCode == 401 && retryCount < maxRetries) {
        final currentUser = _firebaseAuth.currentUser;
        if (currentUser != null) {
          await currentUser.getIdToken(true);
        }
        return _requestWithRetry(request, retryCount: retryCount + 1);
      }

      return response;
    } catch (e) {
      if (retryCount < maxRetries) {
        await Future.delayed(retryDelay);
        return _requestWithRetry(request, retryCount: retryCount + 1);
      }
      rethrow;
    }
  }

  Future<http.Response> get(String endpoint) async {
    return _requestWithRetry(() async {
      final currentUser = _firebaseAuth.currentUser;
      final token = currentUser != null ? await currentUser.getIdToken() : '';

      return http.get(
        Uri.parse('$baseUrl/$endpoint'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
    });
  }

  Future<http.Response> post(String endpoint, dynamic data) async {
    return _requestWithRetry(() async {
      final currentUser = _firebaseAuth.currentUser;
      final token = currentUser != null ? await currentUser.getIdToken() : '';

      return http.post(
        Uri.parse('$baseUrl/$endpoint'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(data),
      );
    });
  }

  Future<http.Response> put(String endpoint, dynamic data) async {
    return _requestWithRetry(() async {
      final currentUser = _firebaseAuth.currentUser;
      final token = currentUser != null ? await currentUser.getIdToken() : '';

      return http.put(
        Uri.parse('$baseUrl/$endpoint'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(data),
      );
    });
  }

  Future<http.Response> delete(String endpoint) async {
    return _requestWithRetry(() async {
      final currentUser = _firebaseAuth.currentUser;
      final token = currentUser != null ? await currentUser.getIdToken() : '';

      return http.delete(
        Uri.parse('$baseUrl/$endpoint'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
    });
  }
}