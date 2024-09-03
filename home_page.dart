import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'location_picker.dart';
import 'map_view.dart';
import 'services/restaurant_service.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';

class HomePage extends StatefulWidget {
  final bool showLocationSetMessage; // Add this parameter

  HomePage({this.showLocationSetMessage = false}); // Default to false

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final RestaurantService _restaurantService = RestaurantService();
  Map<String, dynamic>? _selectedRestaurant;
  bool _isLoading = false;
  double _selectedDistance = 10.0; // Default distance in kilometers
  List<Map<String, dynamic>> _restaurants = [];
  LatLng? _selectedLocation; // User-selected location
  String _locationOption = "Use Current Location"; // Default option
  String? _locationDisplayName; // Display name of the location
  PageController _pageController =
      PageController(); // PageController for auto-scrolling
  int _currentPage = 0;
  Timer? _autoScrollTimer; // Timer for auto-scrolling

  @override
  void initState() {
    super.initState();
    _startAutoScroll();

    // Show a snack bar if a new location was selected
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_selectedLocation != null) {
        _getRandomRestaurant(); // Automatically fetch the restaurants
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                "New location set! Click Randomize to see new Restaurants."),
            duration: Duration(seconds: 3),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _autoScrollTimer?.cancel(); // Cancel the timer when disposing the widget
    super.dispose();
  }

  void _startAutoScroll() {
    _autoScrollTimer = Timer.periodic(Duration(seconds: 3), (timer) {
      if (_pageController.hasClients) {
        _currentPage =
            ((_currentPage + 1) % _selectedRestaurant!['photos'].length)
                .toInt();

        _pageController.animateToPage(
          _currentPage,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  Future<void> _getRandomRestaurant() async {
    setState(() {
      _isLoading = true;
    });

    try {
      LatLng searchLocation;
      String locationName;

      if (_locationOption == "Use Current Location") {
        LocationPermission permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Location permission is required')),
          );
          return;
        }

        Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high);
        searchLocation = LatLng(position.latitude, position.longitude);
        locationName = "your current location";
      } else if (_selectedLocation != null) {
        searchLocation = _selectedLocation!;
        locationName = "the selected location";
      } else {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please select a location on the map')),
        );
        return;
      }

      List<dynamic> restaurants =
          await _restaurantService.fetchNearbyRestaurants(
        searchLocation.latitude,
        searchLocation.longitude,
        (_selectedDistance * 1000).toInt(),
      );

      if (restaurants.isNotEmpty) {
        restaurants.shuffle();
        final selectedRestaurant = restaurants.first;
        final placeDetails = await _restaurantService
            .fetchPlaceDetails(selectedRestaurant['place_id']);
        setState(() {
          _selectedRestaurant = {
            ...selectedRestaurant,
            ...placeDetails,
          };
          _restaurants = restaurants.cast<Map<String, dynamic>>();
          _locationDisplayName = locationName;
        });
      } else {
        setState(() {
          _selectedRestaurant = {'name': 'No restaurants found nearby.'};
          _locationDisplayName = null;
        });
      }
    } catch (e) {
      setState(() {
        _selectedRestaurant = {'name': 'Error: ${e.toString()}'};
        _locationDisplayName = null;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  Future<void> _selectLocationOnMap() async {
    LatLng? selectedLocation = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LocationPicker(
          initialLocation: _selectedLocation ??
              LatLng(37.7749,
                  -122.4194), // Pass the current location or a default one
          initialDistance: _selectedDistance,
          onDistanceChanged: (newDistance) {
            setState(() {
              _selectedDistance = newDistance;
            });
          },
        ),
      ),
    );

    if (selectedLocation != null) {
      setState(() {
        _selectedLocation = selectedLocation;
        _locationOption = "Choose a Location to Search From";
      });

      // Display the snackbar when a new location is set
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text("New location set! Click Randomize to see new Restaurants."),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Widget _buildImageSlider(List<dynamic> photos) {
    return Stack(
      children: [
        Container(
          height: 200,
          margin: EdgeInsets.symmetric(vertical: 10.0),
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 5.0,
                spreadRadius: 1.0,
                offset: Offset(2, 2),
              ),
            ],
          ),
          child: PageView.builder(
            controller: _pageController,
            itemCount: photos.length,
            itemBuilder: (context, index) {
              final photoUrl = _restaurantService.getPhotoUrl(
                  photos[index]['photo_reference'], 400);
              return ClipRRect(
                borderRadius: BorderRadius.circular(10.0),
                child: Image.network(photoUrl, fit: BoxFit.cover),
              );
            },
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
          ),
        ),
        Positioned(
          bottom: 8.0,
          left: 0.0,
          right: 0.0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(photos.length, (index) {
              return AnimatedContainer(
                duration: Duration(milliseconds: 300),
                margin: EdgeInsets.symmetric(horizontal: 4.0),
                height: 8.0,
                width: _currentPage == index ? 16.0 : 8.0,
                decoration: BoxDecoration(
                  color: _currentPage == index ? Colors.orange : Colors.grey,
                  borderRadius: BorderRadius.circular(8.0),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildRestaurantInfo() {
    if (_selectedRestaurant == null) {
      return Column(
        children: [
          if (_locationDisplayName != null)
            Text(
              'Searching from $_locationDisplayName',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.blue),
            ),
          SizedBox(height: 10),
          Text(
            'Press the button to get started!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20),
          ),
        ],
      );
    }

    String? cuisineType;
    if (_selectedRestaurant!['types'] != null &&
        _selectedRestaurant!['types'].isNotEmpty) {
      cuisineType =
          _getCuisineType(List<String>.from(_selectedRestaurant!['types']));
    }

    String? address = _selectedRestaurant!['formatted_address'] ??
        _selectedRestaurant!['vicinity'];

    String? reservationUrl;
    if (_selectedRestaurant!['website'] != null &&
        _selectedRestaurant!['website'].contains('opentable.com')) {
      reservationUrl = _selectedRestaurant!['website'];
    }

    return Expanded(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_locationDisplayName != null)
              Center(
                child: Text(
                  'Searching from $_locationDisplayName',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.blue),
                ),
              ),
            SizedBox(height: 10),
            if (_selectedRestaurant!['photos'] != null &&
                _selectedRestaurant!['photos'].isNotEmpty)
              _buildImageSlider(_selectedRestaurant!['photos']),
            SizedBox(height: 10),
            GestureDetector(
              onTap: () {
                _launchGoogleSearch(
                    _selectedRestaurant!['name'] ?? '', address ?? '');
              },
              child: Text(
                _selectedRestaurant!['name'] ?? 'Unknown Name',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            if (address != null)
              Text(
                address,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            if (cuisineType != null)
              Text(
                'Cuisine Type: $cuisineType',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            if (_selectedRestaurant!['rating'] != null)
              Text(
                'Rating: ${_selectedRestaurant!['rating']} (${_selectedRestaurant!['user_ratings_total']} reviews)',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            if (_selectedRestaurant!['price_level'] != null)
              Text(
                'Price Level: ${'💲' * _selectedRestaurant!['price_level']}',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            SizedBox(height: 20),
            _buildActionButtons(reservationUrl),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _launchGoogleSearch(String name, String address) async {
    final query = Uri.encodeComponent('$name $address');
    final url = 'https://www.google.com/search?q=$query';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  Widget _buildActionButtons(String? reservationUrl) {
    return Center(
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 8.0,
        runSpacing: 8.0,
        children: [
          if (_selectedRestaurant!['website'] != null)
            _buildActionButton(
              icon: Icons.public,
              label: 'Website',
              onPressed: () => _launchURL(_selectedRestaurant!['website']),
            ),
          _buildActionButton(
            icon: Icons.directions,
            label: 'Directions',
            onPressed: () => _launchURL(
                'https://www.google.com/maps/dir/?api=1&destination=${Uri.encodeComponent(_selectedRestaurant!['formatted_address'])}'),
          ),
          if (_selectedRestaurant!['formatted_phone_number'] != null)
            _buildActionButton(
              icon: Icons.call,
              label: 'Call',
              onPressed: () => _launchURL(
                  'tel:${_selectedRestaurant!['formatted_phone_number']}'),
            ),
          if (_selectedRestaurant!['url'] != null)
            _buildActionButton(
              icon: Icons.menu_book,
              label: 'Menu',
              onPressed: () => _launchURL(_selectedRestaurant!['url']),
            ),
          if (reservationUrl != null)
            _buildActionButton(
              icon: Icons.event_seat,
              label: 'Reserve a Table',
              onPressed: () => _launchURL(reservationUrl),
            ),
          _buildActionButton(
            icon: Icons.map,
            label: 'View on Map',
            onPressed: _selectedRestaurant != null && _restaurants.isNotEmpty
                ? () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MapView(
                          selectedRestaurant: _selectedRestaurant!,
                          allRestaurants: _restaurants,
                        ),
                      ),
                    );
                  }
                : () {},
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
  }) {
    return ElevatedButton.icon(
      icon: Icon(icon, size: 18),
      label: Text(label),
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  String? _getCuisineType(List<dynamic> types) {
    final Map<String, String> cuisineTypeMapping = {
      'indian': 'Indian',
      'italian': 'Italian',
      'mexican': 'Mexican',
      'japanese': 'Japanese',
      'chinese': 'Chinese',
      'thai': 'Thai',
      'french': 'French',
      'american': 'American',
      'vietnamese': 'Vietnamese',
      'korean': 'Korean',
      'greek': 'Greek',
    };

    for (var type in types) {
      if (cuisineTypeMapping.containsKey(type)) {
        return cuisineTypeMapping[type]!;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Food Randomizer'),
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              DropdownButton<String>(
                value: _locationOption,
                items: [
                  DropdownMenuItem(
                    child: Text(
                      "Use Current Location",
                      style: TextStyle(color: Colors.blue),
                    ),
                    value: "Use Current Location",
                  ),
                  DropdownMenuItem(
                    child: Text(
                      "Choose a Location to Search From",
                      style: TextStyle(color: Colors.blue),
                    ),
                    value: "Choose a Location to Search From",
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _locationOption = value!;
                    if (_locationOption == "Choose a Location to Search From") {
                      _selectLocationOnMap();
                    }
                  });
                },
              ),
              SizedBox(height: 20),
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
              Slider(
                value: _selectedDistance,
                min: 0.1,
                max: 10.0,
                divisions: 99,
                label: _selectedDistance.toStringAsFixed(1) + ' km',
                onChanged: (value) {
                  setState(() {
                    _selectedDistance = value;
                  });
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _getRandomRestaurant,
                child: _isLoading
                    ? CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white))
                    : Text('Randomize'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  textStyle: TextStyle(fontSize: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              SizedBox(height: 20),
              _buildRestaurantInfo(),
            ],
          ),
        ),
      ),
    );
  }
}
