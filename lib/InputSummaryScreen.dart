import 'package:flutter/material.dart';
import 'dart:convert';

class InputSummaryScreen extends StatelessWidget {
  final String material;
  final String materialGroup;
  final String strLoc;
  final String plant;
  final Map<String, dynamic> apiData;

  InputSummaryScreen({
    required this.material,
    required this.materialGroup,
    required this.strLoc,
    required this.plant,
    required this.apiData,
  });

  @override
  Widget build(BuildContext context) {
    // Extract items from API data
    final items = apiData['Items'] as List<dynamic>? ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Summary',
          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 25.0),
        ),
        backgroundColor: Colors.yellow[700],
        foregroundColor: Colors.red[900],
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _buildText('Plant: $plant'),
            _buildText('Material: $material'),
            _buildText('Material Group: $materialGroup'),
            _buildText('Storage Location: $strLoc'),
            SizedBox(height: 16.0),
            _buildText('Summary:', fontWeight: FontWeight.bold, fontSize: 18.0),
            SizedBox(height: 8.0),
            // Horizontal scroll view for DataTable
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: _buildDataTable(items),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildText(String text, {FontWeight fontWeight = FontWeight.normal, double fontSize = 16.0}) {
    return Text(
      text,
      style: TextStyle(
        color: Colors.blue[900],
        fontWeight: fontWeight,
        fontSize: fontSize,
      ),
    );
  }

  Widget _buildDataTable(List<dynamic> items) {
    // Define the columns for the DataTable
    final columns = <String>[
      'Desc', 'VendorName', 'Strloc', 'StrlocDesc',
      'Unrestricted', 'AtVendor', 'VendorCode', 'Material',
      'ReturnBlock', 'QualityInspection', 'Blocked', 'StockInTransfer'
    ];

    // Create the rows from the JSON data
    final rows = items.map<DataRow>((item) {
      final cells = columns.map<DataCell>((column) {
        final value = item[column] ?? ''; // Use empty string if value is null
        return DataCell(Text(value.toString()));
      }).toList();
      return DataRow(cells: cells);
    }).toList();

    return DataTable(
      columnSpacing: 16.0, // Adjust spacing as needed
      columns: columns.map<DataColumn>((column) {
        return DataColumn(label: Text(column));
      }).toList(),
      rows: rows,
    );
  }
}
