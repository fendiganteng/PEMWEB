import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Kartu Profil',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const ProfileCardPage(),
    );
  }
}

class ProfileCardPage extends StatelessWidget {
  const ProfileCardPage({super.key});

  // Data profil (ganti sesuai datamu)
  static const String nama = 'M. Mauludiy Efendi';
  static const String prodi = 'Mahasiswa Sistem Informasi';
  static const String deskripsi =
      'Mahasiswa Sistem Informasi yang sedang belajar pengembangan '
      'aplikasi mobile dengan Flutter dan Dart.';
  static const List<String> skills = [
    'Dart',
    'Flutter',
    'UI Design',
    'Git',
    'SQL',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      appBar: AppBar(title: const Text('Kartu Profil')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Lebar > 600 -> berdampingan (Row), selain itu bertumpuk (Column)
          final bool isWide = constraints.maxWidth > 600;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: isWide ? const _WideLayout() : const _NarrowLayout(),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// Layout lebar: foto di kiri, info di kanan
class _WideLayout extends StatelessWidget {
  const _WideLayout();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        _ProfilePhoto(),
        SizedBox(width: 32),
        Expanded(child: _ProfileInfo(centered: false)),
      ],
    );
  }
}

// Layout sempit: foto di atas, info di bawah
class _NarrowLayout extends StatelessWidget {
  const _NarrowLayout();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        _ProfilePhoto(),
        SizedBox(height: 24),
        _ProfileInfo(centered: true),
      ],
    );
  }
}

// Foto profil + badge "Available" memakai Stack & Positioned
class _ProfilePhoto extends StatelessWidget {
  const _ProfilePhoto();

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Ganti child dengan backgroundImage: AssetImage('assets/foto.jpg')
        // setelah menambahkan foto di folder assets dan pubspec.yaml
        CircleAvatar(
          radius: 64,
          backgroundColor: Colors.indigo.shade100,
          child: const Icon(Icons.person, size: 72, color: Colors.indigo),
        ),
        Positioned(
          bottom: 0,
          right: -16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: const Text(
              'Available',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Nama, prodi, deskripsi, skill (Wrap + Chip), dan ikon kontak (Row)
class _ProfileInfo extends StatelessWidget {
  final bool centered;

  const _ProfileInfo({required this.centered});

  @override
  Widget build(BuildContext context) {
    final align = centered ? TextAlign.center : TextAlign.start;

    return Column(
      crossAxisAlignment:
      centered ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Text(
          ProfileCardPage.nama,
          textAlign: align,
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          ProfileCardPage.prodi,
          textAlign: align,
          style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
        ),
        const SizedBox(height: 12),
        Text(
          ProfileCardPage.deskripsi,
          textAlign: align,
          style: const TextStyle(fontSize: 14, height: 1.5),
        ),
        const SizedBox(height: 16),
        // Wrap supaya chip otomatis pindah baris
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: centered ? WrapAlignment.center : WrapAlignment.start,
          children: [
            for (final skill in ProfileCardPage.skills)
              Chip(
                label: Text(skill),
                avatar: const Icon(Icons.code, size: 16),
              ),
          ],
        ),
        const SizedBox(height: 16),
        // Row berisi 3 ikon kontak
        Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            _ContactIcon(icon: Icons.email, label: 'Email'),
            SizedBox(width: 16),
            _ContactIcon(icon: Icons.phone, label: 'Telepon'),
            SizedBox(width: 16),
            _ContactIcon(icon: Icons.code, label: 'GitHub'),
          ],
        ),
      ],
    );
  }
}

class _ContactIcon extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ContactIcon({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          backgroundColor: Colors.indigo,
          child: Icon(icon, color: Colors.white),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}