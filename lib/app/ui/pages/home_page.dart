// Imports originais do seu arquivo
import 'package:abaixaai/app/controller/measurement_controller.dart';
import 'package:abaixaai/app/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:abaixaai/app/ui/pages/webview_page.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Estrutura original da sua classe
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Variáveis originais do seu código
  final MeasurementController _measurementController = Get.put(
    MeasurementController(),
  );
  final Location _location = Location();
  LatLng? _currentLocation;
  List<Marker> _markers = [];

  // =======================================================================
  // INÍCIO: CÓDIGO MODIFICADO
  // A lógica de inicialização foi centralizada aqui para adicionar o diálogo com segurança.
  // =======================================================================
  @override
  void initState() {
    super.initState();
    // A função _getUserLocation foi substituída por esta nova função mais completa
    _initializePageAndPermissions();
  }

  Future<void> _initializePageAndPermissions() async {
    // Usamos WidgetsBinding para garantir que o contexto está pronto para um diálogo.
    // Isso evita o travamento que tivemos antes.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // 1. Mostra o diálogo de explicação que criamos
      await _showLocationExplanationDialog();

      // 2. A lógica original da sua função _getUserLocation começa aqui
      final hasPermission = await _location.requestPermission();
      if (hasPermission == PermissionStatus.granted) {
        //
        final locationData = await _location.getLocation();
        if (mounted) {
          // A lógica original do seu setState
          setState(() {
            _currentLocation = LatLng(
              locationData.latitude!,
              locationData.longitude!,
            );
          });
        }
      }

      // 3. A chamada original para _loadMeasurements, que estava no initState
      _loadMeasurements();
    });
  }
  // =======================================================================
  // FIM: CÓDIGO MODIFICADO
  // =======================================================================

  // =======================================================================
  // INÍCIO: CÓDIGO NOVO
  // Esta é a função que cria e mostra o alerta.
  // =======================================================================
  Future<void> _showLocationExplanationDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // O usuário precisa interagir com o diálogo
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1D38),
          title: const Text(
            'Permissão de Localização',
            style: TextStyle(color: Colors.white),
          ),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                  'Para exibir o mapa de ruído e mostrar os dados da sua região, nosso aplicativo precisa de acesso à sua localização.',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text(
                'OK, ENTENDI',
                style: TextStyle(color: Colors.blue),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
  // =======================================================================
  // FIM: CÓDIGO NOVO
  // =======================================================================

  // Sua função _loadMeasurements original, sem alterações
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

  // A função _getUserLocation original não é mais necessária, pois sua lógica
  // foi movida para dentro de _initializePageAndPermissions.

  // Seu método build original, sem nenhuma alteração
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
              colors: [Colors.black, Colors.blue], //
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        leading: Builder(
          builder:
              (context) => IconButton(
                //
                icon: const Icon(Icons.menu, color: Colors.white),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              ), //
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help, color: Colors.white),
            onPressed: () {
              //
              Get.to(
                () => const WebViewPage(
                  url: 'https://gabrielgomes191.github.io/AbaixaAI/#sobre', //
                  title: 'Github.io Abaixa Aí',
                ),
              );
            },
          ),
        ],
      ),
      drawer: Drawer(
        //
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black, Colors.blue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 35,
                      backgroundImage:
                          FirebaseAuth.instance.currentUser?.photoURL != null
                              ? NetworkImage(
                                FirebaseAuth.instance.currentUser!.photoURL!,
                              )
                              : const AssetImage(
                                    'assets/images/profile_placeholder.png',
                                  )
                                  as ImageProvider,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      FirebaseAuth.instance.currentUser?.displayName ??
                          'Usuário',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      FirebaseAuth.instance.currentUser?.email ?? '',
                      style: const TextStyle(color: Colors.blue, fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Dashboard'),
              onTap: () {
                //
                Navigator.pop(context); //
                Navigator.push(
                  //
                  context,
                  MaterialPageRoute(builder: (_) => const DashboardPage()),
                );
              },
            ),
            /*ListTile(
              leading: const Icon(Icons.article),
              title: const Text('Termos de Serviço'),
              onTap: () {
                Navigator.pop(context); //
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
              title: const Text('Notificações'), //
              onTap: () {
                Navigator.pop(context);
              },
            ),*/
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Sair'),
              onTap: () {
                FirebaseAuth.instance.signOut();
                Get.offAllNamed(
                  Routes.INITIAL,
                ); // Changed from Routes.LOGIN to Routes.INITIAL
              },
            ),
          ],
        ),
      ),
      body:
          _currentLocation == null
              ? const Center(
                //
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Carregando dados...",
                      style: TextStyle(
                        //
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ), //
                    ),
                    SizedBox(
                      height: 10, //
                    ),
                    CircularProgressIndicator(),
                  ],
                ),
              )
              : FlutterMap(
                options: MapOptions(
                  //
                  initialCenter: _currentLocation ?? LatLng(0, 0),
                  minZoom: 13.0,
                ),
                children: [
                  TileLayer(
                    //
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  ),
                  CircleLayer(
                    circles:
                        _markers.map((marker) {
                          //
                          Color circleColor;
                          if (5 < 50) {
                            //
                            circleColor = Colors.green.withOpacity(
                              0.3,
                            ); // Baixo ruído
                          } else if (50 >= 50 && 50 < 70) {
                            circleColor = Colors.yellow.withOpacity(
                              0.3,
                            ); // Médio ruído
                          } else {
                            circleColor = Colors.red.withOpacity(
                              0.3,
                            ); // Alto ruído
                          }

                          return CircleMarker(
                            point: marker.point,
                            color: circleColor, //
                            radius: 50,
                          );
                        }).toList(), //
                  ),
                  MarkerLayer(
                    markers: [
                      if (_currentLocation != null) //
                        Marker(
                          point: _currentLocation!,
                          child: Icon(
                            Icons.location_on, //
                            color: Colors.red,
                            size: 50,
                          ), //
                        ),
                      ..._markers.map((marker) {
                        return Marker(
                          //
                          point: marker.point,
                          child: GestureDetector(
                            onTap: () {
                              //
                              showDialog(
                                //
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    //
                                    content: Container(
                                      decoration: const BoxDecoration(
                                        gradient: LinearGradient(
                                          //
                                          colors: [Colors.black, Colors.blue],
                                          begin: Alignment.topLeft, //
                                          end: Alignment.bottomRight,
                                        ), //
                                        borderRadius: BorderRadius.all(
                                          Radius.circular(16),
                                        ), //
                                      ),
                                      child: Padding(
                                        //
                                        padding: const EdgeInsets.all(16.0),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min, //
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start, //
                                          children: [
                                            Text(
                                              //
                                              'Informações do Local',
                                              style: TextStyle(
                                                //
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold, //
                                                fontSize: 18,
                                              ),
                                            ), //
                                            SizedBox(height: 16),
                                            Text(
                                              //
                                              'Latitude:',
                                              style: TextStyle(
                                                //
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold, //
                                              ),
                                            ), //
                                            Text(
                                              'Valor da latitude aqui', //
                                              style: TextStyle(
                                                color: Colors.white, //
                                              ),
                                            ),
                                            SizedBox(height: 8), //
                                            Text(
                                              'Longitude:', //
                                              style: TextStyle(
                                                color: Colors.white, //
                                                fontWeight: FontWeight.bold,
                                              ), //
                                            ),
                                            Text(
                                              'Valor da longitude aqui', //
                                              style: TextStyle(
                                                color: Colors.white, //
                                              ),
                                            ), //
                                            SizedBox(height: 8),
                                            Text(
                                              //
                                              'Última atualização:',
                                              style: TextStyle(
                                                //
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold, //
                                              ),
                                            ), //
                                            Text(
                                              'Data e hora aqui', //
                                              style: TextStyle(
                                                color: Colors.white,
                                              ), //
                                            ),
                                            SizedBox(height: 16), //
                                            Align(
                                              alignment:
                                                  Alignment.centerRight, //
                                              child: TextButton(
                                                onPressed:
                                                    () => //
                                                        Navigator.of(
                                                          context,
                                                        ).pop(), //
                                                child: Text(
                                                  'Fechar', //
                                                  style: TextStyle(
                                                    color: Colors.white, //
                                                  ),
                                                ), //
                                              ),
                                            ), //
                                          ],
                                        ), //
                                      ),
                                    ),
                                    backgroundColor: Colors.transparent, //
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        16,
                                      ), //
                                    ),
                                  );
                                }, //
                              );
                            },
                            child: Icon(
                              Icons.volume_up,
                              color: Colors.red,
                              size: 50, //
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ],
              ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
        child: const Icon(Icons.speed, color: Colors.white), //
        onPressed: () async {
          // Navigate to the measurement page and wait for it to be popped
          await Get.toNamed(Routes.MEASUREMENT_PAGE);
          // Once returned, reload the measurements
          _loadMeasurements();
        },
      ),
    );
  } //
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override //
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
              //
              // Adicione a navegação ou ação desejada aqui.
            },
          ),
          ListTile(
            leading: const Icon(Icons.warning),
            title: const Text('Focos de barulho'),
            onTap: () {
              //
              // Adicione a navegação ou ação desejada aqui.
            },
          ),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('Informações'),
            onTap: () {
              //
              // Adicione a navegação ou ação desejada aqui.
            },
          ),
        ],
      ),
    );
  } //
}
