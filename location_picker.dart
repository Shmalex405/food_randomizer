import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_google_places/flutter_google_places.dart';
import 'package:google_maps_webservice/places.dart';
import 'api_keys.dart';

class LocationPicker extends StatefulWidget {
  final LatLng initialLocation; // Added to accept the initial location
  final double initialDistance;
  final ValueChanged<double> onDistanceChanged;

  LocationPicker({
    required this.initialLocation, // Required initial location parameter
    required this.initialDistance,
    required this.onDistanceChanged,
  });

  @override
  _LocationPickerState createState() => _LocationPickerState();
}

class _LocationPickerState extends State<LocationPicker> {
  late LatLng _pickedLocation; // Updated to be initialized later
  final TextEditingController _searchController = TextEditingController();
  late double _selectedDistance;

  @override
  void initState() {
    super.initState();
    _pickedLocation =
        widget.initialLocation; // Initialize with the passed location
    _selectedDistance = widget.initialDistance;
  }

  void _onMapTap(LatLng location) {
    setState(() {
      _pickedLocation = location;
    });
  }

  void _confirmLocation() {
    widget.onDistanceChanged(
      _selectedDistance,
    ); // Update the distance when confirming location
    Navigator.of(context)
        .pop(_pickedLocation); // Pop the location to the previous screen
  }

  Future<void> _searchLocation() async {
    Prediction? prediction = await PlacesAutocomplete.show(
      context: context,
      apiKey: googleApiKey,
      mode: Mode.overlay,
      language: "en",
      components: [Component(Component.country, "us")],
    );

    if (prediction != null) {
      GoogleMapsPlaces places = GoogleMapsPlaces(apiKey: googleApiKey);
      PlacesDetailsResponse detail =
          await places.getDetailsByPlaceId(prediction.placeId!);
      setState(() {
        _pickedLocation = LatLng(
          detail.result.geometry!.location.lat,
          detail.result.geometry!.location.lng,
        );
      });
      mapController.animateCamera(
        CameraUpdate.newLatLng(_pickedLocation),
      );
    }
  }

  late GoogleMapController mapController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select Location'),
        actions: [
          IconButton(
            icon: Icon(Icons.check),
            onPressed: _confirmLocation,
          )
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (controller) {
              mapController = controller;
            },
            initialCameraPosition: CameraPosition(
              target: _pickedLocation, // Center on the picked location
              zoom: 14.0,
            ),
            markers: {
              Marker(
                markerId: MarkerId('selected-location'),
                position: _pickedLocation,
              ),
            },
            circles: {
              Circle(
                circleId: CircleId('selected-circle'),
                center: _pickedLocation,
                radius: _selectedDistance * 1000, // Convert km to meters
                fillColor: Colors.orange.withOpacity(0.2),
                strokeColor: Colors.orange,
                strokeWidth: 2,
              ),
            },
            onTap: _onMapTap,
          ),
          Positioned(
            top: 16.0,
            left: 16.0,
            right: 16.0,
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  readOnly: true,
                  onTap: _searchLocation,
                  decoration: InputDecoration(
                    hintText: 'Search for a location',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _selectedDistance < 1
                          ? 'Distance: ${(_selectedDistance * 1000).toInt()} meters'
                          : 'Distance: ${_selectedDistance.toStringAsFixed(1)} km',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 10),
                    Slider(
                      value: _selectedDistance,
                      min: 0.1, // Minimum value is now 100 meters
                      max: 10.0, // Maximum value is now 10 kilometers
                      divisions: 99, // More divisions for finer control
                      activeColor: Colors.orange,
                      inactiveColor: Colors.grey.shade400,
                      label: _selectedDistance.toStringAsFixed(1) + ' km',
                      onChanged: (value) {
                        setState(() {
                          _selectedDistance = value;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 16.0,
            left: 16.0,
            right: 16.0,
            child: ElevatedButton(
              onPressed: _confirmLocation,
              child: Text('Search from this Location'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: EdgeInsets.symmetric(vertical: 16.0),
                textStyle: TextStyle(fontSize: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
