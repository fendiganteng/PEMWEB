
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// ======================================
// 1. USER MODEL
// ======================================

class UserModel {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String avatar;

  const UserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.avatar = '',
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'].toString(),
      firstName: (json['first_name'] ?? '').toString(),
      lastName: (json['last_name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      avatar: (json['avatar'] ?? '').toString(),
    );
  }

  String get fullName => '$firstName $lastName'.trim();

  String get initials {
    final a = firstName.isNotEmpty ? firstName[0] : '';
    final b = lastName.isNotEmpty ? lastName[0] : '';
    return '$a$b'.toUpperCase();
  }
}

// ======================================
// 2. USER SERVICE - REST API REQRES
// ======================================

class ApiError implements Exception {
  final String message;

  const ApiError(this.message);

  @override
  String toString() => message;
}

class UserService {
  static const String baseUrl = 'https://reqres.in/api/users';

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

  Future<http.Response> request(
      Future<http.Response> Function() call,
      List<int> acceptedStatus,
      ) async {
    try {
      final response = await call().timeout(
        const Duration(seconds: 15),
      );

      if (!acceptedStatus.contains(response.statusCode)) {
        if (response.statusCode == 401 ||
            response.statusCode == 403) {
          throw const ApiError(
            'API Key ditolak. Periksa pengaturan API Key.',
          );
        }

        String detail = '';

        try {
          final data = jsonDecode(response.body);
          if (data is Map) {
            detail = (data['error'] ?? data['message'] ?? '')
                .toString();
          }
        } catch (_) {}

        throw ApiError(
          'HTTP ${response.statusCode}'
              '${detail.isNotEmpty ? ': $detail' : ''}',
        );
      }

      return response;
    } on TimeoutException {
      throw const ApiError(
        'Koneksi terlalu lama. Silakan coba lagi.',
      );
    } on http.ClientException {
      throw const ApiError(
        'Gagal terhubung ke server. Periksa internet atau CORS browser.',
      );
    }
  }

  // READ - GET
  Future<List<UserModel>> getUsers() async {
    final response = await request(
          () => http.get(
        Uri.parse('$baseUrl?page=1&per_page=12'),
        headers: headers,
      ),
      [200],
    );

    try {
      final body = jsonDecode(response.body);
      final List data = body['data'];

      return data
          .map((item) => UserModel.fromJson(item))
          .toList();
    } catch (_) {
      throw const ApiError(
        'Format data pengguna tidak sesuai.',
      );
    }
  }

  // CREATE - POST
  Future<UserModel> createUser(
      String firstName,
      String lastName,
      String email,
      ) async {
    final response = await request(
          () => http.post(
        Uri.parse(baseUrl),
        headers: headers,
        body: jsonEncode({
          'name': '$firstName $lastName',
          'job': 'User',
          'first_name': firstName,
          'last_name': lastName,
          'email': email,
        }),
      ),
      [200, 201],
    );

    final data = jsonDecode(response.body);
    final id = data['id']?.toString() ??
        DateTime.now().millisecondsSinceEpoch.toString();

    return UserModel(
      id: id,
      firstName: firstName,
      lastName: lastName,
      email: email,
    );
  }

  // UPDATE - PUT
  Future<UserModel> updateUser(UserModel user) async {
    await request(
          () => http.put(
        Uri.parse('$baseUrl/${user.id}'),
        headers: headers,
        body: jsonEncode({
          'name': user.fullName,
          'job': 'User',
          'first_name': user.firstName,
          'last_name': user.lastName,
          'email': user.email,
        }),
      ),
      [200, 201],
    );

    return user;
  }

  // DELETE
  Future<void> deleteUser(String id) async {
    await request(
          () => http.delete(
        Uri.parse('$baseUrl/$id'),
        headers: headers,
      ),
      [200, 204],
    );
  }
}

// ======================================
// 3. MAIN APPLICATION
// ======================================

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF527967);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Ruang Pengguna',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primary,
        ),
        scaffoldBackgroundColor: const Color(0xFFF7F9F6),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF7F9F6),
          foregroundColor: Color(0xFF263B30),
          centerTitle: false,
          elevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: Color(0xFFDDE5DE),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: Color(0xFFDDE5DE),
            ),
          ),
        ),
      ),
      home: const UserPage(),
    );
  }
}

// ======================================
// 4. HALAMAN UTAMA
// ======================================

class UserPage extends StatefulWidget {
  const UserPage({super.key});

  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  final UserService service = UserService();

  late Future<List<UserModel>> futureUsers;

  List<UserModel> users = [];
  String keyword = '';
  String? deletingId;

