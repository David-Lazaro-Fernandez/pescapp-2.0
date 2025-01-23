import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:pescapp/widgets/base_layout.dart';
import 'package:pescapp/services/firebase_service.dart';
import 'package:pescapp/widgets/google_map_widget.dart';


class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseLayout(
      currentIndex: 0,  // Because Dashboard is the home screen
      child: SafeArea(
        child: Column(
          children: [
            HeaderSection(),
            WeatherSection(),
            Expanded(child: GoogleMapWidget()),
            MessageHistorySection(),
          ],
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
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Buenos días, Miguel',
            style: TextStyle(
              fontSize: 32, // equivalent to text-4xl
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0E0E0E),
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

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFBFBFB),
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
                  Text(
                    'Chiltepec',
                    style: TextStyle(
                      fontSize: 24, // equivalent to text-2xl
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0E0E0E),
                    ),
                  ),
                  Text(
                    'Mie. 22 Ago. 2023',
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
                    '34°C',
                    style: TextStyle(
                      fontSize: 48, // equivalent to text-6xl
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1B67E0),
                    ),
                  ),
                  Text(
                    'Día soleado',
                    style: TextStyle(
                      color: const Color(0xFFA8A8A8),
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  WeatherStatRow(label: 'Prob. de lluvia:', value: '23%'),
                  WeatherStatRow(label: 'Humedad:', value: '62%'),
                  WeatherStatRow(label: 'Viento:', value: '16 km/h'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          WeatherChart(),
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
  const WeatherChart({super.key});

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
              spots: [
                FlSpot(0, 25),
                FlSpot(2, 27),
                FlSpot(4, 30),
                FlSpot(6, 34),
                FlSpot(8, 32),
                FlSpot(10, 28),
              ],
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
        margin: const EdgeInsets.all(16.0),
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