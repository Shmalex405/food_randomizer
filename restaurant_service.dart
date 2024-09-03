import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:food_randomizer/api_keys.dart';

class RestaurantService {
  final String apiKey = googleApiKey;

  Future<List<dynamic>> fetchNearbyRestaurants(
      double lat, double lng, int radius) async {
    final String url =
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=$lat,$lng&radius=$radius&type=restaurant&key=$apiKey';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['results'];
    } else {
      throw Exception('Failed to load restaurants');
    }
  }

  String getPhotoUrl(String photoReference, int maxWidth) {
    return 'https://maps.googleapis.com/maps/api/place/photo?maxwidth=$maxWidth&photoreference=$photoReference&key=$apiKey';
  }

  Future<Map<String, dynamic>> fetchPlaceDetails(String placeId) async {
    final String url =
        'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$apiKey';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['result'];
    } else {
      throw Exception('Failed to load place details');
    }
  }
}
