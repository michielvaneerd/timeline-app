import 'dart:io';

import 'package:http/http.dart' as http;
import 'dart:convert' as convert;
import 'dart:developer' as developer;

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

  Future<Map<String, dynamic>> get(String uri,
      {String? basicAuthUsername, String? basicAuthPlainPassword}) async {
    final headers = _getHeaders(
        basicAuthUsername: basicAuthUsername,
        basicAuthPlainPassword: basicAuthPlainPassword);
    final response = await http.get(Uri.parse(uri), headers: headers);
    developer.log(uri);
    developer.log(response.body);
    if (headers.isNotEmpty) {
      developer.log(headers.toString());
    }
    if (response.statusCode == 200) {
      // Sometimes we get a list and sometimes we get a map, but we always want to return a map.
      final map = convert.jsonDecode(response.body);
      if (map is List) {
        return {'items': map};
      }
      return map;
    } else {
      throw Exception(response.toString());
    }
  }

  Future<Map> post(String uri, Map<String, Object?> body,
      {String? basicAuthUsername, String? basicAuthPlainPassword}) async {
    final headers = _getHeaders(
        json: true,
        basicAuthUsername: basicAuthUsername,
        basicAuthPlainPassword: basicAuthPlainPassword);
    final response = await http.post(Uri.parse(uri),
        headers: headers, body: convert.json.encode(body));
    developer.log(uri);
    developer.log(response.body);
    if (response.statusCode == 200) {
      final map = convert.jsonDecode(response.body);
      return map;
    } else {
      throw Exception(response.toString());
    }
  }

  Future<String> getAsString(String uri) async {
    final response = await http.get(Uri.parse(uri));
    developer.log(uri);
    developer.log(response.body);
    if (response.statusCode == 200) {
      return response.body;
    } else {
      throw Exception(response.toString());
    }
  }
}
