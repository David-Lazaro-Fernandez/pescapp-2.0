import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:pescapp/widgets/base_layout.dart';
import 'package:pescapp/services/firebase_service.dart';
import 'package:pescapp/services/weather_service.dart';
import 'package:pescapp/services/google_maps_service.dart';
import 'package:pescapp/services/location_service.dart';

class DashboardPage extends StatelessWidget {
  final GoogleMapsService _googleMapsService = GoogleMapsService();
  final WeatherService _weatherService = WeatherService();
  final LocationService _locationService = LocationService();

  Future<Map<String, dynamic>> _fetchData() async {
    try {
      // Obtener ubicación actual
      final position = await _locationService.getCurrentLocation();
      final latitude = position.latitude;
      final longitude = position.longitude;

      // Fetch location name
      String locationName = await _googleMapsService.getLocationName(latitude, longitude);

      // Fetch weather data
      final weatherData = await _weatherService.getWeatherInLocation(latitude, longitude);
      
      if (weatherData == null) {
        throw Exception('No se pudieron obtener datos del clima');
      }

      return {
        'locationName': locationName,
        'weatherData': weatherData,
      };
    } catch (e) {
      print('Error fetching data: $e');
      return {
        'locationName': 'Ubicación no disponible',
        'weatherData': null,
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseLayout(
      currentIndex: 0,
      child: SafeArea(
        child: FutureBuilder<Map<String, dynamic>>(
          future: _fetchData(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!['weatherData'] == null) {
              return Center(child: Text('No hay datos disponibles'));
            }

            final data = snapshot.data!;
            final locationName = data['locationName'];
            final weatherData = data['weatherData'];

            return Column(
              children: [
                HeaderSection(),
                WeatherSection(
                  locationName: locationName,
                  weatherData: weatherData,
                ),
                MessageHistorySection(),
              ],
            );
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
  final String locationName;
  final Map<String, dynamic> weatherData;

  const WeatherSection({
    super.key,
    required this.locationName,
    required this.weatherData,
  });

  String _formatDate() {
    final now = DateTime.now();
    final days = ['Dom.', 'Lun.', 'Mar.', 'Mie.', 'Jue.', 'Vie.', 'Sab.'];
    final months = ['Ene.', 'Feb.', 'Mar.', 'Abr.', 'May.', 'Jun.', 'Jul.', 'Ago.', 'Sep.', 'Oct.', 'Nov.', 'Dic.'];
    return '${days[now.weekday % 7]} ${now.day} ${months[now.month - 1]} ${now.year}';
  }

  List<FlSpot> _convertToSpots(List<dynamic> hourlyTemps) {
    return List<FlSpot>.generate(
      hourlyTemps.length,
      (index) => FlSpot(
        index.toDouble(),
        double.parse(hourlyTemps[index]['temp'].toString()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Convertir los datos de temperatura a FlSpot
    final List<dynamic> hourlyTemps = weatherData['hourly_temps'] ?? [];
    final spots = _convertToSpots(hourlyTemps);

    return Container(
      color: const Color.fromARGB(255, 255, 255, 255),
      padding: const EdgeInsets.all(24.0),
      child: Column(
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
          WeatherChart(spots: spots),
        ],
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