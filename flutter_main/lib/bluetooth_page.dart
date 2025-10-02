import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Bluetooth Conexión Cimple',
      theme: ThemeData(primarySwatch: Colors.green),
      home: const BluetoothPage(),
    );
  }
}

class BluetoothPage extends StatefulWidget {
  const BluetoothPage({super.key});

  @override
  State<BluetoothPage> createState() => _BluetoothPageState();
}

class _BluetoothPageState extends State<BluetoothPage> {
  final List<ScanResult> _devices = [];
  BluetoothDevice? _connectedDevice;
  List<BluetoothService> _services = [];

  @override
  void initState() {
    super.initState();
    _checkPermissionsAndStartScan();
  }

  // Pedir permisos
  Future<void> _checkPermissionsAndStartScan() async {
    var scanPermission = await Permission.bluetoothScan.request();
    var connectPermission = await Permission.bluetoothConnect.request();
    var locationPermission = await Permission.locationWhenInUse.request();

    if (scanPermission.isGranted &&
        connectPermission.isGranted &&
        locationPermission.isGranted) {
      _startScan();
    } else {
      debugPrint("Permisos denegados");
    }
  }

  // Escanear dispositivos
  void _startScan() {
    _devices.clear();
    FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));

    FlutterBluePlus.scanResults.listen((results) {
      setState(() {
        _devices.clear();
        _devices.addAll(results);
      });
    });
  }

  //Conectar a un dispositivo
  Future<void> _connectToDevice(BluetoothDevice device) async {
    try {
      await device.connect(autoConnect: false);
      setState(() {
        _connectedDevice = device;
      });

      // Descubrir servicios
      final services = await device.discoverServices();
      setState(() {
        _services = services;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Conectado a ${device.name}")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al conectar: $e")),
      );
    }
  }

  // Desconectar
  Future<void> _disconnect() async {
    if (_connectedDevice != null) {
      await _connectedDevice!.disconnect();
      setState(() {
        _connectedDevice = null;
        _services.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Dispositivo desconectado")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Bluetooth Escaneo y Conexiones"),
        actions: [
          if (_connectedDevice == null)
            IconButton(icon: const Icon(Icons.refresh), onPressed: _startScan),
          if (_connectedDevice != null)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _disconnect,
            ),
        ],
      ),
      body: _connectedDevice == null
          ? _devices.isEmpty
              ? const Center(child: Text("Buscando dispositivos..."))
              : ListView.builder(
                  itemCount: _devices.length,
                  itemBuilder: (context, index) {
                    final result = _devices[index];
                    final device = result.device;
                    return ListTile(
                      leading: const Icon(Icons.bluetooth),
                      title: Text(device.name.isNotEmpty
                          ? device.name
                          : "Sin nombre"),
                      subtitle: Text("ID: ${device.id}"),
                      trailing: ElevatedButton(
                        onPressed: () => _connectToDevice(device),
                        child: const Text("Conectar"),
                      ),
                    );
                  },
                )
          : ListView(
              children: [
                ListTile(
                  title: Text("Conectado a: ${_connectedDevice!.name}"),
                  subtitle: Text("ID: ${_connectedDevice!.id}"),
                ),
                const Divider(),
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text("Servicios descubiertos:",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                ..._services.map((s) => ListTile(
                      title: Text("UUID: ${s.uuid}"),
                      subtitle:
                          Text("Características: ${s.characteristics.length}"),
                    )),
              ],
            ),
    );
  }
}
