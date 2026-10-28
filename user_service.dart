
import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import '../models/user_model.dart';

class UserService {
  final String baseUrl = 'https://reqres.in/api/users';

  String apiKey = const String.fromEnvironment(
    'REQRES_API_KEY',
    defaultValue: 'reqres-free-v1',
  );

  Map<String, String> get headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'x-api-key': apiKey,
    'X-Reqres-Env': 'prod',
  };

  // READ - GET
  Future<List<UserModel>> getUsers() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl?page=1&per_page=12'),
        headers: headers,
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List users = data['data'];

        return users
            .map((user) => UserModel.fromJson(user))
            .toList();
      }

      throw Exception(
        'GET gagal: HTTP ${response.statusCode}',
      );
    } on TimeoutException {
      throw Exception('Koneksi timeout');
    } on http.ClientException {
      throw Exception('Tidak dapat terhubung ke API');
    }
  }

  // CREATE - POST
  Future<UserModel> createUser(
      String firstName,
      String lastName,
      String email,
      ) async {
    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: headers,
        body: jsonEncode({
          'name': '$firstName $lastName',
          'job': 'User',
          'first_name': firstName,
          'last_name': lastName,
          'email': email,
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 ||
          response.statusCode == 201) {
        final data = jsonDecode(response.body);

        return UserModel(
          id: (data['id'] ??
              DateTime.now().millisecondsSinceEpoch)
              .toString(),
          firstName: firstName,
          lastName: lastName,
          email: email,
        );
      }

      throw Exception(
        'POST gagal: HTTP ${response.statusCode}',
      );
    } on TimeoutException {
      throw Exception('Koneksi timeout');
    } on http.ClientException {
      throw Exception('Tidak dapat terhubung ke API');
    }
  }

  // UPDATE - PUT
  Future<UserModel> updateUser(UserModel user) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/${user.id}'),
        headers: headers,
        body: jsonEncode({
          'name': user.fullName,
          'job': 'User',
          'first_name': user.firstName,
          'last_name': user.lastName,
          'email': user.email,
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 ||
          response.statusCode == 201) {
        return user;
      }

      throw Exception(
        'PUT gagal: HTTP ${response.statusCode}',
      );
    } on TimeoutException {
      throw Exception('Koneksi timeout');
    } on http.ClientException {
      throw Exception('Tidak dapat terhubung ke API');
    }
  }

  // DELETE
  Future<void> deleteUser(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/$id'),
        headers: headers,
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 ||
          response.statusCode == 204) {
        return;
      }

      throw Exception(
        'DELETE gagal: HTTP ${response.statusCode}',
      );
    } on TimeoutException {
      throw Exception('Koneksi timeout');
    } on http.ClientException {
      throw Exception('Tidak dapat terhubung ke API');
    }
  }
}
