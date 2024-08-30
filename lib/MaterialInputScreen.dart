import 'package:flutter/material.dart';
import 'InputSummaryScreen.dart';
import 'api_service.dart';

class MaterialInputScreen extends StatefulWidget {
  @override
  _MaterialInputScreenState createState() => _MaterialInputScreenState();
}

class _MaterialInputScreenState extends State<MaterialInputScreen> {
  final _formKey = GlobalKey<FormState>();
  String _material = '';
  String _materialGroup = '';
  String _strLoc = '';
  String _plant = '';

  late ApiService apiService;

  @override
  void initState() {
    super.initState();
    apiService = ApiService('http://10.7.5.52:8084/AAPLSTORE');
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      if (_plant.isEmpty && _material.isEmpty && _materialGroup.isEmpty && _strLoc.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please enter at least one search parameter')),
        );
        return;
      }

      try {
        final data = await apiService.getData(
          plant: _plant,
          mat: _material,
          matgrp: _materialGroup,
          strloc: _strLoc,
        );

        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => InputSummaryScreen(
              material: _material,
              materialGroup: _materialGroup,
              strLoc: _strLoc,
              plant: _plant,
              apiData: data,
            ),
          ),
        );
      } catch (e) {
        print('Error: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to fetch data from server')),
        );
      }
    }
  }

  Widget _buildRow(String label, String hintText, Function(String?) onSaved) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: <Widget>[
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
                color: Colors.blue[900], // Set the text color to blue
              ),
            ),
          ),
          SizedBox(width: 16.0),
          Expanded(
            flex: 5,
            child: TextFormField(
              decoration: InputDecoration(
                hintText: hintText,
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                return null;
              },
              onSaved: onSaved,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Material Input',style: TextStyle( fontWeight: FontWeight.w500,fontSize:25.0, ),),
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    _buildRow('Plant', 'Enter Plant', (value) {
                      _plant = value!;
                    }),
                    _buildRow('Material', 'Enter Material', (value) {
                      _material = value!;
                    }),
                    _buildRow('Material Group', 'Enter Material Group', (value) {
                      _materialGroup = value!;
                    }),
                    _buildRow('Str Loc', 'Enter Storage Location', (value) {
                      _strLoc = value!;
                    }),
                    SizedBox(height: 20.0),
                    ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.red[900],
                      ),
                      child: Text('Submit'),
                    ),
                    SizedBox(height: 30.0), // Space between button and message
                    Text(
                      '*Note*: Please enter at least one field to continue',
                      style: TextStyle(
                        fontSize: 16.0,
                        color: Colors.red[900], // Set the color of the message to red
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center, // Center align the text
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
