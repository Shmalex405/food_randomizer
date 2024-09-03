import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class MapView extends StatefulWidget {
  final Map<String, dynamic> selectedRestaurant;
  final List<Map<String, dynamic>> allRestaurants;

  MapView({required this.selectedRestaurant, required this.allRestaurants});

  @override
  _MapViewState createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  late GoogleMapController mapController;
  LatLng _initialPosition = LatLng(37.7749, -122.4194);

  @override
  void initState() {
    super.initState();
    _setInitialPosition();
  }

  void _setInitialPosition() {
    final restaurantLocation = LatLng(
      widget.selectedRestaurant['geometry']['location']['lat'],
      widget.selectedRestaurant['geometry']['location']['lng'],
    );
    setState(() {
      _initialPosition = restaurantLocation;
    });
  }

  void _launchMapsUrl(LatLng destination) async {
    final url =
        'https://www.google.com/maps/dir/?api=1&destination=${destination.latitude},${destination.longitude}';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    Set<Marker> markers = widget.allRestaurants.map((restaurant) {
      return Marker(
        markerId: MarkerId(restaurant['place_id']),
        position: LatLng(
          restaurant['geometry']['location']['lat'],
          restaurant['geometry']['location']['lng'],
        ),
        infoWindow: InfoWindow(
          title: restaurant['name'],
          snippet: restaurant['formatted_address'],
        ),
        icon: restaurant['place_id'] == widget.selectedRestaurant['place_id']
            ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue)
            : BitmapDescriptor.defaultMarker,
      );
    }).toSet();

    return Scaffold(
      appBar: AppBar(
        title: Text('Restaurant Map View'),
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (controller) {
              mapController = controller;
            },
            initialCameraPosition: CameraPosition(
              target: _initialPosition,
              zoom: 14.0,
            ),
            markers: markers,
          ),
          Positioned(
            bottom: 16.0,
            left: 16.0,
            right: 16.0,
            child: ElevatedButton(
              onPressed: () {
                _launchMapsUrl(_initialPosition);
              },
              child: Text('Get Directions'),
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
