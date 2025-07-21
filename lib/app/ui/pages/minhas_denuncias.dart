import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MyReportsPage extends StatelessWidget {
  Future<List<Map<String, dynamic>>> fetchUserReports() async {
    final userEmail = FirebaseAuth.instance.currentUser?.email;

    if (userEmail == null) {
      throw Exception('Usuário não está logado.');
    }

    List<Map<String, dynamic>> allReports = [];

    // 1. Fetch ALL documents from the 'denuncias' collection
    // We no longer filter by 'createdAt' at this level, as per your new requirement.
    final mainCollectionSnapshot =
        await FirebaseFirestore.instance.collection('denuncias').get();

    for (var doc in mainCollectionSnapshot.docs) {
      final data = doc.data();

      // Check if the main 'denuncia' itself was created by the user
      if (data['createdAt'] == userEmail) {
        final timestamp = data['timestamp'] as Timestamp?;
        DateTime? dateTime;

        if (timestamp != null) {
          // Use the timestamp as-is without timezone adjustment
          dateTime = timestamp.toDate();
        }

        allReports.add({...data, 'timestamp': dateTime});
      }

      // 2. Always fetch documents from the 'sub_denuncias' subcollection for each main document
      // AND apply the 'createdAt' filter for the user's email here.
      final subReportsQuerySnapshot =
          await doc.reference
              .collection('sub_denuncias')
              .where('createdAt', isEqualTo: userEmail)
              .get();

      for (var subDoc in subReportsQuerySnapshot.docs) {
        final subData = subDoc.data();
        final subTimestamp = subData['timestamp'] as Timestamp?;
        DateTime? subDateTime;

        if (subTimestamp != null) {
          // Use the timestamp as-is without timezone adjustment
          subDateTime = subTimestamp.toDate();
        }

        allReports.add({...subData, 'timestamp': subDateTime});
      }
    }

    // Manually sort all reports by timestamp in descending order (most recent first).
    allReports.sort((a, b) {
      final timestampA = a['timestamp'] as DateTime?;
      final timestampB = b['timestamp'] as DateTime?;

      // Handle null timestamps by placing them at the end.
      if (timestampA == null && timestampB == null) return 0;
      if (timestampA == null) return 1; // b is not null, so b comes before a
      if (timestampB == null) return -1; // a is not null, so a comes before b
      return timestampB.compareTo(timestampA); // Sort in descending order
    });

    return allReports;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Minhas Denúncias',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        // Apply a gradient background to the AppBar for a consistent look.
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.black, Colors.blue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        iconTheme: const IconThemeData(
          color: Colors.white,
        ), // Set back button color to white
      ),
      // Apply a subtle background color to the body.
      body: Container(
        color: Colors.blue.shade50, // Light blue background
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: fetchUserReports(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              // Display a more prominent error message.
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 50,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Erro ao carregar denúncias: ${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Optionally, add a button to retry fetching data
                      ElevatedButton.icon(
                        onPressed: () {
                          // You might need a way to re-trigger the FutureBuilder
                          // A common approach is to make MyReportsPage a StatefulWidget
                          // and call setState, or use a GetX controller and update.
                          // For simplicity in StatelessWidget, the user would need to navigate back and forth.
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Tentar Novamente'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              // Display a more engaging message for no reports found.
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: Colors.blueGrey,
                        size: 60,
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Nenhuma denúncia encontrada.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueGrey,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Parece que você ainda não fez nenhuma denúncia. Use o mapa na tela inicial para registrar o ruído ao seu redor!',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              );
            }

            final reports = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(
                16.0,
              ), // Add padding around the list
              itemCount: reports.length,
              itemBuilder: (context, index) {
                final report = reports[index];
                final timestamp = report['timestamp'] as DateTime?;
                final formattedTimestamp =
                    timestamp != null
                        ? '${timestamp.day.toString().padLeft(2, '0')}/${timestamp.month.toString().padLeft(2, '0')}/${timestamp.year} ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}'
                        : 'Data inválida';

                return Card(
                  margin: const EdgeInsets.symmetric(
                    vertical: 8.0,
                  ), // Spacing between cards
                  elevation: 5, // Add a subtle shadow
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      15.0,
                    ), // Rounded corners for cards
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white,
                          Colors.blue.shade50,
                        ], // Subtle gradient for card background
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                color: Colors.blue,
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Localização:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.blue.shade800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                              left: 32.0,
                              top: 4.0,
                            ),
                            child: Text(
                              'Latitude: ${report['latitude']?.toStringAsFixed(6) ?? 'N/A'}', // Format latitude
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 32.0),
                            child: Text(
                              'Longitude: ${report['longitude']?.toStringAsFixed(6) ?? 'N/A'}', // Format longitude
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(
                                Icons.calendar_today,
                                color: Colors.blue,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Data da Denúncia:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.blue.shade800,
                                ),
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                              left: 32.0,
                              top: 4.0,
                            ),
                            child: Text(
                              formattedTimestamp,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          // You can add more details from your report data here, e.g., noise level
                          if (report.containsKey(
                            'noiseLevel',
                          )) // Assuming you might have a 'noiseLevel' field
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.volume_up,
                                      color: Colors.blue,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Nível de Ruído:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Colors.blue.shade800,
                                      ),
                                    ),
                                  ],
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(
                                    left: 32.0,
                                    top: 4.0,
                                  ),
                                  child: Text(
                                    '${report['noiseLevel']?.toStringAsFixed(2) ?? 'N/A'} dB',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
