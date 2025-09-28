// lib/screens/EditMarkerPage.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zapp/models/marker_data_model.dart';
import 'package:zapp/screens/HomeScreen.dart';
import 'package:zapp/services/auth_service.dart';
import 'package:zapp/services/map_service.dart';

class EditMarkerPage extends StatefulWidget {
  const EditMarkerPage({super.key});

  @override
  _EditMarkerPageState createState() => _EditMarkerPageState();
}

class _EditMarkerPageState extends State<EditMarkerPage> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  double _ranking = 5.0;
  MarkerData? _selectedMarker;
  List<MarkerData> _userMarkers = [];

  @override
  void initState() {
    super.initState();
    _loadMarkers();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadMarkers() async {
    final mapService = Provider.of<MapService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    _userMarkers = await mapService.loadUserMarkers(authService.currentUser!.id);
    setState(() {});
  }

  void _fillFields(MarkerData marker) {
    _titleController.text = marker.title ?? '';
    _descriptionController.text = marker.description ?? '';
    _ranking = marker.ranking ?? 5.0;
  }

  @override
  Widget build(BuildContext context) {
    final mapService = Provider.of<MapService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back),
          onPressed: () {
            // Navigator.pop führt zurück zur vorherigen Seite, ohne neue Seite zu erstellen
            Navigator.pop(context);
          },
        ),
        title: const Text('Edit Marker'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<MarkerData>(
              value: _selectedMarker,
              items: _userMarkers
                  .map((marker) => DropdownMenuItem<MarkerData>(
                value: marker,
                child: Text(marker.title ?? 'Marker ID: ${marker.id}'),
              ))
                  .toList(),
              onChanged: (marker) {
                setState(() {
                  _selectedMarker = marker;
                  if (marker != null) {
                    _fillFields(marker);
                  }
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
              onPressed: () async {
                if (_selectedMarker != null) {
                  await mapService.updateMarker(
                    markerId: _selectedMarker!.id,
                    title: _titleController.text,
                    description: _descriptionController.text,
                    ranking: _ranking,
                  );
                  // Lade die Marker neu, um die Dropdown-Liste zu aktualisieren
                  await _loadMarkers();
                  Navigator.pop(context);
                }
              },
              child: const Text('Save'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_selectedMarker != null) {
                  await mapService.deleteMarker(_selectedMarker!.id);
                  // Lade die Marker neu, um die Dropdown-Liste zu aktualisieren
                  await _loadMarkers();
                  setState(() {
                    _selectedMarker = null;
                    _titleController.clear();
                    _descriptionController.clear();
                    _ranking = 5.0;
                  });
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