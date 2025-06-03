import 'package:abaixaai/app/controller/home_controller.dart';
import 'package:abaixaai/app/controller/measurement_controller.dart';
import 'package:abaixaai/app/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:abaixaai/app/ui/pages/webview_page.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final HomeController _homeController = Get.put(HomeController());
  final MeasurementController _measurementController = Get.put(
    MeasurementController(),
  );
  final Location _location = Location();
  LatLng? _currentLocation;
  List<Marker> _markers = [];

  @override
  void initState() {
    super.initState();
    _getUserLocation();
    _loadMeasurements();
  }

  Future<void> _loadMeasurements() async {
    final measurements = await _measurementController.fetchMeasurements();
    setState(() {
      _markers =
          measurements.map((measurement) {
            return Marker(
              point: LatLng(measurement['latitude'], measurement['longitude']),
              child: const Icon(Icons.location_on, color: Colors.red, size: 30),
            );
          }).toList();
    });
  }

  Future<void> _getUserLocation() async {
    final hasPermission = await _location.requestPermission();
    if (hasPermission == PermissionStatus.granted) {
      final locationData = await _location.getLocation();
      setState(() {
        _currentLocation = LatLng(
          locationData.latitude!,
          locationData.longitude!,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text("Abaixa Aí"),
        backgroundColor: Colors.black,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.black, Colors.blue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        // Use Builder to access the Scaffold context for opening the drawer
        leading: Builder(
          builder:
              (context) => IconButton(
                icon: const Icon(Icons.menu, color: Colors.white),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help, color: Colors.white),
            onPressed: () {
              Get.to(
                () => const WebViewPage(
                  url: 'https://gabrielgomes191.github.io/AbaixaAI/#sobre',
                  title: 'Github.io Abaixa Aí',
                ),
              );
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.blue),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircleAvatar(
                    radius: 40,
                    // Replace with your profile placeholder asset path if available
                    backgroundImage: AssetImage(
                      'assets/images/profile_placeholder.png',
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Usuário',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Dashboard'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DashboardPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.article),
              title: const Text('Termos de Serviço'),
              onTap: () {
                // Navigate to Terms of Service
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.payment),
              title: const Text('Pagamentos'),
              onTap: () {
                // Navigate to Payments page
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text('Notificações'),
              onTap: () {
                // Navigate to Notifications page
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
      body:
          _currentLocation == null
              ? const Center(child: CircularProgressIndicator())
              : FlutterMap(
                options: MapOptions(
                  initialCenter: _currentLocation ?? LatLng(0, 0),
                  minZoom: 13.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                    subdomains: ['a', 'b', 'c'],
                  ),
                  MarkerLayer(
                    markers: [
                      // Marcador para a localização atual
                      if (_currentLocation != null)
                        Marker(
                          point: _currentLocation!,
                          child: Container(
                            width: 50, // Tamanho do marcador
                            height: 50, // Tamanho do marcador
                            decoration: BoxDecoration(
                              color: Colors.red, // Cor vermelha
                              shape: BoxShape.circle, // Formato circular
                            ),
                          ),
                        ),
                      // Marcadores existentes
                      ..._markers.map((marker) {
                        return Marker(
                          point: marker.point,
                          child: GestureDetector(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: Text('Informações do Local'),
                                    content: Text('Nome: \nDescrição: '),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                        child: const Text('Fechar'),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                            child: Container(
                              width: 40, // Tamanho do marcador
                              height: 40, // Tamanho do marcador
                              decoration: BoxDecoration(
                                color: Colors.blue, // Cor azul
                                shape: BoxShape.circle, // Formato circular
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ],
              ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
        child: const Icon(Icons.speed, color: Colors.white),
        onPressed: () {
          Get.toNamed(Routes.MEASUREMENT_PAGE);
        },
      ),
    );
  }
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: Colors.blue,
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.report),
            title: const Text('Minhas Denúcias'),
            onTap: () {
              // Adicione a navegação ou ação desejada aqui.
            },
          ),
          ListTile(
            leading: const Icon(Icons.warning),
            title: const Text('Focos de barulho'),
            onTap: () {
              // Adicione a navegação ou ação desejada aqui.
            },
          ),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('Informações'),
            onTap: () {
              // Adicione a navegação ou ação desejada aqui.
            },
          ),
        ],
      ),
    );
  }
}
