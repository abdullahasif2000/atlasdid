import 'package:flutter/material.dart';
import 'api_service.dart';

class RecordsListScreen extends StatefulWidget {
  @override
  _RecordsListScreenState createState() => _RecordsListScreenState();
}

class _RecordsListScreenState extends State<RecordsListScreen> {
  late ApiService apiService;
  List<dynamic> records = [];
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    apiService = ApiService('http://10.7.5.52:8084/AAPLSTORE');
    fetchRecords();
  }

  void fetchRecords() async {
    try {
      final data = await apiService.fetchAllRecords(
        plant: 'KHI',
      );

      setState(() {
        records = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Records List'),
        backgroundColor: Colors.blue[900],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
          ? Center(child: Text(errorMessage))
          : ListView.builder(
        itemCount: records.length,
        itemBuilder: (context, index) {
          final record = records[index];
          return ListTile(
            title: Text(record['Material'] ?? 'No Material'),
            subtitle: Text('Group: ${record['MaterialGroup'] ?? 'N/A'}'),
          );
        },
      ),
    );
  }
}
