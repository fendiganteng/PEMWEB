import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Form Registrasi',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
      ),
      home: const RegistrationPage(),
    );
  }
}

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  // Kunci form untuk validasi
  final _formKey = GlobalKey<FormState>();

  // Controller tiap field
  final _namaController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // FocusNode agar tombol "next" berpindah Nama -> Email -> Password
  final _namaFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  // State input non-teks
  String? _jenisKelamin;
  String? _programStudi;
  bool _setuju = false;
  bool _obscurePassword = true;

  // Menandai bahwa tombol Daftar sudah ditekan (untuk menampilkan error Radio/Dropdown)
  bool _sudahSubmit = false;

  final List<String> _daftarProdi = const [
    'Teknik Informatika',
    'Sistem Informasi',
    'Teknik Elektro',
    'Manajemen',
    'Akuntansi',
  ];

  @override
  void dispose() {
    _namaController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _namaFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  // ---------- Validator ----------
  String? _validateNama(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Nama tidak boleh kosong';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email tidak boleh kosong';
    }
    if (!value.contains('@')) {
      return 'Email harus mengandung "@"';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password tidak boleh kosong';
    }
    if (value.length < 6) {
      return 'Password minimal 6 karakter';
    }
    return null;
  }

  // ---------- Aksi tombol Daftar ----------
  void _onDaftar() {
    setState(() => _sudahSubmit = true);

    final formValid = _formKey.currentState!.validate();

    // Checkbox belum dicentang -> tampilkan SnackBar peringatan
    if (!_setuju) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Anda harus menyetujui Syarat & Ketentuan terlebih dahulu!'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      return;
    }

    // Validasi field teks + radio + dropdown
    if (!formValid || _jenisKelamin == null || _programStudi == null) {
      return;
    }

    _tampilkanDialogKonfirmasi();
  }

  void _tampilkanDialogKonfirmasi() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Konfirmasi Data'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _baris('Nama', _namaController.text.trim()),
              _baris('Email', _emailController.text.trim()),
              _baris('Password', '•' * _passwordController.text.length),
              _baris('Jenis Kelamin', _jenisKelamin!),
              _baris('Program Studi', _programStudi!),
              const SizedBox(height: 12),
              const Text('Apakah data di atas sudah benar?'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _submit();
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  Widget _baris(String label, String nilai) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          const Text(': '),
          Expanded(child: Text(nilai)),
        ],
      ),
    );
  }

  void _submit() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Registrasi berhasil!'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
    _resetForm();
  }

  void _resetForm() {
    _formKey.currentState!.reset();
    _namaController.clear();
    _emailController.clear();
    _passwordController.clear();
    setState(() {
      _jenisKelamin = null;
      _programStudi = null;
      _setuju = false;
      _sudahSubmit = false;
    });
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Form Registrasi')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Nama Lengkap
              TextFormField(
                controller: _namaController,
                focusNode: _namaFocus,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Nama Lengkap',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                validator: _validateNama,
                onFieldSubmitted: (_) =>
                    FocusScope.of(context).requestFocus(_emailFocus),
              ),
              const SizedBox(height: 16),

              // Email
              TextFormField(
                controller: _emailController,
                focusNode: _emailFocus,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
                validator: _validateEmail,
                onFieldSubmitted: (_) =>
                    FocusScope.of(context).requestFocus(_passwordFocus),
              ),
              const SizedBox(height: 16),

              // Password
              TextFormField(
                controller: _passwordController,
                focusNode: _passwordFocus,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword
                        ? Icons.visibility_off
                        : Icons.visibility),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                validator: _validatePassword,
                onFieldSubmitted: (_) => FocusScope.of(context).unfocus(),
              ),
              const SizedBox(height: 20),

              // Jenis Kelamin (Radio)
              const Text('Jenis Kelamin',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Row(
                children: [
                  _radioOption('Laki-laki'),
                  _radioOption('Perempuan'),
                ],
              ),
              if (_sudahSubmit && _jenisKelamin == null)
                _pesanError('Pilih jenis kelamin'),
              const SizedBox(height: 12),

              // Program Studi (DropdownButton)
              const Text('Program Studi',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: (_sudahSubmit && _programStudi == null)
                        ? Theme.of(context).colorScheme.error
                        : Colors.grey,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: DropdownButton<String>(
                  value: _programStudi,
                  isExpanded: true,
                  underline: const SizedBox(),
                  hint: const Text('Pilih program studi'),
                  items: _daftarProdi
                      .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                      .toList(),
                  onChanged: (value) => setState(() => _programStudi = value),
                ),
              ),
              if (_sudahSubmit && _programStudi == null)
                _pesanError('Pilih program studi'),
              const SizedBox(height: 12),

              // Checkbox Syarat & Ketentuan
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: const Text('Saya setuju dengan Syarat & Ketentuan'),
                value: _setuju,
                onChanged: (value) => setState(() => _setuju = value ?? false),
              ),
              const SizedBox(height: 16),

              // Tombol Daftar
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: _onDaftar,
                  child: const Text('Daftar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _radioOption(String value) {
    return Expanded(
      child: RadioListTile<String>(
        contentPadding: EdgeInsets.zero,
        title: Text(value),
        value: value,
        groupValue: _jenisKelamin,
        onChanged: (v) => setState(() => _jenisKelamin = v),
      ),
    );
  }

  Widget _pesanError(String pesan) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, left: 4),
      child: Text(
        pesan,
        style: TextStyle(
          color: Theme.of(context).colorScheme.error,
          fontSize: 12,
        ),
      ),
    );
  }
}
