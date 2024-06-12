import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:mysql1/mysql1.dart';

class EditMarkerPage extends StatefulWidget {



  const EditMarkerPage({super.key});

  @override
  _EditMarkerPageState createState() => _EditMarkerPageState();
}

class dropDownMarker {
  final double latitude;
  final double longitude;
  final Future<String> formatted;
  final int id;
  dropDownMarker(this.latitude, this.longitude, this.formatted, this.id);

}

class _EditMarkerPageState extends State<EditMarkerPage> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late double _ranking;
  late MySqlConnection _conn;
  late List<dropDownMarker> markers = [];
  dropDownMarker? _selectedMarker;
  static const String apiKey = "b95c8ec314774f969029f107534ead70";


  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _ranking = 5.0;
    _selectedMarker = null;
    _connectToDatabase();
  }



  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<String> getCountyName(double lat, double long, String type) async {
   final url = "https://api.geoapify.com/v1/geocode/reverse?lat=$lat&lon=$long&type=$type&apiKey=$apiKey";
   final response = await http.get(Uri.parse(url));
   return jsonDecode(response.body)['features'][0]['properties']['formatted'];
  }


  Future<void> _fillMarkerList() async {
    markers.clear();
    final results = await _conn.query('SELECT * FROM markers');

    for (var row in results) {
      markers.add(
        dropDownMarker(
            row[1], row[2], getCountyName(row[1], row[2], "city"), row[0]
        )
      );
    }
    print("!!!!");
    print(markers);
    setState(() {});
  }

  Future<void> _storeInfosInDatabase() async {
    if (_selectedMarker != null) {
      await _conn.query(
        'UPDATE markers SET title = ?, description = ?, ranking = ? WHERE latitude = ? AND longitude = ?',
        [
          _titleController.text,
          _descriptionController.text,
          _ranking,
          _selectedMarker!.latitude,
          _selectedMarker!.longitude,
        ],
      );
    }
  }

  Future<void> _connectToDatabase() async {
    _conn = await MySqlConnection.connect(ConnectionSettings(
      host: 'sql7.freesqldatabase.com',
      port: 3306,
      user: 'sql7712971',
      db: 'sql7712971',
      password: 'YnYC9zjPM1',
    ));
    _fillMarkerList();
  }

  Future<void> fillFields() async {
    if (_selectedMarker != null) {
      final results = await _conn.query(
        'SELECT * FROM markers WHERE latitude = ? AND longitude = ?',
        [_selectedMarker!.latitude, _selectedMarker!.longitude],
      );
      if (results.isNotEmpty) {
        final row = results.first;
        print("Row data: $row"); // Debugging line to print fetched row
        setState(() {
          _titleController.text = row['title'] ?? '';
          _descriptionController.text = row['description'].toString() ?? '';
          _ranking = row['ranking'] ?? 5.0;
        });

        print("Ranking: ${row['ranking']}"); // Debugging line to check ranking
      } else {
        setState(() {
          _titleController.text = '';
          _descriptionController.text = '';
          _ranking = 5.0;
        });
        print("No data found for the selected marker."); // Debugging line for empty result
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Marker'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<dropDownMarker>(
              value: _selectedMarker,
              items: markers
                  .map((marker) => DropdownMenuItem<dropDownMarker>(
                value: marker,
                child: FutureBuilder(
                  future: marker.formatted,
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return Text(snapshot.data ?? '');
                    } else {
                      return Text('');
                    }
                  },
                ),
              ))
                  .toList(),
              onChanged: (marker) {
                setState(() {
                  _selectedMarker = marker;
                  fillFields();
                });
              },
              decoration: const InputDecoration(
                labelText: 'Select Marker',
              ),
            ),
            const SizedBox(height: 16.0),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
              ),
            ),
            const SizedBox(height: 16.0),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
              ),
            ),
            const SizedBox(height: 16.0),
            Text(
              "Ranking: ${_ranking.toStringAsFixed(1)}",
            ),
            Slider(
              value: _ranking,
              min: 0.0,
              max: 10.0,
              divisions: 100,
              label: _ranking.toStringAsFixed(1),
              onChanged: (value) {
                setState(() {
                  _ranking = value;
                });
              },
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () {
                _storeInfosInDatabase();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => EditMarkerPage()),
                      (Route<dynamic> route) => false,
                );
              },
              child: const Text('Save'),
            ),
            ElevatedButton(
              onPressed: () {
                if (_selectedMarker != null) {
                  _conn.query(
                    'DELETE FROM markers WHERE latitude = ? AND longitude = ?',
                    [_selectedMarker!.latitude, _selectedMarker!.longitude],
                  );
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => EditMarkerPage()),
                        (Route<dynamic> route) => false,
                  );
                }
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }
}