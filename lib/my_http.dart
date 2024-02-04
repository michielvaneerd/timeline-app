import 'dart:io';

import 'package:http/http.dart' as http;
import 'dart:convert' as convert;
import 'dart:developer' as developer;

import 'package:http/http.dart';

class MyHttp {
  String _getAuthHeader(
      String basicAuthUsername, String basicAuthPlainPassword) {
    return 'Basic ${convert.base64.encode(convert.utf8.encode('$basicAuthUsername:$basicAuthPlainPassword'))}';
  }

  Map<String, String> _getHeaders(
      {String? basicAuthUsername,
      String? basicAuthPlainPassword,
      bool json = false}) {
    final Map<String, String> headers = {};
    if (json) {
      headers[HttpHeaders.contentTypeHeader] = 'application/json';
    }
    if (basicAuthUsername != null && basicAuthPlainPassword != null) {
      headers[HttpHeaders.authorizationHeader] =
          _getAuthHeader(basicAuthUsername, basicAuthPlainPassword);
    }
    return headers;
  }

  T _handleResponse<T>(Response response) {
    developer.log(response.body);
    //developer.log(response.headers['x-wp-totalpages'] ?? 'x-wp-totalpages');
    //developer.log(response.headers['x-wp-total'] ?? 'x-wp-total');
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return convert.jsonDecode(response.body);
    } else {
      throw Exception(response.toString());
    }
  }

  Future<T> delete<T>(String uri,
      {String? basicAuthUsername, String? basicAuthPlainPassword}) async {
    final headers = _getHeaders(
        basicAuthUsername: basicAuthUsername,
        basicAuthPlainPassword: basicAuthPlainPassword);
    final response = await http.delete(Uri.parse(uri), headers: headers);
    developer.log(uri);
    if (headers.isNotEmpty) {
      developer.log(headers.toString());
    }
    return _handleResponse<T>(response);
  }

  Future<List> getWithPagination(String uri,
      {String? basicAuthUsername, String? basicAuthPlainPassword}) async {
    List totalResult = [];
    var currentPage = 0;
    while (true) {
      currentPage += 1;
      final response = await getResponse(uri,
          basicAuthUsername: basicAuthUsername,
          basicAuthPlainPassword: basicAuthPlainPassword,
          page: currentPage);
      final totalPageCount =
          int.parse(response.headers['x-wp-totalpages'].toString());
      final totalItemCount =
          int.parse(response.headers['x-wp-total'].toString());
      totalResult.addAll(_handleResponse<List>(response));
      if (totalResult.length >= totalItemCount ||
          currentPage >= totalPageCount) {
        break;
      }
    }
    return totalResult;
  }

  Future<Response> getResponse(String uri,
      {String? basicAuthUsername,
      String? basicAuthPlainPassword,
      int? page}) async {
    final headers = _getHeaders(
        basicAuthUsername: basicAuthUsername,
        basicAuthPlainPassword: basicAuthPlainPassword);
    if (headers.isNotEmpty) {
      developer.log(headers.toString());
    }
    // TODO: use Uri.https etc. instead of Strings
    if (page != null) {
      uri = ('$uri&page=$page');
    }
    developer.log(uri);
    final response = await http.get(Uri.parse(uri), headers: headers);
    return response;
  }

  Future<T> get<T>(String uri,
      {String? basicAuthUsername, String? basicAuthPlainPassword}) async {
    final response = await getResponse(uri,
        basicAuthUsername: basicAuthUsername,
        basicAuthPlainPassword: basicAuthPlainPassword);
    return _handleResponse<T>(response);
  }

  Future<T> post<T>(String uri, Map<String, Object?> body,
      {String? basicAuthUsername, String? basicAuthPlainPassword}) async {
    final headers = _getHeaders(
        json: true,
        basicAuthUsername: basicAuthUsername,
        basicAuthPlainPassword: basicAuthPlainPassword);
    developer.log(uri);
    developer.log(convert.json.encode(body));
    final response = await http.post(Uri.parse(uri),
        headers: headers, body: convert.json.encode(body));
    return _handleResponse<T>(response);
  }
}
