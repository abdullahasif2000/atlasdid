import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:async';

class ApiService {
  final String baseUrl;
  final Duration defaultTimeout;

  ApiService(this.baseUrl, {this.defaultTimeout = const Duration(seconds: 20)});


  Future<Map<String, dynamic>> getData({
    required String plant,
    String mat = '',
    String matgrp = '',
    String strloc = '',
    Duration? timeout,
  }) async {
    Map<String, String> queryParams = {
      if (plant.isNotEmpty) 'Plant': plant,
      if (mat.isNotEmpty) 'Mat': mat,
      if (matgrp.isNotEmpty) 'Matgrp': matgrp,
      if (strloc.isNotEmpty) 'Strloc': strloc,
    };

    final uri = Uri.parse('$baseUrl/STR_Display_Stock_dev').replace(queryParameters: queryParams);

    try {
      final response = await http.get(uri).timeout(timeout ?? defaultTimeout);

      if (response.statusCode == 200) {
        if (response.body.isEmpty) {
          throw Exception('Empty response body.');
        }
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to load data: ${response.statusCode} ${response.reasonPhrase}');
      }
    } on TimeoutException catch (_) {
      throw Exception('Request timed out. Please try again.');
    } on http.ClientException catch (e) {
      throw Exception('Client error: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }


  Future<Map<String, dynamic>> postData(
      String endpoint,
      Map<String, dynamic> data, {
        Duration? timeout,
      }) async {
    final uri = Uri.parse('$baseUrl$endpoint');

    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      ).timeout(timeout ?? defaultTimeout);

      if (response.statusCode == 200) {
        if (response.body.isEmpty) {
          throw Exception('Empty response body.');
        }
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to post data: ${response.statusCode} ${response.reasonPhrase}');
      }
    } on TimeoutException catch (_) {
      throw Exception('Request timed out. Please try again.');
    } on http.ClientException catch (e) {
      throw Exception('Client error: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }


  Future<List<dynamic>> fetchAllRecords({
    required String plant,
    String mat = '',
    String matgrp = '',
    String strloc = '',
    Duration? timeout,
  }) async {
    Map<String, String> queryParams = {
      if (plant.isNotEmpty) 'Plant': plant,
      if (mat.isNotEmpty) 'Mat': mat,
      if (matgrp.isNotEmpty) 'Matgrp': matgrp,
      if (strloc.isNotEmpty) 'Strloc': strloc,
    };

    final uri = Uri.parse('$baseUrl/STR_Display_Stock_dev').replace(queryParameters: queryParams);

    try {
      final response = await http.get(uri).timeout(timeout ?? defaultTimeout);

      if (response.statusCode == 200) {
        if (response.body.isEmpty) {
          throw Exception('Empty response body.');
        }
        final Map<String, dynamic> decoded = json.decode(response.body) as Map<String, dynamic>;
        final items = decoded['Items'];
        if (items is List) {
          return items;
        } else {
          throw Exception('Unexpected response format: "Items" is not a list.');
        }
      } else {
        throw Exception('Failed to load data: ${response.statusCode} ${response.reasonPhrase}');
      }
    } on TimeoutException catch (_) {
      throw Exception('Request timed out. Please try again.');
    } on http.ClientException catch (e) {
      throw Exception('Client error: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }


  Future<Map<String, dynamic>> login(String email, String password, {Duration? timeout}) async {
    final uri = Uri.parse('$baseUrl/api/login');

    final body = json.encode({
      'email': email,
      'password': password,
    });

    print('Logging in to: $uri');
    print('Request body: $body');

    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: body,
      ).timeout(timeout ?? defaultTimeout);

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        if (response.body.isEmpty) {
          throw Exception('Empty response body.');
        }
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to login: ${response.statusCode} ${response.reasonPhrase}');
      }
    } on TimeoutException catch (_) {
      throw Exception('Request timed out. Please try again.');
    } on http.ClientException catch (e) {
      throw Exception('Client error: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }
}
