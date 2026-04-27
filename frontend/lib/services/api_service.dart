import 'package:dio/dio.dart';

import '../services/local_storage.dart';
import '../utils/constants.dart';

class ApiService {
  ApiService._();

  static final Dio dio = _createDio();

  static Dio _createDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.apiBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
      ),
    );

    dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (obj) => print('API_LOG: $obj'),
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = LocalStorage.accessToken;
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (e, handler) {
          if (e.response?.statusCode == 401) {
            print('API_LOG: Unauthorized (401) detected. Clearing session.');
            LocalStorage.clearAuth();
            // We don't have easy access to AuthNotifier here, but clearing storage
            // will cause the app to show the login screen on the next cold build
            // or when AuthNotifier next checks its state.
          }
          handler.next(e);
        },
      ),
    );

    return dio;
  }
}
