import 'package:flutter/material.dart';
import 'api_service.dart'; // Ensure this imports your ApiService class

class MaterialInputScreen extends StatefulWidget {
  @override
  _MaterialInputScreenState createState() => _MaterialInputScreenState();
}

class _MaterialInputScreenState extends State<MaterialInputScreen> {
  final _formKey = GlobalKey<FormState>();
  String _selectedParameter = 'Plant';
  String _inputValue = '';
  late ApiService apiService;
  Map<String, dynamic>? _apiData;
  bool _isLoading = false;

  final List<String> _parameters = ['Plant', 'Material', 'Material Group', 'Str Loc'];

  @override
  void initState() {
    super.initState();
    apiService = ApiService('http://10.7.5.52:8084/AAPLSTORE');
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      if (_inputValue.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please enter a value')),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        final data = await apiService.getData(
          plant: _selectedParameter == 'Plant' ? _inputValue : '',
          mat: _selectedParameter == 'Material' ? _inputValue : '',
          matgrp: _selectedParameter == 'Material Group' ? _inputValue : '',
          strloc: _selectedParameter == 'Str Loc' ? _inputValue : '',
        );

        if (data == null || (data['Items'] as List<dynamic>?)?.isEmpty == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No results found')),
          );
        } else {
          setState(() {
            _apiData = data;
          });
        }
      } catch (e) {
        print('Error: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to fetch data from server')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedParameter,
      onChanged: (String? newValue) {
        setState(() {
          _selectedParameter = newValue!;
        });
      },
      items: _parameters.map<DropdownMenuItem<String>>((String parameter) {
        return DropdownMenuItem<String>(
          value: parameter,
          child: Text(parameter),
        );
      }).toList(),
      decoration: InputDecoration(
        labelText: 'Select Parameter',
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _buildInputField() {
    return TextFormField(
      decoration: InputDecoration(
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
      return Center(child: Text('No data available'));
    }

    final items = _apiData!['Items'] as List<dynamic>? ?? [];
    if (items.isEmpty) return Center(child: Text('No data available'));

    final firstItem = items.first as Map<String, dynamic>;
    final columns = ['Serial No'] + firstItem.keys.toList();

    final rows = items.asMap().entries.map<DataRow>((entry) {
      final index = entry.key; // Serial number
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
        leading: SizedBox.shrink(),
        title: Center(
          child: Image.asset(
            'assets/images/Atlas.png',
            width: 100.0,
            height: 100.0,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.yellow[700],
        foregroundColor: Colors.red[900],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomRight: Radius.circular(20),
            bottomLeft: Radius.circular(20),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Form(
              key: _formKey,
              child: Column(
                children: <Widget>[
                  _buildDropdown(),
                  SizedBox(height: 16.0),
                  _buildInputField(),
                ],
              ),
            ),
            SizedBox(height: 10.0),
            ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.blue[900],
              ),
              child: Text('Submit'),
            ),
            SizedBox(height: 20.0),
            if (_isLoading)
              CircularProgressIndicator()
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
