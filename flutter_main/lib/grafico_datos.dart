import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:fl_chart/fl_chart.dart';

class DataPage extends StatefulWidget {
  final BluetoothDevice? device;

  const DataPage({super.key, this.device});

  @override
  State<DataPage> createState() => _DataPageState();
}

class _DataPageState extends State<DataPage> {
  final List<double> humedad = [];
  final List<double> conductividad = [];
  final List<double> ph = [];
  final List<double> temperatura = [];

  @override
  void initState() {
    super.initState();
    if (widget.device != null) {
      _connectToDevice();
    }
  }

  Future<void> _connectToDevice() async {
    var services = await widget.device!.discoverServices();
    for (var service in services) {
      for (var characteristic in service.characteristics) {
        if (characteristic.properties.notify) {
          await characteristic.setNotifyValue(true);
          characteristic.value.listen((value) {
            final data = String.fromCharCodes(value);
            print("📡 Recibido: $data");
            _processData(data);
          });
        }
      }
    }
  }

  void _processData(String data) {
    try {
      final parts = data.split(",");
      if (parts.length < 4) return;

      setState(() {
        humedad.add(double.tryParse(parts[0].split(":")[1]) ?? 0);
        conductividad.add(double.tryParse(parts[1].split(":")[1]) ?? 0);
        ph.add(double.tryParse(parts[2].split(":")[1]) ?? 0);
        temperatura.add(double.tryParse(parts[3].split(":")[1]) ?? 0);

        if (humedad.length > 10) {
          humedad.removeAt(0);
          conductividad.removeAt(0);
          ph.removeAt(0);
          temperatura.removeAt(0);
        }
      });
    } catch (e) {
      print("⚠️ Error al procesar datos: $e");
    }
  }

  LineChartData _buildChart(String label, List<double> data, Color color) {
    return LineChartData(
      lineBarsData: [
        LineChartBarData(
          spots: List.generate(data.length, (i) => FlSpot(i.toDouble(), data[i])),
          isCurved: true,
          barWidth: 3,
          color: color,
          dotData: const FlDotData(show: false),
        ),
      ],
      titlesData: const FlTitlesData(show: false),
      gridData: const FlGridData(show: false),
      borderData: FlBorderData(show: false),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Datos en tiempo real")),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildCard("Humedad (%)", humedad, Colors.blue),
            _buildCard("Conductividad (µS/cm)", conductividad, Colors.green),
            _buildCard("pH", ph, Colors.orange),
            _buildCard("Temperatura (°C)", temperatura, Colors.red),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(String title, List<double> data, Color color) {
    return Card(
      margin: const EdgeInsets.all(12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(
              height: 200,
              child: data.isEmpty
                  ? const Center(child: Text("Esperando datos..."))
                  : LineChart(_buildChart(title, data, color)),
            ),
          ],
        ),
      ),
    );
  }
}
