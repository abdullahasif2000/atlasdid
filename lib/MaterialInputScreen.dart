import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
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


  final TextEditingController _inputController = TextEditingController();

  final List<String> _parameters = ['Plant', 'Material', 'Material Group', 'Str Loc'];

  @override
  void initState() {
    super.initState();
    apiService = ApiService('https://api.aipportals.com//AAPLSTORE');
    _loadCompany();
  }

  Future<void> _loadCompany() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _company = prefs.getString('company') ?? 'Unknown Company';
    });
  }

  Future<void> _scanQR() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => Scaffold(
        appBar: AppBar(
          title: const Text('Scan QR Code'),
        ),
        body: MobileScanner(
          onDetect: (barcodeCapture) {
            final barcode = barcodeCapture.barcodes.first;
            if (barcode.rawValue != null) {
              Navigator.pop(context, barcode.rawValue);
            }
          },
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _inputValue = result;
        _inputController.text = result;
      });
    }
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

      // Ensure the input value has the correct length
      if (_selectedParameter == 'Material' && _inputValue.length > 10) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter up to 10 digits only')),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      String fullMaterialNumber = _inputValue;

      // Prepend leading zeros only if the selected parameter is 'Material'
      if (_selectedParameter == 'Material') {
        fullMaterialNumber = '00000000' + _inputValue;
      }

      try {
        final data = await apiService.getData(
          company: _company,
          plant: _selectedParameter == 'Plant' ? fullMaterialNumber : '',
          mat: _selectedParameter == 'Material' ? fullMaterialNumber : '',
          matgrp: _selectedParameter == 'Material Group' ? fullMaterialNumber : '',
          strloc: _selectedParameter == 'Str Loc' ? fullMaterialNumber : '',
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
      controller: _inputController,
      decoration: InputDecoration(
        labelText: 'Enter Value ',
        border: const OutlineInputBorder(),
        suffixIcon: _selectedParameter == 'Material'
            ? IconButton(
          icon: const Icon(Icons.qr_code),
          onPressed: _scanQR,
        )
            : null,
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
        DataCell( Center(child: Text((index + 1).toString()))),
        DataCell(Text(getCellValue('Material'))),
        DataCell(Center(child: Text(getCellValue('Desc')))),
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
        child: Align(
          alignment: Alignment.centerLeft,
          child: SizedBox(
            width: 2200, // width of content
            child: DataTable2(
              columnSpacing: 2.0,
              horizontalMargin: 1.0,
              minWidth: 1600,
              headingRowColor: WidgetStateProperty.all(Colors.blue[900]),
              headingRowHeight: 55.0,
              fixedTopRows: 1,
              columns: columns.map<DataColumn>((column) {
                return DataColumn(
                  label: Center(
                    child: Container(
                      padding: const EdgeInsets.all(8.0),
                      child: Center(
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
            margin: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 6.0),
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black, width: 2.0),
              borderRadius: BorderRadius.circular(12.0),
              color: Colors.yellow[700],
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('Material:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                        Text('Desc:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                        Text('Plant:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                        Text('Strloc:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 8,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item['Material'] ?? 'N/A', style: const TextStyle(color: Colors.black)),
                        Text(item['Desc'] ?? 'N/A', style: const TextStyle(color: Colors.black)),
                        Text(item['Plant'] ?? 'N/A', style: const TextStyle(color: Colors.black)),
                        Text(item['Strloc'] ?? 'N/A', style: const TextStyle(color: Colors.black)),
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