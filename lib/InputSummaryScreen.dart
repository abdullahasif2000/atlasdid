import 'package:flutter/material.dart';

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
    if (items.isEmpty) {
      return Center(child: Text('No data available'));
    }

    // Extract columns from the first item
    final firstItem = items.first as Map<String, dynamic>;
    final columns = ['Serial No'] + firstItem.keys.toList(); // Add Serial No to columns

    // Create rows based on extracted columns
    final rows = items.asMap().entries.map<DataRow>((entry) {
      final index = entry.key; // Serial number
      final item = entry.value as Map<String, dynamic>;

      final cells = [index + 1].map<DataCell>((serialNumber) {
        return DataCell(_buildTableCell(serialNumber.toString()));
      }).toList()
          + columns.sublist(1).map<DataCell>((column) {
            final value = item[column] ?? '';
            return DataCell(_buildTableCell(value.toString()));
          }).toList();

      return DataRow(cells: cells);
    }).toList();

    return DataTable(
      columnSpacing: 0.0, // Set spacing to 0 to ensure borders align properly
      columns: columns.map<DataColumn>((column) {
        return DataColumn(
          label: _buildTableCell(column, isHeader: true),
        );
      }).toList(),
      rows: rows,
    );
  }

  Widget _buildTableCell(String text, {bool isHeader = false}) {
    return Container(
      padding: EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(
            color: isHeader ? Colors.grey.shade600 : Colors.grey.shade300,
            width: 1.0,
          ),
        ),
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
            color: isHeader ? Colors.black : Colors.blue[900],
          ),
        ),
      ),
    );
  }
}
