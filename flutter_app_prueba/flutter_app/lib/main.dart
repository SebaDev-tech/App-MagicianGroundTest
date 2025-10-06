import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'dart:typed_data';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: BluetoothPage(),
    );
  }
}

class BluetoothPage extends StatefulWidget {
  const BluetoothPage({super.key});

  @override
  State<BluetoothPage> createState() => _BluetoothPageState();
}

class _BluetoothPageState extends State<BluetoothPage> {
  BluetoothConnection? connection;
  bool isConnected = false;
  String receivedData = "";

  // Escanear dispositivos emparejados
  Future<List<BluetoothDevice>> getBondedDevices() async {
    return await FlutterBluetoothSerial.instance.getBondedDevices();
  }

  // Conectar al HC-06
  void connectToDevice(BluetoothDevice device) async {
    try {
      connection = await BluetoothConnection.toAddress(device.address);
      setState(() {
        isConnected = true;
      });

      connection!.input!.listen((Uint8List data) {
        setState(() {
          receivedData += String.fromCharCodes(data);
        });
      }).onDone(() {
        setState(() {
          isConnected = false;
        });
      });
    } catch (e) {
      debugPrint("Error al conectar: $e");
    }
  }

  @override
  void dispose() {
    connection?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Bluetooth HC-06")),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: () async {
              List<BluetoothDevice> devices = await getBondedDevices();
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Selecciona un dispositivo"),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: devices.map((device) {
                      return ListTile(
                        title: Text(device.name ?? "Desconocido"),
                        subtitle: Text(device.address),
                        onTap: () {
                          Navigator.pop(context);
                          connectToDevice(device);
                        },
                      );
                    }).toList(),
                  ),
                ),
              );
            },
            child: const Text("Conectar a HC-06"),
          ),
          const SizedBox(height: 20),
          Text(
            isConnected ? "Conectado ✅" : "Desconectado ❌",
            style: TextStyle(
              fontSize: 18,
              color: isConnected ? Colors.green : Colors.red,
            ),
          ),
          const Divider(),
          Expanded(
            child: SingleChildScrollView(
              child: Text(
                receivedData,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
