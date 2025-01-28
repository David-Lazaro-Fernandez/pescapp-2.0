import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherService {
  final String _apiKey = '5b9d9297f4bdf81bbd70e0d4970f3da2'; // Replace with your OpenWeatherAPI key

  Future<Map<String, dynamic>?> getWeatherInLocation(double lat, double lon) async {
    final String url =
        'https://api.openweathermap.org/data/2.5/forecast?lat=$lat&lon=$lon&appid=$_apiKey&units=metric';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['list'] != null && data['list'].isNotEmpty) {
          final firstForecast = data['list'][0];
          final main = firstForecast['main'];
          final weather = firstForecast['weather']?[0];

          // Get the next 6 temperature readings for the chart
          final List<Map<String, dynamic>> hourlyTemps = [];
          for (var i = 0; i < 6 && i < data['list'].length; i++) {
            final forecast = data['list'][i];
            hourlyTemps.add({
              'temp': forecast['main']['temp'] ?? 0.0,
              'time': forecast['dt_txt'] ?? '',
            });
          }

          return {
            'temperature': main?['temp']?.toString() ?? 'N/A',
            'description': weather?['description'] ?? 'N/A',
            'humidity': main?['humidity']?.toString() ?? 'N/A',
            'wind_speed': firstForecast['wind']?['speed']?.toString() ?? 'N/A',
            'probability_of_rain': ((firstForecast['pop'] ?? 0) * 100).toStringAsFixed(0),
            'temp_min': main?['temp_min']?.toString() ?? 'N/A',
            'temp_max': main?['temp_max']?.toString() ?? 'N/A',
            'hourly_temps': hourlyTemps,
          };
        }
      }
      print('Failed to load weather data: ${response.statusCode}');
      return null;
    } catch (e) {
      print('Error fetching weather data: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> getWeatherData(double latitude, double longitude) async {
    final String url =
        'https://api.openweathermap.org/data/2.5/forecast?lat=$latitude&lon=$longitude&appid=$_apiKey';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to fetch weather data');
    }
  }

  void parseWeatherData(Map<String, dynamic> weatherData) {
    if (weatherData['list'] != null && weatherData['list'].isNotEmpty) {
      final firstForecast = weatherData['list'][0];

      final double probabilityOfRain = firstForecast['pop'] ?? 0.0;
      final int humidity = firstForecast['main']['humidity'] ?? 0;
      final double windSpeed = firstForecast['wind']['speed'] ?? 0.0;
      final double tempDay = firstForecast['main']['temp'] ?? 0.0;
      final double tempMin = firstForecast['main']['temp_min'] ?? 0.0;
      final double tempMax = firstForecast['main']['temp_max'] ?? 0.0;

      print('Probability of Rain: $probabilityOfRain');
      print('Humidity: $humidity');
      print('Wind Speed: $windSpeed');
      print('Day Temperature: $tempDay');
      print('Min Temperature: $tempMin');
      print('Max Temperature: $tempMax');
    } else {
      print('No forecast data available.');
    }
  }
} 