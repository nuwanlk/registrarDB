import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const String supabaseUrl = 'https://putrfpmhdrnhotmelbwz.supabase.co';
  const String supabaseKey = 'sb_publishable_MjUXbM6GgMpIyVEXkk6EzA_mPc1fuOC';

  await Supabase.initialize(
    url: supabaseUrl,
    publishableKey: supabaseKey,
  );

  runApp(const MyApp());
}

SupabaseClient get supabase => Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Registrar DB',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0056b3),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[50],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF0056b3), width: 2),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      home: const LoginPage(),
    );
  }
}

// ─── LOGIN PAGE ───────────────────────────────────────────────────────────────

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  Future<void> _login() async {
    setState(() => _isLoading = true);
    try {
      // 1. Try to find the user in Supabase
      final response = await supabase
          .from('login')
          .select()
          .eq('username', _usernameController.text.trim())
          .eq('password', _passwordController.text)
          .maybeSingle();

      if (response != null) {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => MainNavigationPage(
                username: response['username'],
              ),
            ),
          );
        }
      } else {
        // 2. Fallback: Check if the login table is empty and credentials are default
        final List<dynamic> anyUsers = await supabase.from('login').select('username').limit(1);
        
        if (anyUsers.isEmpty && 
            _usernameController.text == 'Admin' && 
            _passwordController.text == 'admin') {
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => const MainNavigationPage(username: 'Admin'),
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Invalid username or password'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(32),
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock_person, size: 64, color: Color(0xFF0056b3)),
                  const SizedBox(height: 24),
                  const Text(
                    'Registrar DB Login',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      prefixIcon: Icon(Icons.person),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.key),
                      suffixIcon: IconButton(
                        icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off),
                        onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                      ),
                    ),
                    onSubmitted: (_) => _login(),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton(
                            onPressed: _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0056b3),
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Login', style: TextStyle(fontSize: 16)),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── MAIN NAVIGATION PAGE ─────────────────────────────────────────────────────

