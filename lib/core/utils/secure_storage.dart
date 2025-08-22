import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';

class SecureStorage {
  final FlutterSecureStorage _storage = FlutterSecureStorage();
  
  static const String authTokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userIdKey = 'user_id';
  
  Future<void> write(String key, String value) async {
    await _storage.write(key: key, value: value);
  }
  
  Future<String?> read(String key) async {
    return await _storage.read(key: key);
  }
  
  Future<void> delete(String key) async {
    await _storage.delete(key: key);
  }
  
  Future<void> deleteAll() async {
    await _storage.deleteAll();
  }
}