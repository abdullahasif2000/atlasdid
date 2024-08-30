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
    return Scaffold(
      appBar: AppBar(
        title: Text(' Summary'),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Plant: $plant', style: TextStyle(fontSize: 16.0)),
            Text('Material: $material', style: TextStyle(fontSize: 16.0)),
            Text('Material Group: $materialGroup', style: TextStyle(fontSize: 16.0)),
            Text('Storage Location: $strLoc', style: TextStyle(fontSize: 16.0)),
            SizedBox(height: 16.0),
            Text('Summary:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.0)),
            SizedBox(height: 8.0),
            _buildPrettyJsonCard(apiData),
          ],
        ),
      ),
    );
  }

  Widget _buildPrettyJsonCard(Map<String, dynamic> data) {
    String prettyString = prettyJson(data);

    return Card(
      color: Colors.grey[200],
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Text(
            prettyString,
            style: TextStyle(fontFamily: 'Courier', fontSize: 16.0),
          ),
        ),
      ),
    );
  }

  String prettyJson(Map<String, dynamic> data) {
    JsonEncoder encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(data);
  }
}
