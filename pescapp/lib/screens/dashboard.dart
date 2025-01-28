import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:pescapp/widgets/base_layout.dart';
import 'package:pescapp/services/firebase_service.dart';
import 'package:pescapp/services/weather_service.dart';
import 'package:pescapp/services/google_maps_service.dart';

class DashboardPage extends StatelessWidget {
  final GoogleMapsService _googleMapsService = GoogleMapsService();
  final WeatherService _weatherService = WeatherService();

  Future<Map<String, dynamic>> _fetchData() async {
    // Replace with actual coordinates
    double latitude = 37.7749;
    double longitude = -122.4194;

    // Fetch location name
    String locationName = await _googleMapsService.getLocationName(latitude, longitude);

    // Fetch weather data
    Map<String, dynamic> weatherData = await _weatherService.getWeatherData(latitude, longitude);

    // Parse weather data
    _weatherService.parseWeatherData(weatherData);

    return {
      'locationName': locationName,
      'weatherData': weatherData,
    };
  }

  @override
  Widget build(BuildContext context) {
    return BaseLayout(
      currentIndex: 0,  // Because Dashboard is the home screen
      child: SafeArea(
        child: FutureBuilder<Map<String, dynamic>>(
          future: _fetchData(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData) {
              return Center(child: Text('No data available'));
            } else {
              final data = snapshot.data!;
              final locationName = data['locationName'];
              final weatherData = data['weatherData'];

              return Column(
                children: [
                  HeaderSection(),
                  WeatherSection(),
                  MessageHistorySection(),
                ],
              );
            }
          },
        ),
      ),
    );
  }
}

class HeaderSection extends StatelessWidget {
  const HeaderSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 1.0, right: 1.0, top: 25.0 ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Buenos días, Miguel',
            style: TextStyle(
              fontSize: 32, // equivalent to text-4xl
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0E0E0E),
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '¡Hoy habrá mucho viento!',
            style: TextStyle(
              fontSize: 20, // equivalent to text-xl
              color: const Color(0xFFA8A8A8),
            ),
          ),
        ],
      ),
    );
  }
}

class WeatherSection extends StatelessWidget {
  const WeatherSection({super.key});

  String _formatDate() {
    final now = DateTime.now();
    final days = ['Dom.', 'Lun.', 'Mar.', 'Mie.', 'Jue.', 'Vie.', 'Sab.'];
    final months = ['Ene.', 'Feb.', 'Mar.', 'Abr.', 'May.', 'Jun.', 'Jul.', 'Ago.', 'Sep.', 'Oct.', 'Nov.', 'Dic.'];
    return '${days[now.weekday % 7]} ${now.day} ${months[now.month - 1]} ${now.year}';
  }

  @override
  Widget build(BuildContext context) {
    final WeatherService weatherService = WeatherService();
    final GoogleMapsService googleMapsService = GoogleMapsService();
    final double latitude = 18.293232;
    final double longitude = -93.863316;

    return Container(
      color: const Color.fromARGB(255, 255, 255, 255),
      padding: const EdgeInsets.all(24.0),
      child: FutureBuilder<Map<String, dynamic>>(
        future: Future.wait([
          googleMapsService.getLocationName(latitude, longitude),
          weatherService.getWeatherInLocation(latitude, longitude),
        ]).then((results) => {
          'locationName': results[0],
          'weatherData': results[1],
        }),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError || snapshot.data == null) {
            return Center(child: Text('Error fetching data'));
          }

          final locationName = snapshot.data!['locationName'] as String;
          final weatherData = snapshot.data!['weatherData'] as Map<String, dynamic>?;

          if (weatherData == null) {
            return Center(child: Text('No weather data available'));
          }

          // Get hourly temperatures for the chart
          final hourlyTemps = (weatherData['hourly_temps'] as List<Map<String, dynamic>>)
              .asMap()
              .entries
              .map((entry) => FlSpot(
                    entry.key.toDouble(),
                    double.parse(entry.value['temp'].toString()),
                  ))
              .toList();

          return Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.6,
                        child: Text(
                          locationName,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF0E0E0E),
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                      ),
                      Text(
                        _formatDate(),
                        style: TextStyle(
                          color: const Color(0xFFA8A8A8),
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    Icons.wb_sunny,
                    size: 32,
                    color: const Color(0xFF1B67E0),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${weatherData['temperature']}°C',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1B67E0),
                        ),
                      ),
                      Text(
                        weatherData['description'],
                        style: TextStyle(
                          color: const Color(0xFFA8A8A8),
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      WeatherStatRow(
                        label: 'Prob. de lluvia:',
                        value: '${weatherData['probability_of_rain']}%',
                      ),
                      WeatherStatRow(
                        label: 'Humedad:',
                        value: '${weatherData['humidity']}%',
                      ),
                      WeatherStatRow(
                        label: 'Viento:',
                        value: '${weatherData['wind_speed']} km/h',
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              WeatherChart(spots: hourlyTemps),
            ],
          );
        },
      ),
    );
  }
}

class WeatherStatRow extends StatelessWidget {
  final String label;
  final String value;

  const WeatherStatRow({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '$label ',
          style: TextStyle(
            color: const Color(0xFFA8A8A8),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: const Color(0xFF1B67E0),
          ),
        ),
      ],
    );
  }
}

class WeatherChart extends StatelessWidget {
  final List<FlSpot> spots;

  const WeatherChart({
    super.key,
    required this.spots,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: const Color(0xFF1B67E0),
              barWidth: 3,
              dotData: FlDotData(show: false),
            ),
          ],
        ),
      ),
    );
  }
}

class MessageHistorySection extends StatelessWidget {
  const MessageHistorySection({super.key});

  @override
  Widget build(BuildContext context) {
    final FirebaseService firebaseService = FirebaseService();

    return Expanded(
      child: Card(
        color: Colors.grey[100],
        margin: const EdgeInsets.only(left: 1.0, right: 1.0, top: 1.0 ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Historial de mensajes',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: firebaseService.getBoats(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(child: Text('No boats found.'));
                  } else {
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('# Mensaje')),
                          DataColumn(label: Text('Estado')),
                          DataColumn(label: Text('Hora')),
                        ],
                        rows: snapshot.data!.map((boat) {
                          return DataRow(cells: [
                            DataCell(Text(boat['id'] ?? 'N/A')),
                            DataCell(Text(boat['status'] ?? 'N/A')),
                            DataCell(Text(boat['time'] ?? 'N/A')),
                          ]);
                        }).toList(),
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
} 