class MainNavigationPage extends StatefulWidget {
  final String username;
  const MainNavigationPage({super.key, required this.username});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _selectedIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const DataEntryPage(),
      const SearchPage(),
      ChangePasswordPage(currentUsername: widget.username),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(25),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.account_balance, color: Colors.white, size: 32),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Database for Searching Certificates in Books',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Divisional Secretariat Weligama',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.logout, color: Colors.white),
                  tooltip: 'Logout',
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (context) => const LoginPage()),
                    );
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                NavigationRail(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: (int index) {
                    setState(() {
                      _selectedIndex = index;
                    });
                  },
                  backgroundColor: Colors.grey[100],
                  labelType: NavigationRailLabelType.all,
                  selectedIconTheme: const IconThemeData(size: 30),
                  unselectedIconTheme: const IconThemeData(size: 24),
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.add_circle_outline),
                      selectedIcon: Icon(Icons.add_circle),
                      label: Text('Enter Data'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.search_outlined),
                      selectedIcon: Icon(Icons.search),
                      label: Text('Search'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.settings_outlined),
                      selectedIcon: Icon(Icons.settings),
                      label: Text('Settings'),
                    ),
                  ],
                ),
                const VerticalDivider(thickness: 1, width: 1),
                Expanded(
                  child: Container(
                    color: Colors.white,
                    child: _pages[_selectedIndex],
                  ),
                ),
              ],
            ),
          ),
          // Footer
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              border: Border(top: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Text(
              'Created by ICTA - T G N Thisara | Divisional Secretariat Weligama',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── CHANGE PASSWORD PAGE ─────────────────────────────────────────────────────

class ChangePasswordPage extends StatefulWidget {
  final String currentUsername;
  const ChangePasswordPage({super.key, required this.currentUsername});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _usernameController.text = widget.currentUsername;
  }

  Future<void> _updatePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isUpdating = true);

    try {
      // 1. Verify current password first
      final verifyResponse = await supabase
          .from('login')
          .select()
          .eq('username', widget.currentUsername)
          .eq('password', _currentPasswordController.text)
          .maybeSingle();

      if (verifyResponse == null) {
        // Check if we are in the "First Run" scenario (Empty table + Admin/admin)
        final anyUsers = await supabase.from('login').select('username').limit(1);
        
        if (anyUsers.isEmpty && 
            widget.currentUsername == 'Admin' && 
            _currentPasswordController.text == 'admin') {
          // It's the first run, we need to INSERT instead of UPDATE
          await supabase.from('login').insert({
            'username': _usernameController.text.trim(),
            'password': _newPasswordController.text,
          });
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Current password is incorrect'), backgroundColor: Colors.red),
            );
          }
          return;
        }
      } else {
        // Standard update
        await supabase.from('login').update({
          'username': _usernameController.text.trim(),
          'password': _newPasswordController.text,
        }).eq('username', widget.currentUsername);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Credentials updated successfully'), backgroundColor: Colors.green),
        );
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Update error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Settings', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    const Divider(height: 32),
                    TextFormField(
                      controller: _usernameController,
                      decoration: const InputDecoration(labelText: 'Username', prefixIcon: Icon(Icons.person_outline)),
                      validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _currentPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Current Password', prefixIcon: Icon(Icons.lock_outline)),
                      validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _newPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'New Password', prefixIcon: Icon(Icons.lock_reset)),
                      validator: (v) => (v == null || v.length < 4) ? 'Password must be at least 4 characters' : null,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Confirm New Password', prefixIcon: Icon(Icons.lock_reset)),
                      validator: (v) {
                        if (v != _newPasswordController.text) return 'Passwords do not match';
                        return null;
                      },
                    ),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      child: _isUpdating
                          ? const Center(child: CircularProgressIndicator())
                          : ElevatedButton.icon(
                              onPressed: _updatePassword,
                              icon: const Icon(Icons.save),
                              label: const Text('Update Credentials'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0056b3),
                                foregroundColor: Colors.white,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── DATA ENTRY PAGE ──────────────────────────────────────────────────────────

class DataEntryPage extends StatefulWidget {
  const DataEntryPage({super.key});

  @override
  State<DataEntryPage> createState() => _DataEntryPageState();
}

class _DataEntryPageState extends State<DataEntryPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _divisionController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _mothersNameController = TextEditingController();
  final TextEditingController _bCertNoController = TextEditingController();
  final TextEditingController _bookNoController = TextEditingController();
  DateTime? _selectedDate;
  bool _isSaving = false;

  @override
  void dispose() {
    _divisionController.dispose();
    _fullNameController.dispose();
    _mothersNameController.dispose();
    _bCertNoController.dispose();
    _bookNoController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _submitData() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      await supabase.from('filedata').insert({
        'division': _divisionController.text.trim(),
        'DOB': _selectedDate != null
            ? DateFormat('yyyy-MM-dd').format(_selectedDate!)
            : null,
        'full_name': _fullNameController.text.trim(),
        'mothers_name': _mothersNameController.text.trim(),
        'B_cert_no': _bCertNoController.text.trim(),
        'book_no': _bookNoController.text.trim(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Data saved successfully'),
              ],
            ),
            backgroundColor: Colors.green[700],
            behavior: SnackBarBehavior.floating,
          ),
        );
        _formKey.currentState!.reset();
        _divisionController.clear();
        _fullNameController.clear();
        _mothersNameController.clear();
        _bCertNoController.clear();
        _bookNoController.clear();
        setState(() => _selectedDate = null);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red[700],
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.edit_note, color: Theme.of(context).primaryColor, size: 28),
                        const SizedBox(width: 12),
                        Text(
                          'New Record Entry',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 32),
                    TextFormField(
                      controller: _fullNameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name (සම්පූර්ණ නම)',
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (value) =>
                          (value == null || value.trim().isEmpty) ? 'Name is required' : null,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _divisionController,
                      decoration: const InputDecoration(
                        labelText: 'Division (කොට්ඨාසය)',
                        prefixIcon: Icon(Icons.business),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today, size: 20, color: Colors.grey),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _selectedDate == null
                                        ? 'Date of Birth (උපන් දිනය)'
                                        : 'DOB: ${DateFormat('yyyy-MM-dd').format(_selectedDate!)}',
                                    style: TextStyle(
                                      color: _selectedDate == null ? Colors.grey[600] : Colors.black87,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          onPressed: () => _selectDate(context),
                          icon: const Icon(Icons.event),
                          label: const Text('Pick Date'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        if (_selectedDate != null)
                          IconButton(
                            icon: const Icon(Icons.clear, color: Colors.red),
                            onPressed: () => setState(() => _selectedDate = null),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _mothersNameController,
                      decoration: const InputDecoration(
                        labelText: "Mother's Name (මවගේ නම)",
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _bCertNoController,
                            decoration: const InputDecoration(
                              labelText: 'Birth Certificate No',
                              hintText: 'උප්පැන්න සහතික අංකය',
                              prefixIcon: Icon(Icons.description),
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: TextFormField(
                            controller: _bookNoController,
                            decoration: const InputDecoration(
                              labelText: 'Book No (පොත් අංකය)',
                              prefixIcon: Icon(Icons.menu_book),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      child: _isSaving
                          ? const Center(child: CircularProgressIndicator())
                          : ElevatedButton.icon(
                              onPressed: _submitData,
                              icon: const Icon(Icons.save),
                              label: const Text(
                                'Save Record',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).primaryColor,
                                foregroundColor: Colors.white,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── SEARCH PAGE ──────────────────────────────────────────────────────────────

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _nameSearchController = TextEditingController();
  final TextEditingController _divisionSearchController = TextEditingController();
  final TextEditingController _motherSearchController = TextEditingController();
  DateTime? _dobSearch;
  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = false;
  bool _hasSearched = false;

  @override
  void dispose() {
    _nameSearchController.dispose();
    _divisionSearchController.dispose();
    _motherSearchController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    try {
      var query = supabase.from('filedata').select();

      if (_nameSearchController.text.trim().isNotEmpty) {
        query = query.ilike('full_name', '%${_nameSearchController.text.trim()}%');
      }
      if (_divisionSearchController.text.trim().isNotEmpty) {
        query = query.ilike('division', '%${_divisionSearchController.text.trim()}%');
      }
      if (_motherSearchController.text.trim().isNotEmpty) {
        query = query.ilike('mothers_name', '%${_motherSearchController.text.trim()}%');
      }
      if (_dobSearch != null) {
        query = query.eq('DOB', DateFormat('yyyy-MM-dd').format(_dobSearch!));
      }

      final response = await query.order('full_name', ascending: true);
      setState(() {
        _searchResults = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Search error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _clearFilters() {
    _nameSearchController.clear();
    _divisionSearchController.clear();
    _motherSearchController.clear();
    setState(() {
      _dobSearch = null;
      _searchResults = [];
      _hasSearched = false;
    });
  }

  Future<void> _deleteRecord(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Record?'),
        content: const Text('This action cannot be undone. Are you sure?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await supabase.from('filedata').delete().eq('id', id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Record deleted')));
          _search();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete error: $e'), backgroundColor: Colors.red));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Search Filters', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _nameSearchController,
                          decoration: const InputDecoration(labelText: 'Name', prefixIcon: Icon(Icons.person_search)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: _divisionSearchController,
                          decoration: const InputDecoration(labelText: 'Division', prefixIcon: Icon(Icons.location_on)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _motherSearchController,
                          decoration: const InputDecoration(labelText: "Mother's Name", prefixIcon: Icon(Icons.face)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(1900),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null) setState(() => _dobSearch = picked);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_month, color: Colors.grey, size: 20),
                                const SizedBox(width: 12),
                                Text(_dobSearch == null ? 'Date of Birth' : DateFormat('yyyy-MM-dd').format(_dobSearch!)),
                                const Spacer(),
                                if (_dobSearch != null)
                                  IconButton(
                                    icon: const Icon(Icons.close, size: 16),
                                    onPressed: () => setState(() => _dobSearch = null),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _clearFilters,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reset'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: _search,
                        icon: const Icon(Icons.search),
                        label: const Text('Search'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          if (_isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (!_hasSearched)
            const Expanded(child: Center(child: Text('Enter criteria and search for records')))
          else if (_searchResults.isEmpty)
            const Expanded(child: Center(child: Text('No matching records found')))
          else
            Expanded(
              child: Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text('${_searchResults.length} Records Found', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Table(
                          columnWidths: const {
                            0: FlexColumnWidth(3),
                            1: FlexColumnWidth(2),
                            2: FlexColumnWidth(2),
                            3: FlexColumnWidth(2),
                            4: FlexColumnWidth(2),
                            5: FixedColumnWidth(60),
                          },
                          children: [
                            TableRow(
                              decoration: BoxDecoration(color: Colors.grey[100]),
                              children: const [
                                Padding(padding: EdgeInsets.all(12), child: Text('Full Name', style: TextStyle(fontWeight: FontWeight.bold))),
                                Padding(padding: EdgeInsets.all(12), child: Text('DOB', style: TextStyle(fontWeight: FontWeight.bold))),
                                Padding(padding: EdgeInsets.all(12), child: Text('Division', style: TextStyle(fontWeight: FontWeight.bold))),
                                Padding(padding: EdgeInsets.all(12), child: Text('Mother', style: TextStyle(fontWeight: FontWeight.bold))),
                                Padding(padding: EdgeInsets.all(12), child: Text('B-Cert / Book', style: TextStyle(fontWeight: FontWeight.bold))),
                                Padding(padding: EdgeInsets.all(12), child: Text('', style: TextStyle(fontWeight: FontWeight.bold))),
                              ],
                            ),
                            ..._searchResults.map((data) => TableRow(
                              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE)))),
                              children: [
                                Padding(padding: const EdgeInsets.all(12), child: Text(data['full_name'] ?? '-')),
                                Padding(padding: const EdgeInsets.all(12), child: Text(data['DOB'] ?? '-')),
                                Padding(padding: const EdgeInsets.all(12), child: Text(data['division'] ?? '-')),
                                Padding(padding: const EdgeInsets.all(12), child: Text(data['mothers_name'] ?? '-')),
                                Padding(padding: const EdgeInsets.all(12), child: Text('${data['B_cert_no'] ?? ''} / ${data['book_no'] ?? ''}')),
                                Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                    onPressed: () => _deleteRecord(data['id']),
                                  ),
                                ),
                              ],
                            )),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
