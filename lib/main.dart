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

SupabaseClient get supabase => Supabase.instance.client; // Use a getter instead of a final variable

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Registrar DB',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const MainNavigationPage(),
    );
  }
}

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const DataEntryPage(),
    const SearchPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Database for Searching Certificates in Books',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              'Divisional Secretariat Weligama',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: Column(
        children: [
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
                  labelType: NavigationRailLabelType.all,
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.add_box),
                      selectedIcon: Icon(Icons.add_box),
                      label: Text('Enter Data'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.search),
                      selectedIcon: Icon(Icons.search),
                      label: Text('Search'),
                    ),
                  ],
                ),
                const VerticalDivider(thickness: 1, width: 1),
                Expanded(
                  child: _pages[_selectedIndex],
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8.0),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Text(
              'Created by ICTA - T G N Thisara Divisional Secretariat Weligama',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
        ],
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
      debugPrint('Attempting insert...');
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

      debugPrint('Insert successful');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data saved successfully'),
            backgroundColor: Colors.green,
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
      debugPrint('Insert error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Data Entry (Sinhala Supported)',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _fullNameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name (සම්පූර්ණ නම)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                (value == null || value.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _divisionController,
                decoration: const InputDecoration(
                  labelText: 'Division (ප්‍රාදේශීය ලේකම් කාර්යාලය)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _selectedDate == null
                          ? 'Select Date of Birth (උපන් දිනය)'
                          : 'DOB: ${DateFormat('yyyy-MM-dd').format(_selectedDate!)}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _selectDate(context),
                    icon: const Icon(Icons.calendar_today),
                    label: const Text('Pick Date'),
                  ),
                  if (_selectedDate != null)
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _selectedDate = null),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _mothersNameController,
                decoration: const InputDecoration(
                  labelText: "Mother's Name (මවගේ නම)",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _bCertNoController,
                decoration: const InputDecoration(
                  labelText: 'Birth Certificate No (උප්පැන්න සහතික අංකය)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _bookNoController,
                decoration: const InputDecoration(
                  labelText: 'Book No (පොත් අංකය)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 30),
              Center(
                child: _isSaving
                    ? const CircularProgressIndicator()
                    : ElevatedButton.icon(
                  onPressed: _submitData,
                  icon: const Icon(Icons.save),
                  label: const Text('Save Data'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 50, vertical: 15),
                  ),
                ),
              ),
            ],
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
  final TextEditingController _divisionSearchController =
  TextEditingController();
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
        query =
            query.ilike('full_name', '%${_nameSearchController.text.trim()}%');
      }
      if (_divisionSearchController.text.trim().isNotEmpty) {
        query = query.ilike(
            'division', '%${_divisionSearchController.text.trim()}%');
      }
      if (_motherSearchController.text.trim().isNotEmpty) {
        query = query.ilike(
            'mothers_name', '%${_motherSearchController.text.trim()}%');
      }
      if (_dobSearch != null) {
        query =
            query.eq('DOB', DateFormat('yyyy-MM-dd').format(_dobSearch!));
      }

      final response = await query;
      debugPrint('Search results: ${response.length} rows');

      setState(() {
        _searchResults = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      debugPrint('Search error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error searching: $e'),
            backgroundColor: Colors.red,
          ),
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
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this record?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await supabase.from('filedata').delete().eq('id', id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Record deleted')),
          );
          _search(); // Refresh results
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // ── Search Filters ──
          ExpansionTile(
            title: const Text('Search Filters'),
            initiallyExpanded: true,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _nameSearchController,
                      decoration: const InputDecoration(
                        labelText: 'Name (නම)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _divisionSearchController,
                      decoration: const InputDecoration(
                        labelText: 'Division (ප්‍රාදේශීය)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_on),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _motherSearchController,
                      decoration: const InputDecoration(
                        labelText: "Mother's Name (මවගේ නම)",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _dobSearch == null
                                ? 'Date of Birth (උපන් දිනය)'
                                : 'DOB: ${DateFormat('yyyy-MM-dd').format(_dobSearch!)}',
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.calendar_today),
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(1900),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null) {
                              setState(() => _dobSearch = picked);
                            }
                          },
                        ),
                        if (_dobSearch != null)
                          IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () =>
                                setState(() => _dobSearch = null),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _search,
                          icon: const Icon(Icons.search),
                          label: const Text('Search'),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          onPressed: _clearFilters,
                          icon: const Icon(Icons.clear_all),
                          label: const Text('Clear'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Results ──
          if (_isLoading)
            const Expanded(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (!_hasSearched)
            const Expanded(
              child: Center(
                child: Text('Use the filters above to search records.'),
              ),
            )
          else if (_searchResults.isEmpty)
              const Expanded(
                child: Center(child: Text('No records found.')),
              )
            else
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_searchResults.length} record(s) found',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SingleChildScrollView(
                          child: DataTable(
                            headingRowColor: WidgetStateProperty.all(
                              Theme.of(context)
                                  .colorScheme
                                  .primaryContainer,
                            ),
                            columns: const [
                              DataColumn(label: Text('Full Name')),
                              DataColumn(label: Text('DOB')),
                              DataColumn(label: Text('Division')),
                              DataColumn(label: Text("Mother's Name")),
                              DataColumn(label: Text('B-Cert No')),
                              DataColumn(label: Text('Book No')),
                              DataColumn(label: Text('Actions')),
                            ],
                            rows: _searchResults.map((data) {
                              return DataRow(cells: [
                                DataCell(Text(data['full_name'] ?? '')),
                                DataCell(Text(data['DOB'] != null
                                    ? DateFormat('yyyy-MM-dd').format(
                                    DateTime.parse(data['DOB']))
                                    : '')),
                                DataCell(Text(data['division'] ?? '')),
                                DataCell(Text(data['mothers_name'] ?? '')),
                                DataCell(Text(data['B_cert_no'] ?? '')),
                                DataCell(Text(data['book_no'] ?? '')),
                                DataCell(
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _deleteRecord(data['id']),
                                  ),
                                ),
                              ]);
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}