import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class MaterialInputScreen extends StatefulWidget {
  const MaterialInputScreen({super.key});

  @override
  _MaterialInputScreenState createState() => _MaterialInputScreenState();
}

class _MaterialInputScreenState extends State<MaterialInputScreen> {
  final _formKey = GlobalKey<FormState>();
  String _selectedParameter = 'Plant';
  String _company = '';
  String _inputValue = '';
  late ApiService apiService;
  Map<String, dynamic>? _apiData;
  bool _isLoading = false;

  final List<String> _parameters = ['Plant', 'Material', 'Material Group', 'Str Loc'];

  @override
  void initState() {
    super.initState();
    apiService = ApiService('http://10.7.5.52:8084/AAPLSTORE');
    _loadCompany();
  }

  Future<void> _loadCompany() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _company = prefs.getString('company') ?? 'Unknown Company';
    });
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      if (_inputValue.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a value')),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        final data = await apiService.getData(
          company: _company,
          plant: _selectedParameter == 'Plant' ? _inputValue : '',
          mat: _selectedParameter == 'Material' ? _inputValue : '',
          matgrp: _selectedParameter == 'Material Group' ? _inputValue : '',
          strloc: _selectedParameter == 'Str Loc' ? _inputValue : '',
        );

        if ((data['Items'] as List<dynamic>?)?.isEmpty == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No results found')),
          );
        } else {
          setState(() {
            _apiData = data;
          });
        }
      } catch (e) {
        print('Error: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to fetch data from server')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildDropdown(String title, List<String> items, String value, void Function(String?)? onChanged) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: title,
        border: OutlineInputBorder(),
      ),
      value: value,
      onChanged: onChanged,
      items: items.map<DropdownMenuItem<String>>((String item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(item),
        );
      }).toList(),
    );
  }

  Widget _buildInputField() {
    return TextFormField(
      decoration: const InputDecoration(
        labelText: 'Enter Value',
        border: OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a value';
        }
        return null;
      },
      onSaved: (value) {
        _inputValue = value ?? '';
      },
    );
  }

  Widget _buildDataTable() {
    if (_apiData == null || _apiData!['Items'] == null) {
      return const Center(child: Text('No data available'));
    }

    final items = _apiData!['Items'] as List<dynamic>? ?? [];
    if (items.isEmpty) return const Center(child: Text('No data available'));

    final firstItem = items.first as Map<String, dynamic>;
    final columns = ['Serial No'] + firstItem.keys.toList();

    final rows = items.asMap().entries.map<DataRow>((entry) {
      final index = entry.key;
      final item = entry.value as Map<String, dynamic>;

      final cells = [index + 1].map<DataCell>((serialNumber) {
        return DataCell(Text(serialNumber.toString()));
      }).toList()
          + columns.sublist(1).map<DataCell>((column) {
            final value = item[column];
            return DataCell(Text(value?.toString() ?? 'NA'));
          }).toList();

      return DataRow(cells: cells);
    }).toList();

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(width: 2.0, color: Colors.blue[900]!),
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: DataTable(
            columnSpacing: 16.0,
            columns: columns.map<DataColumn>((column) {
              return DataColumn(
                label: Text(
                  column,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red[900],
                  ),
                ),
              );
            }).toList(),
            rows: rows,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const SizedBox.shrink(),
        title: Center(
          child: Image.asset(
            'assets/images/Atlas.png',
            width: 90.0,
            height: 90.0,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.yellow[700],
        foregroundColor: Colors.red[900],
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomRight: Radius.circular(15),
            bottomLeft: Radius.circular(15),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Welcome to $_company',
              style: TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
                color: Colors.red[900],
              ),
            ),
            const SizedBox(height: 20.0),
            Form(
              key: _formKey,
              child: Column(
                children: <Widget>[
                  _buildDropdown(
                    'Select Parameter',
                    _parameters,
                    _selectedParameter,
                        (newValue) {
                      setState(() {
                        _selectedParameter = newValue!;
                      });
                    },
                  ),
                  const SizedBox(height: 16.0),
                  _buildInputField(),
                ],
              ),
            ),
            const SizedBox(height: 10.0),
            ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.blue[900],
              ),
              child: const Text('Submit'),
            ),
            const SizedBox(height: 20.0),
            if (_isLoading)
              const CircularProgressIndicator()
            else if (_apiData != null)
              Container(
                height: MediaQuery.of(context).size.height * 0.7,
                child: _buildDataTable(),
              ),
          ],
        ),
      ),
    );
  }
}
