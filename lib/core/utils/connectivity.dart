// lib/core/utils/connectivity.dart
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';

class ConnectivityService extends GetxService {
  final Connectivity _connectivity = Connectivity();
  final RxBool isConnected = true.obs;

  @override
  void onInit() {
    super.onInit();
    _initConnectivity();
    _connectivity.onConnectivityChanged.listen(_updateConnectionStatus as void Function(List<ConnectivityResult> event)?);
  }

  Future<void> _initConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _updateConnectionStatus(result as ConnectivityResult);
    } catch (e) {
      Get.log('Couldn\'t check connectivity status: $e');
    }
  }

  void _updateConnectionStatus(ConnectivityResult result) {
    isConnected.value = result != ConnectivityResult.none;
  }

  // Add this method for easier access to the connection status
  Future<bool> get isConnectedAsync async {
    final result = await _connectivity.checkConnectivity();
    return result != ConnectivityResult.none;
  }
}