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
    if (response.statusCode == 200) {
      return convert.jsonDecode(response.body);
    } else {
      throw Exception(response.toString());
    }
  }

  Future<T> get<T>(String uri,
      {String? basicAuthUsername, String? basicAuthPlainPassword}) async {
    final headers = _getHeaders(
        basicAuthUsername: basicAuthUsername,
        basicAuthPlainPassword: basicAuthPlainPassword);
    final response = await http.get(Uri.parse(uri), headers: headers);
    developer.log(uri);
    if (headers.isNotEmpty) {
      developer.log(headers.toString());
    }
    return _handleResponse<T>(response);
  }

  Future<T> post<T>(String uri, Map<String, Object?> body,
      {String? basicAuthUsername, String? basicAuthPlainPassword}) async {
    final headers = _getHeaders(
        json: true,
        basicAuthUsername: basicAuthUsername,
        basicAuthPlainPassword: basicAuthPlainPassword);
    final response = await http.post(Uri.parse(uri),
        headers: headers, body: convert.json.encode(body));
    developer.log(uri);
    return _handleResponse<T>(response);
  }
}
