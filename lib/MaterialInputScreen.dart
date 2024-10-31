import 'dart:isolate';
import 'dart:async';
import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'api_service.dart';
import 'login_screen.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';

class PdfGenerator {
  static Future<void> generatePdfInIsolate(SendPort sendPort, List<Map<String, dynamic>> items) async {
    final pdf = pw.Document();

    // Building Pdf content
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            children: [
              for (var item in items)
                pw.Text("Material: ${item['Material']}, Desc: ${item['Desc']}, Plant: ${item['Plant']}"),

            ],
          );
        },
      ),
    );

    // Send Pdf data back the main thread
    final pdfData = await pdf.save();
    sendPort.send(pdfData);
  }
}


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
  String _strLocFilter = '';
  String _currentDateTime = '';


  final TextEditingController _inputController = TextEditingController();

  final List<String> _parameters = [
    'Plant',
    'Material',
    'Material Group',
    'Str Loc'
  ];
  final List<String> _plants = ['KHI', 'SKP', 'MDP', 'EKHI', 'DKHI', 'GKHI'];

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
      builder: (context) =>
          Scaffold(
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
        fullMaterialNumber = '00000000$_inputValue';
      }

      try {
        final data = await apiService.getData(
          company: _company,
          plant: _selectedParameter == 'Plant' ? fullMaterialNumber : '',
          mat: _selectedParameter == 'Material' ? fullMaterialNumber : '',
          matgrp: _selectedParameter == 'Material Group'
              ? fullMaterialNumber
              : '',
          strloc: _selectedParameter == 'Str Loc' ? fullMaterialNumber : '',
        );

        if ((data['Items'] as List<dynamic>?)?.isEmpty == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No results found')),
          );
        } else {
          setState(() {
            _currentDateTime = DateTime.now().toString();
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


  Future<void> _generatePdf() async {
    if (_apiData == null || _apiData!['Items'] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No data available to generate PDF')),
      );
      return;
    }

    final items = _apiData!['Items'] as List<dynamic>? ?? [];
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No data available to generate PDF')),
      );
      return;
    }

    // Show a loading indicator
    setState(() {
      _isLoading = true; //  loading state
    });

    //  ReceivePort to receive the PDF data
    final receivePort = ReceivePort();

    // Spawn an isolate to generate the PDF
    await Isolate.spawn((List<dynamic> params) async {
      final SendPort sendPort = params[0];
      final List<dynamic> items = params[1];

      final pdf = pw.Document();
      final String currentDateTime = DateTime.now().toString(); // Get the current date and time

      // Add content to the PDF using MultiPage to handle large tables
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          build: (pw.Context context) {
            return [
              pw.Text(
                'Stock Data Report',
                style: pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                'Generated on: $currentDateTime',
                style: const pw.TextStyle(
                  fontSize: 12,
                  color: PdfColors.grey,
                ),
              ),

              pw.SizedBox(height: 20),
              pw.TableHelper.fromTextArray(
                headers: const [
                  'Material', 'Desc', 'Plant', 'Strloc', 'Unrestricted', 'StrlocDesc',
                  'Material Group', 'Quality Inspection', 'Blocked', 'StockInTransfer',
                ],
                data: items.map((item) {
                  return [
                    item['Material'] ?? 'N/A',
                    item['Desc'] ?? 'N/A',
                    item['Plant'] ?? 'N/A',
                    item['Strloc'] ?? 'N/A',
                    item['Unrestricted'] ?? 'N/A',
                    item['StrlocDesc'] ?? 'N/A',
                    item['Material Group'] ?? 'N/A',
                    item['QualityInspection'] ?? 'N/A',
                    item['Blocked'] ?? 'N/A',
                    item['StockInTransfer'] ?? 'N/A',
                  ];
                }).toList(),
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.blue900,
                ),
                cellAlignment: pw.Alignment.centerLeft,
                cellHeight: 35,
                cellStyle: const pw.TextStyle(fontSize: 10),
              ),
            ];
          },
        ),
      );

      // Send the generated PDF data back to the main thread
      sendPort.send(await pdf.save());
    }, [receivePort.sendPort, items]);

    // Get the generated PDF data
    final pdfData = await receivePort.first as List<int>;

    // Handle file saving and sharing
    try {
      var status = await Permission.storage.status;
      if (!status.isGranted) {
        status = await Permission.storage.request();
        if (!status.isGranted) {
          throw Exception("Storage permission not granted");
        }
      }

      // Get the Downloads directory
      final List<Directory>? downloadsDirectory = await getExternalStorageDirectories(
        type: StorageDirectory.downloads,
      );

      if (downloadsDirectory == null || downloadsDirectory.isEmpty) {
        throw Exception("Unable to find downloads directory");
      }

      // Save the PDF file to the Downloads folder
      final file = File('${downloadsDirectory.first.path}/material_data_report.pdf');
      await file.writeAsBytes(pdfData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PDF saved to Downloads folder')),
      );

      // File sharing
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Material Data Report PDF',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating PDF: $e')),
      );
    } finally {
      // Hide loading indicator
      setState(() {
        _isLoading = false; // Reset loading state
      });
    }
  }



  Widget _buildStrLocFilter() {
    return SizedBox(
      width: 150,
      height: 40,
      child: TextFormField(
        decoration: const InputDecoration(
          labelText: 'Filter by Str Loc',
          border: OutlineInputBorder(),
        ),
        onChanged: (value) {
          setState(() {
            _strLocFilter = value.trim();
          });
        },
      ),
    );
  }


  Widget _buildDropdown(String title, List<String> items, String value,
      void Function(String?)? onChanged) {
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

          // Clear the input value if switching from any other another parameter
          if (_selectedParameter != 'Plant,Material,Material Group,Str Loc') {
            _inputValue = ''; // Clear the value when changing from Plant
            _inputController.clear(); // Clear the input field if not Plant
          }
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
    if (_selectedParameter == 'Plant') {
      return DropdownButtonFormField<String>(
        decoration: const InputDecoration(
          labelText: 'Select Plant',
          border: OutlineInputBorder(),
        ),
        value: _inputValue.isNotEmpty ? _inputValue : null,
        items: _plants.map((String plant) {
          return DropdownMenuItem<String>(
            value: plant,
            child: Text(plant),
          );
        }).toList(),
        onChanged: (String? newValue) {
          setState(() {
            _inputValue = newValue ?? '';
            _inputController.text = _inputValue;
          });
        },
      );
    } else {
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
  }

  Widget _buildDataTable() {
    if (_apiData == null || _apiData!['Items'] == null) {
      return const Center(child: Text('No data available'));
    }

    // Get the list of items from the API response
    final items = _apiData!['Items'] as List<dynamic>? ?? [];
    if (items.isEmpty) return const Center(child: Text('No data available'));

    // Apply filter for "Str Loc" if a value is entered
    final filteredItems = _strLocFilter.isNotEmpty
        ? items.where((item) {
      final strLoc = item['Strloc'] ?? '';
      return strLoc.toString().toLowerCase().contains(
          _strLocFilter.toLowerCase());
    }).toList()
        : items;

    if (_selectedParameter == 'Material') {
      return _buildColumnLayout(items);
    }

    final columns = [
      'S NO.',
      'Material',
      'Desc',
      'Plant',
      'Strloc',
      'StrlocDesc',
      'Material Group',
      'Unrestricted',
      'QualityInspection',
      'Blocked',
      // 'ReturnBlock',
      // 'VendorCode',
      // 'VendorName',
      // 'AtVendor',
      'StockInTransfer'
    ];

    final rows = filteredItems
        .asMap()
        .entries
        .map<DataRow>((entry) {
      final index = entry.key;
      final item = entry.value as Map<String, dynamic>;

      String getCellValue(String key) {
        if (key == 'Material') {
          final material = item[key]?.toString() ?? 'N/A';
          return material.length > 10
              ? material.substring(material.length - 10)
              : material;
        }
        return item[key]?.toString().isNotEmpty == true ? item[key]! : 'N/A';
      }


      final cells = [
        DataCell(Center(child: Text((index + 1).toString()))),
        DataCell(Center(child: Text(getCellValue('Material')))),
        DataCell(Center(child: Text(getCellValue('Desc')))),
        DataCell(Center(child: Text(getCellValue('Plant')))),
        DataCell(Center(child: Text(getCellValue('Strloc')))),
        DataCell(Center(child: Text(getCellValue('StrlocDesc')))),
        DataCell(Center(child: Text(getCellValue('Material Group')))),
        DataCell(Center(child: Text(getCellValue('Unrestricted')))),
        DataCell(Center(child: Text(getCellValue('QualityInspection')))),
        DataCell(Center(child: Text(getCellValue('Blocked')))),
        // DataCell(Center(child: Text(getCellValue('ReturnBlock')))),
        // DataCell(Center(child: Text(getCellValue('VendorCode')))),
        // DataCell(Center(child: Text(getCellValue('VendorName')))),
        // DataCell(Center(child: Text(getCellValue('AtVendor')))),
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
            width: 2100, // width of content
            child: DataTable2(
              columnSpacing: 1.0,
              horizontalMargin: 1.0,
              minWidth: 1700,
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
    // Apply filter for Str Loc if a value is entered
    final filteredItems = _strLocFilter.isNotEmpty
        ? items.where((item) {
      final strLoc = item['Strloc'] ?? '';
      return strLoc.toString().toLowerCase().contains(
          _strLocFilter.toLowerCase());
    }).toList()
        : items;

    if (filteredItems.isEmpty) {
      return const Center(child: Text('No results available for the filter.'));
    }

    return Expanded(
      child: ListView.builder(
        itemCount: filteredItems.length,
        itemBuilder: (context, index) {
          final item = filteredItems[index] as Map<String, dynamic>;

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
                  const Expanded(
                    flex: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [Text('Material:', style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.black)),
                        Text('Desc:', style: TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.black)),
                        Text('Plant:', style: TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.black)),
                        Text('Strloc:', style: TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.black)),
                        Text('StrlocDesc:', style: TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.black)),
                        Text('MatGroup:', style: TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.black)),
                        Text('Unrestricted:', style: TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.black)),
                        Text('QualityInspec:', style: TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.black)),
                        Text('Blocked:', style: TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.black)),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 9,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item['Material'] ?? 'N/A', style: const TextStyle(
                            color: Colors.black)),
                        Text(item['Desc'] ?? 'N/A', style: const TextStyle(
                            color: Colors.black)),
                        Text(item['Plant'] ?? 'N/A', style: const TextStyle(
                            color: Colors.black)),
                        Text(item['Strloc'] ?? 'N/A', style: const TextStyle(
                            color: Colors.black)),
                        Text(item['StrlocDesc'] ?? 'N/A', style: const TextStyle(
                            color: Colors.black)),
                        Text(item['Material Group'] ?? 'N/A', style: const TextStyle(
                            color: Colors.black)),
                        Text(item['Unrestricted'] ?? 'N/A', style: const TextStyle(
                            color: Colors.black)),
                        Text(item['QualityInspection'] ?? 'N/A', style: const TextStyle(
                            color: Colors.black)),
                        Text(item['Blocked'] ?? 'N/A', style: const TextStyle(
                            color: Colors.black)),
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


  // Show the filter only for Material, Material Group, and Plant parameters
  bool _shouldShowFilter() {
    return _selectedParameter == 'Material' ||
        _selectedParameter == 'Material Group' ||
        _selectedParameter == 'Plant';
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
                  // Dropdown for selecting the parameter
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

                  const SizedBox(height: 12.0),

                  if (_selectedParameter == 'Material' ||
                      _selectedParameter == 'Material Group' ||
                      _selectedParameter == 'Plant')
                    Column(
                      children: [
                        _buildStrLocFilter(),
                        const SizedBox(height: 16.0),
                      ],
                    ),

                  Row(
                    children: [
                      Visibility(
                        visible: _selectedParameter != 'Plant',
                        child: Expanded(
                          child: ElevatedButton(
                            onPressed: _generatePdf,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green[700],
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text('Generate PDF'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16.0),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[900],
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text('Generate Listing'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16.0),

                  if (_isLoading) const CircularProgressIndicator(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8.0),
          if (_apiData != null && !_isLoading) _buildDataTable(),
        ],
      ),
    );
  }
}