  @override
  void initState() {
    super.initState();
    futureUsers = loadUsers();
  }

  Future<List<UserModel>> loadUsers() async {
    final result = await service.getUsers();
    users = result;
    return result;
  }

  void refreshUsers() {
    setState(() {
      users = [];
      futureUsers = loadUsers();
    });
  }

  void showMessage(String message, {bool error = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error
            ? const Color(0xFFC15D5D)
            : const Color(0xFF527967),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  // ======================================
  // 5. PENGATURAN API KEY
  // ======================================

  Future<void> settingApiKey() async {
    final controller = TextEditingController(
      text: service.apiKey,
    );

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Pengaturan API'),
          content: SizedBox(
            width: 370,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Masukkan API Key ReqRes untuk menghubungkan aplikasi.',
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    labelText: 'API Key',
                    prefixIcon: Icon(Icons.key_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Jangan gunakan manage key rahasia di browser.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(
                dialogContext,
                controller.text.trim(),
              ),
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (result == null || result.isEmpty) return;

    if (result.startsWith('pro_')) {
      showMessage(
        'Manage key tidak aman digunakan di browser.',
        error: true,
      );
      return;
    }

    service.apiKey = result;
    refreshUsers();
  }

  // ======================================
  // 6. FORM CREATE & UPDATE
  // ======================================

  Future<void> openForm({UserModel? user}) async {
    final formKey = GlobalKey<FormState>();

    String firstName = user?.firstName ?? '';
    String lastName = user?.lastName ?? '';
    String email = user?.email ?? '';

    bool saving = false;
    final isEdit = user != null;

    final result = await showDialog<UserModel>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
              title: Text(
                isEdit ? 'Edit Pengguna' : 'Tambah Pengguna',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 21,
                ),
              ),
              content: SizedBox(
                width: 420,
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Lengkapi informasi pengguna di bawah ini.',
                          style: TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 20),

                        TextFormField(
                          initialValue: firstName,
                          decoration: const InputDecoration(
                            labelText: 'Nama Depan',
                            prefixIcon:
                            Icon(Icons.person_outline),
                          ),
                          onChanged: (value) => firstName = value,
                          validator: (value) {
                            if (value == null ||
                                value.trim().isEmpty) {
                              return 'Nama depan wajib diisi';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 14),

                        TextFormField(
                          initialValue: lastName,
                          decoration: const InputDecoration(
                            labelText: 'Nama Belakang',
                            prefixIcon:
                            Icon(Icons.person_outline),
                          ),
                          onChanged: (value) => lastName = value,
                          validator: (value) {
                            if (value == null ||
                                value.trim().isEmpty) {
                              return 'Nama belakang wajib diisi';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 14),

                        TextFormField(
                          initialValue: email,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Alamat Email',
                            prefixIcon:
                            Icon(Icons.mail_outline),
                          ),
                          onChanged: (value) => email = value,
                          validator: (value) {
                            final text = value?.trim() ?? '';
                            final valid = RegExp(
                              r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                            ).hasMatch(text);

                            if (!valid) {
                              return 'Masukkan email yang valid';
                            }

                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actionsPadding: const EdgeInsets.fromLTRB(
                20, 0, 20, 20,
              ),
              actions: [
                TextButton(
                  onPressed: saving
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: const Text('Batal'),
                ),
                FilledButton.icon(
                  onPressed: saving
                      ? null
                      : () async {
                    if (!formKey.currentState!.validate()) {
                      return;
                    }

                    setDialogState(() => saving = true);

                    try {
                      UserModel saved;

                      if (isEdit) {
                        saved = await service.updateUser(
                          UserModel(
                            id: user.id,
                            firstName: firstName.trim(),
                            lastName: lastName.trim(),
                            email: email.trim(),
                            avatar: user.avatar,
                          ),
                        );
                      } else {
                        saved = await service.createUser(
                          firstName.trim(),
                          lastName.trim(),
                          email.trim(),
                        );
                      }

                      if (!dialogContext.mounted) return;

                      Navigator.pop(dialogContext, saved);
                    } catch (e) {
                      if (dialogContext.mounted) {
                        setDialogState(() => saving = false);
                      }

                      showMessage('$e', error: true);
                    }
                  },
                  icon: saving
                      ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                      : const Icon(Icons.check),
                  label: Text(
                    saving
                        ? 'Menyimpan...'
                        : isEdit
                        ? 'Simpan Perubahan'
                        : 'Tambah',
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (!mounted || result == null) return;

    setState(() {
      if (isEdit) {
        final index = users.indexWhere(
              (item) => item.id == user.id,
        );

        if (index != -1) {
          users[index] = result;
        }
      } else {
        users.insert(0, result);
      }
    });

    showMessage(
      isEdit
          ? 'Data pengguna berhasil diperbarui!'
          : 'Pengguna baru berhasil ditambahkan!',
    );
  }

  // ======================================
  // 7. DELETE USER
  // ======================================

  Future<void> removeUser(UserModel user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Hapus Pengguna?'),
          content: Text(
            'Apakah kamu yakin ingin menghapus '
                '${user.fullName}?',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFC15D5D),
              ),
              onPressed: () =>
                  Navigator.pop(dialogContext, true),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );

    if (confirm != true || !mounted) return;

    setState(() => deletingId = user.id);

    try {
      await service.deleteUser(user.id);

      if (!mounted) return;

      setState(() {
        users.removeWhere((item) => item.id == user.id);
      });

      showMessage('Pengguna berhasil dihapus!');
    } catch (e) {
      showMessage('$e', error: true);
    } finally {
      if (mounted) {
        setState(() => deletingId = null);
      }
    }
  }

  // ======================================
  // 8. TAMPILAN KARTU PENGGUNA
  // ======================================

  Widget userCard(UserModel user) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(
          color: Color(0xFFE5EBE5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 10,
          horizontal: 8,
        ),
        child: ListTile(
          leading: CircleAvatar(
            radius: 25,
            backgroundColor: const Color(0xFFE3EFE6),
            child: Text(
              user.initials,
              style: const TextStyle(
                color: Color(0xFF527967),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          title: Text(
            user.fullName,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Text(
              user.email,
              style: const TextStyle(
                color: Color(0xFF829086),
                fontSize: 12,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          trailing: deletingId == user.id
              ? const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
            ),
          )
              : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'Edit',
                icon: const Icon(
                  Icons.edit_outlined,
                  color: Color(0xFF527967),
                ),
                onPressed: () => openForm(user: user),
              ),
              IconButton(
                tooltip: 'Hapus',
                icon: const Icon(
                  Icons.delete_outline,
                  color: Color(0xFFC15D5D),
                ),
                onPressed: () => removeUser(user),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ======================================
  // 9. FUTUREBUILDER
  // ======================================

  Widget userList() {
    return FutureBuilder<List<UserModel>>(
      future: futureUsers,
      builder: (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.wifi_off_rounded,
                  size: 55,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Gagal memuat pengguna',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                  ),
                  child: Text(
                    '${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: refreshUsers,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Coba Lagi'),
                ),
              ],
            ),
          );
        }

        final filteredUsers = users.where((user) {
          final search = keyword.toLowerCase();

          return user.fullName
              .toLowerCase()
              .contains(search) ||
              user.email.toLowerCase().contains(search);
        }).toList();

        if (filteredUsers.isEmpty) {
          return const Center(
            child: Text(
              'Tidak ada pengguna ditemukan.',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          itemCount: filteredUsers.length,
          itemBuilder: (context, index) {
            return userCard(filteredUsers[index]);
          },
        );
      },
    );
  }

  // ======================================
  // 10. MAIN UI
  // ======================================

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF527967);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 75,
        title: const Row(
          children: [
            CircleAvatar(
              backgroundColor: Color(0xFFE3EFE6),
              child: Icon(
                Icons.people_alt_outlined,
                color: primary,
              ),
            ),
            SizedBox(width: 12),
            Text(
              'Ruang Pengguna',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 19,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Pengaturan API Key',
            onPressed: settingApiKey,
            icon: const Icon(Icons.key_outlined),
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: refreshUsers,
            icon: const Icon(Icons.refresh),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 850,
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // HEADER
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6F0E9),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kelola Pengguna',
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF294D3B),
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Kelola informasi pengguna dengan '
                            'mudah, cepat, dan sederhana.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF688073),
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Mode demo ReqRes • Perubahan tidak '
                            'tersimpan permanen.',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF688073),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // SEARCH + ADD
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          hintText: 'Cari pengguna...',
                          hintStyle: TextStyle(fontSize: 13),
                          prefixIcon: Icon(Icons.search),
                        ),
                        onChanged: (value) {
                          setState(() => keyword = value);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 17,
                          vertical: 18,
                        ),
                      ),
                      onPressed: () => openForm(),
                      icon: const Icon(
                        Icons.add,
                        size: 20,
                      ),
                      label: const Text('Tambah'),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                const Text(
                  'Daftar Pengguna',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF294D3B),
                  ),
                ),

                const SizedBox(height: 6),

                const Text(
                  'Informasi pengguna yang tersedia.',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),

                const SizedBox(height: 18),

                // DATA FROM API
                Expanded(
                  child: userList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
