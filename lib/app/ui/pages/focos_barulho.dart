import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class NoiseHotspotsPage extends StatelessWidget {
  Future<List<Map<String, dynamic>>> fetchHotspots() async {
    // Fetch all documents from the 'denuncias' collection.
    final querySnapshot = await FirebaseFirestore.instance
        .collection('denuncias')
        .get();

    // Process each document to calculate a 'score' based on noise levels.
    final hotspots = querySnapshot.docs.map((doc) {
      final data = doc.data();
      // Safely retrieve 'amount' map and individual noise levels.
      final amount = data['amount'] as Map<String, dynamic>?;
      final high = amount?['high'] ?? 0;
      final medium = amount?['medium'] ?? 0;
      final low = amount?['low'] ?? 0;

      // Calculate a weighted score for each hotspot.
      // High noise contributes most, then medium, then low.
      final score = (3 * high) + (2 * medium) + (1 * low);

      // Return a new map including all original data and the calculated score.
      return {...data, 'score': score};
    }).toList();

    // Sort the hotspots by their calculated 'score' in descending order
    // (highest score first).
    hotspots.sort((a, b) => b['score'].compareTo(a['score']));
    return hotspots;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Focos de Barulho',
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
        iconTheme: const IconThemeData(color: Colors.white), // Set back button color to white
      ),
      // Apply a subtle background color to the body.
      body: Container(
        color: Colors.blue.shade50, // Light blue background
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: fetchHotspots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              // Display a prominent error message with an option to retry.
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 50),
                      const SizedBox(height: 10),
                      Text(
                        'Erro ao carregar focos de barulho: ${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: () {
                          // In a StatelessWidget, you'd typically rebuild the parent
                          // or use a state management solution (like GetX) to re-fetch.
                          // For now, this button is purely illustrative.
                          // You might need to wrap FutureBuilder in a StatefulWidget
                          // and call setState to re-trigger the future.
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
              // Display an engaging message when no hotspots are found.
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.location_off, color: Colors.blueGrey, size: 60),
                      const SizedBox(height: 20),
                      const Text(
                        'Nenhum foco de barulho encontrado.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueGrey,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Parece que não há locais com ruídos frequentes registrados ainda.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            final hotspots = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(16.0), // Add padding around the list
              itemCount: hotspots.length,
              itemBuilder: (context, index) {
                final hotspot = hotspots[index];
                // Safely retrieve noise counts
                final amount = hotspot['amount'] as Map<String, dynamic>?;
                final high = amount?['high'] ?? 0;
                final medium = amount?['medium'] ?? 0;
                final low = amount?['low'] ?? 0;

                // Determine color based on score (adjust thresholds as needed)
                Color scoreColor;
                if (hotspot['score'] >= 9) { // Example threshold for high score
                  scoreColor = Colors.red.shade700;
                } else if (hotspot['score'] >= 5) { // Example threshold for medium score
                  scoreColor = Colors.orange.shade700;
                } else {
                  scoreColor = Colors.green.shade700;
                }

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8.0), // Spacing between cards
                  elevation: 5, // Add a subtle shadow
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15.0), // Rounded corners for cards
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.white, Colors.blue.shade50], // Subtle gradient for card background
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
                              const Icon(Icons.campaign, color: Colors.red, size: 28), // Icon for hotspot
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Foco de Barulho',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: Colors.red.shade800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(Icons.location_on, color: Colors.blue, size: 20),
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
                            padding: const EdgeInsets.only(left: 32.0, top: 4.0),
                            child: Text(
                              'Latitude: ${hotspot['latitude']?.toStringAsFixed(6) ?? 'N/A'}',
                              style: const TextStyle(fontSize: 14, color: Colors.black87),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 32.0),
                            child: Text(
                              'Longitude: ${hotspot['longitude']?.toStringAsFixed(6) ?? 'N/A'}',
                              style: const TextStyle(fontSize: 14, color: Colors.black87),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(Icons.star, color: scoreColor, size: 20), // Star icon with score-based color
                              const SizedBox(width: 8),
                              Text(
                                'Pontuação de Ruído:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.blue.shade800,
                                ),
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 32.0, top: 4.0),
                            child: Text(
                              '${hotspot['score']} (Alta: $high, Média: $medium, Baixa: $low)', // Display individual counts
                              style: TextStyle(fontSize: 14, color: scoreColor, fontWeight: FontWeight.bold),
                            ),
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