import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'login_screen.dart';

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

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();


    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
    );
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

      String getCellValue(String key) {
        return item[key]?.toString().isNotEmpty == true ? item[key]! : 'N/A';
      }

      final cells = [
        DataCell(Center(child: Text((index + 1).toString()))),
        DataCell(Text(getCellValue('Material'))),
        DataCell(Text(getCellValue('Desc'))),
        DataCell(Center(child: Text(getCellValue('Plant')))),
        DataCell(Center(child: Text(getCellValue('Strloc')))),
        DataCell(Center(child: Text(getCellValue('StrlocDesc')))),
        DataCell(Center(child: Text(getCellValue('Unrestricted')))),
        DataCell(Center(child: Text(getCellValue('QualityInspection')))),
        DataCell(Center(child: Text(getCellValue('Blocked')))),
        DataCell(Center(child: Text(getCellValue('ReturnBlock')))),
        DataCell(Center(child: Text(getCellValue('VendorCode')))),
        DataCell(Center(child: Text(getCellValue('VendorName')))),
        DataCell(Center(child: Text(getCellValue('AtVendor')))),
        DataCell(Center(child: Text(getCellValue('StockInTransfer')))),
      ];

      return DataRow(cells: cells);
    }).toList();

    return Expanded(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          child: DataTable(
            columnSpacing: 20.0,
            headingRowColor: WidgetStateProperty.all(Colors.blue[900]),
            columns: columns.map<DataColumn>((column) {
              return DataColumn(
                label: Center(
                  child: Container(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      column,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
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
                  Container(
                    width: 1.0,
                    color: Colors.black,
                    margin: const EdgeInsets.symmetric(horizontal: 16.0),
                  ),
                  Expanded(
                    flex: 5,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item['Material'] ?? 'N/A'),
                        Text(item['Desc'] ?? 'N/A'),
                        Text(item['Plant'] ?? 'N/A'),
                        Text(item['Strloc'] ?? 'N/A'),
                        Text(item['StrlocDesc'] ?? 'N/A'),
                        Text(item['Unrestricted'] ?? 'N/A'),
                        Text(item['QualityInspection'] ?? 'N/A'),
                        Text(item['Blocked'] ?? 'N/A'),
                        Text(item['ReturnBlock'] ?? 'N/A'),
                        Text(item['VendorCode'] ?? 'N/A'),
                        Text(item['VendorName'] ?? 'N/A'),
                        Text(item['AtVendor'] ?? 'N/A'),
                        Text(item['StockInTransfer'] ?? 'N/A'),
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
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
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
                      backgroundColor: Colors.blue[900],
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
