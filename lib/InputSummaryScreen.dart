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
            _buildPrettyJsonCard(apiData),
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
