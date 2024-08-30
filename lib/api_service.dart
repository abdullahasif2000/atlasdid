import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:async';

class ApiService {
  final String baseUrl;

  ApiService(this.baseUrl);


  Future<Map<String, dynamic>> getData({
    required String plant,
    String mat = '',
    String matgrp = '',
    String strloc = '',
    Duration timeout = const Duration(seconds: 20),
  }) async {

    Map<String, String> queryParams = {
      if (plant.isNotEmpty) 'Plant': plant,
      if (mat.isNotEmpty) 'Mat': mat,
      if (matgrp.isNotEmpty) 'Matgrp': matgrp,
      if (strloc.isNotEmpty) 'Strloc': strloc,
    };


    final uri = Uri.parse(baseUrl + '/STR_Display_Stock_dev').replace(queryParameters: queryParams);

    try {
      final response = await http.get(uri).timeout(timeout);

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to load data: ${response.statusCode}');
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
        Duration timeout = const Duration(seconds: 15),
      }) async {
    final uri = Uri.parse('$baseUrl$endpoint');

    try {
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(data),
      ).timeout(timeout);

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to post data: ${response.statusCode}');
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
    Duration timeout = const Duration(seconds: 30),
  }) async {

    Map<String, String> queryParams = {
      if (plant.isNotEmpty) 'Plant': plant,
      if (mat.isNotEmpty) 'Mat': mat,
      if (matgrp.isNotEmpty) 'Matgrp': matgrp,
      if (strloc.isNotEmpty) 'Strloc': strloc,
    };


    final uri = Uri.parse(baseUrl + '/STR_Display_Stock_dev').replace(queryParameters: queryParams);

    try {
      final response = await http.get(uri).timeout(timeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> decoded = json.decode(response.body) as Map<String, dynamic>;
        return decoded['Items'] as List<dynamic>;
      } else {
        throw Exception('Failed to load data: ${response.statusCode}');
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
