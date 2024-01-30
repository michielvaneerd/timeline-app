import 'dart:io';

import 'package:http/http.dart' as http;
import 'dart:convert' as convert;
import 'dart:developer' as developer;

class MyHttp {
  String _getAuthHeader(
      String basicAuthUsername, String basicAuthPlainPassword) {
    return 'Basic ${convert.base64.encode(convert.utf8.encode('$basicAuthUsername:$basicAuthPlainPassword'))}';
  }

  Future<Map<String, dynamic>> get(String uri,
      {String? basicAuthUsername, String? basicAuthPlainPassword}) async {
    final Map<String, String> map = {};
    if (basicAuthUsername != null && basicAuthPlainPassword != null) {
      map[HttpHeaders.authorizationHeader] =
          _getAuthHeader(basicAuthUsername, basicAuthPlainPassword);
    }
    final response = await http.get(Uri.parse(uri), headers: map);
    developer.log(uri);
    developer.log(response.body);
    if (map.isNotEmpty) {
      developer.log(map.toString());
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
