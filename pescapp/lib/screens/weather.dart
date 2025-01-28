import 'package:flutter/material.dart';
import 'package:pescapp/widgets/base_layout.dart';
import 'package:pescapp/services/weather_service.dart';
import 'package:pescapp/services/google_maps_service.dart';
import 'package:fl_chart/fl_chart.dart';

class WeatherScreen extends StatelessWidget {
  final WeatherService _weatherService = WeatherService();
  final GoogleMapsService _googleMapsService = GoogleMapsService();

  @override
  Widget build(BuildContext context) {
    return BaseLayout(
      currentIndex: 1, // Weather tab index
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Pronóstico del día',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0E0E0E),
                    fontFamily: 'Inter',
                  ),
                ),
              ),
              // Weather Content
              FutureBuilder<Map<String, dynamic>>(
                future: _loadWeatherData(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError || snapshot.data == null) {
                    return Center(child: Text('Error al cargar el clima'));
                  }

                  final weatherData = snapshot.data!;
                  final locationName = weatherData['locationName'] as String;
                  final forecast = weatherData['weatherData'] as Map<String, dynamic>;
                  final hourlyTemps = forecast['hourly_temps'] as List<Map<String, dynamic>>;

                  return Column(
                    children: [
                      // Location and Current Weather
                      CurrentWeatherCard(
                        locationName: locationName,
                        temperature: forecast['temperature'],
                        description: forecast['description'],
                        humidity: forecast['humidity'],
                        windSpeed: forecast['wind_speed'],
                        probabilityOfRain: forecast['probability_of_rain'],
                      ),
                      // Hourly Timeline
                      Container(
                        height: 180,
                        padding: EdgeInsets.all(16),
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: hourlyTemps.length,
                          itemBuilder: (context, index) {
                            final hourData = hourlyTemps[index];
                            return HourlyWeatherCard(
                              time: _formatTime(hourData['time']),
                              temperature: hourData['temp'].toString(),
                            );
                          },
                        ),
                      ),
                      // Temperature Chart
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Container(
                          height: 200,
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: EdgeInsets.all(16),
                          child: WeatherChart(
                            spots: hourlyTemps
                                .asMap()
                                .entries
                                .map((entry) => FlSpot(
                                      entry.key.toDouble(),
                                      double.parse(entry.value['temp'].toString()),
                                    ))
                                .toList(),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<Map<String, dynamic>> _loadWeatherData() async {
    final double latitude = 18.293232;
    final double longitude = -93.863316;

    final locationName = await _googleMapsService.getLocationName(latitude, longitude);
    final weatherData = await _weatherService.getWeatherInLocation(latitude, longitude);

    return {
      'locationName': locationName,
      'weatherData': weatherData,
    };
  }

  String _formatTime(String dateTimeStr) {
    final dateTime = DateTime.parse(dateTimeStr);
    return '${dateTime.hour}:00';
  }
}

class CurrentWeatherCard extends StatelessWidget {
  final String locationName;
  final String temperature;
  final String description;
  final String humidity;
  final String windSpeed;
  final String probabilityOfRain;

  const CurrentWeatherCard({
    required this.locationName,
    required this.temperature,
    required this.description,
    required this.humidity,
    required this.windSpeed,
    required this.probabilityOfRain,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(16),
      color: Colors.grey[100],
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              locationName,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$temperature°C',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1B67E0),
                      ),
                    ),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    WeatherStatRow(label: 'Lluvia:', value: '$probabilityOfRain%'),
                    WeatherStatRow(label: 'Humedad:', value: '$humidity%'),
                    WeatherStatRow(label: 'Viento:', value: '$windSpeed km/h'),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class HourlyWeatherCard extends StatelessWidget {
  final String time;
  final String temperature;

  const HourlyWeatherCard({
    required this.time,
    required this.temperature,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(right: 8),
      color: Colors.grey[100],
      child: Container(
        width: 80,
        padding: EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              time,
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Icon(
              Icons.wb_sunny,
              color: const Color(0xFF1B67E0),
            ),
            SizedBox(height: 8),
            Text(
              '$temperature°C',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WeatherStatRow extends StatelessWidget {
  final String label;
  final String value;

  const WeatherStatRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(
            '$label ',
            style: TextStyle(
              color: Colors.grey[100],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1B67E0),
            ),
          ),
        ],
      ),
    );
  }
}

class WeatherChart extends StatelessWidget {
  final List<FlSpot> spots;

  const WeatherChart({required this.spots});

  @override
  Widget build(BuildContext context) {
    return LineChart(
      LineChartData(
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text('${value.toInt()}:00');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text('${value.toInt()}°');
              },
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: const Color(0xFF1B67E0),
            barWidth: 3,
            dotData: FlDotData(show: true),
          ),
        ],
      ),
    );
  }
} 