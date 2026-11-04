import 'dart:math';

import 'package:avatar_glow/avatar_glow.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:faker/faker.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

// ============================================================
// ENTRY POINT
// ============================================================
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Wajib agar DateFormat bisa memakai locale Indonesia
  await initializeDateFormatting('id_ID', null);
  runApp(const ContactApp());
}

class ContactApp extends StatelessWidget {
  const ContactApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Daftar Kontak',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
      ),
      home: const MainPage(),
    );
  }
}

// ============================================================
// MODEL & DATA DUMMY (Faker)
// ============================================================
class Contact {
  final String name;
  final String phone;
  final String email;
  final String category;
  final DateTime addedAt;

  const Contact({
    required this.name,
    required this.phone,
    required this.email,
    required this.category,
    required this.addedAt,
  });
}

class ContactRepository {
  static const List<String> categories = ['Keluarga', 'Teman', 'Kerja'];

  /// Dibuat sekali saja, dipakai oleh halaman Kontak dan Cari.
  static final List<Contact> contacts = _generate(20);

  static List<Contact> _generate(int count) {
    final faker = Faker();
    final random = Random();

    return List.generate(count, (i) {
      return Contact(
        name: faker.person.name(),
        phone: '08${random.nextInt(900000000) + 100000000}',
        email: faker.internet.email(),
        category: categories[random.nextInt(categories.length)],
        addedAt: DateTime.now().subtract(Duration(days: random.nextInt(365))),
      );
    });
  }
}

// ============================================================
// HALAMAN UTAMA + CONVEX APP BAR
// ============================================================
class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    ContactPage(),
    SearchPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: ConvexAppBar(
        style: TabStyle.reactCircle,
        backgroundColor: Theme.of(context).colorScheme.primary,
        initialActiveIndex: _currentIndex,
        items: const [
          TabItem(icon: Icons.contacts, title: 'Kontak'),
          TabItem(icon: Icons.search, title: 'Cari'),
          TabItem(icon: Icons.person, title: 'Profil'),
        ],
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}

// ============================================================
// WIDGET ITEM KONTAK (dipakai di 2 halaman)
// ============================================================
class ContactTile extends StatelessWidget {
  final Contact contact;

  const ContactTile({super.key, required this.contact});

  @override
  Widget build(BuildContext context) {
    // Contoh hasil: "05 September 2026"
    final tanggal =
    DateFormat('dd MMMM yyyy', 'id_ID').format(contact.addedAt);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      child: ListTile(
        leading: CircleAvatar(
          child: Text(contact.name[0].toUpperCase()),
        ),
        title: Text(
          contact.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${contact.phone}\n${contact.email}\nDitambahkan pada $tanggal',
        ),
        isThreeLine: true,
        trailing: Chip(
          label: Text(contact.category, style: const TextStyle(fontSize: 11)),
          visualDensity: VisualDensity.compact,
        ),
      ),
    );
  }
}

// ============================================================
// HALAMAN 1: KONTAK (ListView.builder)
// ============================================================
class ContactPage extends StatelessWidget {
  const ContactPage({super.key});

  @override
  Widget build(BuildContext context) {
    final contacts = ContactRepository.contacts;

    return Scaffold(
      appBar: AppBar(title: Text('Kontak (${contacts.length})')),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: contacts.length,
        itemBuilder: (context, index) => ContactTile(contact: contacts[index]),
      ),
    );
  }
}

// ============================================================
// HALAMAN 2: CARI (DropdownSearch offline)
// ============================================================
class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  String? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    final filtered = _selectedCategory == null
        ? <Contact>[]
        : ContactRepository.contacts
        .where((c) => c.category == _selectedCategory)
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Cari Kontak')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: DropdownSearch<String>(
              items: ContactRepository.categories,
              selectedItem: _selectedCategory,
              popupProps: const PopupProps.menu(
                showSearchBox: true,
                searchFieldProps: TextFieldProps(
                  decoration: InputDecoration(
                    hintText: 'Cari kategori...',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ),
              dropdownDecoratorProps: const DropDownDecoratorProps(
                dropdownSearchDecoration: InputDecoration(
                  labelText: 'Kategori Kontak',
                  hintText: 'Pilih kategori',
                  border: OutlineInputBorder(),
                ),
              ),
              onChanged: (value) => setState(() => _selectedCategory = value),
            ),
          ),
          Expanded(
            child: _selectedCategory == null
                ? const Center(child: Text('Pilih kategori untuk melihat kontak'))
                : filtered.isEmpty
                ? const Center(child: Text('Tidak ada kontak di kategori ini'))
                : ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (context, index) =>
                  ContactTile(contact: filtered[index]),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// HALAMAN 3: PROFIL (AvatarGlow)
// ============================================================
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AvatarGlow(
              glowColor: Theme.of(context).colorScheme.primary,
              child: const CircleAvatar(
                radius: 60,
                backgroundColor: Colors.indigo,
                // Ganti dengan foto sendiri: AssetImage('assets/foto.jpg')
                backgroundImage: NetworkImage('https://i.pravatar.cc/300'),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Nama Mahasiswa',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text('Sistem Informasi'),
            const Text('mahasiswa@email.com'),
          ],
        ),
      ),
    );
  }
}