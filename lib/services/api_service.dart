import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final String _baseUrl = AppConstants.baseUrl;
  final Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  void setAuthToken(String token) {
    _headers['Authorization'] = 'Bearer $token';
  }

  void removeAuthToken() {
    _headers.remove('Authorization');
  }

  Future<Map<String, dynamic>> get(String endpoint) async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl$endpoint'),
            headers: _headers,
          )
          .timeout(Duration(milliseconds: AppConstants.apiTimeout));

      return _handleResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl$endpoint'),
            headers: _headers,
            body: json.encode(data),
          )
          .timeout(Duration(milliseconds: AppConstants.apiTimeout));

      return _handleResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> put(String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await http
          .put(
            Uri.parse('$_baseUrl$endpoint'),
            headers: _headers,
            body: json.encode(data),
          )
          .timeout(Duration(milliseconds: AppConstants.apiTimeout));

      return _handleResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> delete(String endpoint) async {
    try {
      final response = await http
          .delete(
            Uri.parse('$_baseUrl$endpoint'),
            headers: _headers,
          )
          .timeout(Duration(milliseconds: AppConstants.apiTimeout));

      return _handleResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    final statusCode = response.statusCode;
    final responseBody = response.body;

    if (statusCode >= 200 && statusCode < 300) {
      if (responseBody.isEmpty) {
        return {'success': true};
      }
      return json.decode(responseBody);
    } else if (statusCode == 401) {
      throw Exception('인증이 필요합니다.');
    } else if (statusCode == 403) {
      throw Exception('접근 권한이 없습니다.');
    } else if (statusCode == 404) {
      throw Exception('요청한 리소스를 찾을 수 없습니다.');
    } else if (statusCode >= 500) {
      throw Exception('서버 오류가 발생했습니다.');
    } else {
      throw Exception('요청 처리 중 오류가 발생했습니다. (상태 코드: $statusCode)');
    }
  }

  Exception _handleError(dynamic error) {
    if (error is SocketException) {
      return Exception('네트워크 연결을 확인해주세요.');
    } else if (error is HttpException) {
      return Exception('HTTP 요청 중 오류가 발생했습니다.');
    } else if (error is FormatException) {
      return Exception('응답 데이터 형식이 올바르지 않습니다.');
    } else {
      return Exception('알 수 없는 오류가 발생했습니다: $error');
    }
  }
}
