import 'package:flutter/foundation.dart';
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

      FocusScope.of(context).unfocus();

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
        if (kDebugMode) {
          print('Error: $e');
        }
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
        border: const OutlineInputBorder(),
      ),
      value: value,
      onChanged: (newValue) {
        setState(() {
          _selectedParameter = newValue!;
          _apiData = null;
        });
      },
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

    // Change to column layout if parameter is 'Material'
    if (_selectedParameter == 'Material') {
      return _buildColumnLayout(items);
    }

    final columns = [
      'S NO.', 'Material', 'Desc', 'Plant', 'Strloc', 'StrlocDesc',
      'Unrestricted', 'QualityInspection', 'Blocked', 'ReturnBlock',
      'VendorCode', 'VendorName', 'AtVendor', 'StockInTransfer'
    ];

    final rows = items.asMap().entries.map<DataRow>((entry) {
      final index = entry.key;
      final item = entry.value as Map<String, dynamic>;

      final cells = [
        DataCell(Center(child: Text((index + 1).toString()))),
        DataCell(Center(child: Text(
            int.tryParse(item['Material'] ?? '0')?.toString() ?? 'N/A'
        )
        )
        ),
        DataCell(Center(child: Text(item['Desc']?.toString().isNotEmpty == true ? item['Desc']! : 'NA'))),
        DataCell(Center(child: Text(item['Plant']?.toString().isNotEmpty == true ? item['Plant']! : 'NA'))),
        DataCell(Center(child: Text(item['Strloc']?.toString().isNotEmpty == true ? item['Strloc']! : 'NA'))),
        DataCell(Center(child: Text(item['StrlocDesc']?.toString().isNotEmpty == true ? item['StrlocDesc']! : 'NA'))),
        DataCell(Center(child: Text(item['Unrestricted']?.toString().isNotEmpty == true ? item['Unrestricted']! : 'NA'))),
        DataCell(Center(child: Text(item['QualityInspection']?.toString().isNotEmpty == true ? item['QualityInspection']! : 'NA'))),
        DataCell(Center(child: Text(item['Blocked']?.toString().isNotEmpty == true ? item['Blocked']! : 'NA'))),
        DataCell(Center(child: Text(item['ReturnBlock']?.toString().isNotEmpty == true ? item['ReturnBlock']! : 'NA'))),
        DataCell(Center(child: Text(item['VendorCode']?.toString().isNotEmpty == true ? item['VendorCode']! : 'NA'))),
        DataCell(Center(child: Text(item['VendorName']?.toString().isNotEmpty == true ? item['VendorName']! : 'NA'))),
        DataCell(Center(child: Text(item['AtVendor']?.toString().isNotEmpty == true ? item['AtVendor']! : 'NA'))),
        DataCell(Center(child: Text(item['StockInTransfer']?.toString().isNotEmpty == true ? item['StockInTransfer']! : 'NA'))),
      ];

      return DataRow(cells: cells);
    }).toList();

    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.blue, width: 1.0),
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SingleChildScrollView(
            child: DataTable(
              columnSpacing: 16.0,
              columns: columns.map<DataColumn>((column) {
                return DataColumn(
                  label: SizedBox(
                    width: 100,
                    child: Center(
                      child: Text(
                        column,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.yellow,
                        ),
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                      ),
                    ),
                  ),
                );
              }).toList(),
              rows: rows,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildColumnLayout(List<dynamic> items) {
    return Expanded(
      child: ListView.builder(
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index] as Map<String, dynamic>;

          return Container(
            margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.blue, width: 1.0),
              borderRadius: BorderRadius.circular(12.0),
              color: Colors.yellow[700],
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Left side: Headers
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('Material:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                        Text('Description:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                        Text('Plant:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                        Text('Storage Location:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                        Text('Storage Location Desc:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                        Text('Unrestricted:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                        Text('Quality Inspection:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                        Text('Blocked:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                        Text('Return Block:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                        Text('Vendor Code:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                        Text('Vendor Name:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                        Text('At Vendor:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                        Text('Stock in Transfer:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                      ],
                    ),
                  ),
                  // Middle: Vertical divider
                  Container(
                    width: 1.0,
                    color: Colors.black,
                    margin: const EdgeInsets.symmetric(horizontal: 16.0),
                  ),
                  // Right side: Values
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDataCell(item['Material']),
                        _buildDataCell(item['Desc']),
                        _buildDataCell(item['Plant']),
                        _buildDataCell(item['Strloc']),
                        _buildDataCell(item['StrlocDesc']),
                        _buildDataCell(item['Unrestricted']),
                        _buildDataCell(item['QualityInspection']),
                        _buildDataCell(item['Blocked']),
                        _buildDataCell(item['ReturnBlock']),
                        _buildDataCell(item['VendorCode']),
                        _buildDataCell(item['VendorName']),
                        _buildDataCell(item['AtVendor']),
                        _buildDataCell(item['StockInTransfer']),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDataCell(dynamic value) {
    return GestureDetector(
      onTap: () {
        if (value != null && value.toString().isNotEmpty) {
          _showFullTextDialog(value.toString());
        }
      },
      child: Tooltip(
        message: value?.toString() ?? 'NA',
        child: Text(
          value?.toString().isNotEmpty == true ? value.toString() : 'N/A',
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
          style: TextStyle(color: Colors.black),
        ),
      ),
    );
  }

  void _showFullTextDialog(String fullText) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          // title: Text('Full Text'),
          content: Text(fullText),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }




  @override

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Welcome to $_company',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.red[900],
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
      body: Column(
        children: [
          const SizedBox(height: 20.0),
          Form(
            key: _formKey,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: <Widget>[
                  _buildDropdown(
                    'Select Parameter',
                    _parameters,
                    _selectedParameter,
                        (newValue) {
                      setState(() {
                        _selectedParameter = newValue!;
                        _apiData = null;
                      });
                    },
                  ),
                  const SizedBox(height: 16.0),
                  _buildInputField(),
                  const SizedBox(height: 10.0),
                  ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Submit'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16.0),
          if (_isLoading)
            const CircularProgressIndicator()
          else
            _buildDataTable(),
        ],
      ),
    );
  }
}