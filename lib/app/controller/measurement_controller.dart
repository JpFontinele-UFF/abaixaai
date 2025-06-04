import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:noise_meter/noise_meter.dart';
import 'package:permission_handler/permission_handler.dart';

class MeasurementController extends GetxController {
  NoiseMeter? _noiseMeter;
  StreamSubscription<NoiseReading>? _noiseSubscription;

  RxBool isRecording = false.obs;
  RxDouble currentDb = 0.0.obs;
  RxList<double> dbValues = <double>[].obs;
  RxDouble minDb = 0.0.obs;
  RxDouble maxDb = 0.0.obs;
  RxDouble avgDb = 0.0.obs;

  @override
  void onClose() {
    _noiseSubscription?.cancel();
    super.onClose();
  }

  Future<bool> _checkPermission() async =>
      await Permission.microphone.isGranted;
  Future<void> _requestPermission() async =>
      await Permission.microphone.request();

  void _onData(NoiseReading noiseReading) {
    currentDb.value = noiseReading.meanDecibel;
    dbValues.add(noiseReading.meanDecibel);
    minDb.value = dbValues.reduce((a, b) => a < b ? a : b);
    maxDb.value = dbValues.reduce((a, b) => a > b ? a : b);
    avgDb.value = dbValues.reduce((a, b) => a + b) / dbValues.length;
    update();
  }

  void _onError(Object error) {
    stopRecording();
  }

  Future<void> startRecording() async {
    dbValues.clear();
    isRecording.value = true;
    minDb.value = 0.0;
    maxDb.value = 0.0;
    avgDb.value = 0.0;

    if (!(await _checkPermission())) await _requestPermission();

    _noiseMeter ??= NoiseMeter();
    _noiseSubscription = _noiseMeter!.noise.listen(_onData, onError: _onError);
    update();
  }

  Future<void> stopRecording() async {
    isRecording.value = false;
    await _noiseSubscription?.cancel();
    _noiseSubscription = null;
    update();
  }

  Future<List<Map<String, dynamic>>> fetchMeasurements() async {
    final querySnapshot =
        await FirebaseFirestore.instance.collection('denuncias').get();
    return querySnapshot.docs.map((doc) => doc.data()).toList();
  }

  Future<void> saveMeasurement({
    required double latitude,
    required double longitude,
  }) async {
    final denunciasCollection = FirebaseFirestore.instance.collection(
      'denuncias',
    );

    final querySnapshot = await denunciasCollection.get();
    bool isWithinRange = false;
    String? parentDocId;
    int low = 0;
    int medium = 0;
    int high = 0;

    for (var doc in querySnapshot.docs) {
      if (avgDb.value < 40) {
        low = 1;
      } else if (avgDb.value < 80) {
        medium = 1;
      } else {
        high = 1;
      }

      final data = doc.data();
      final existingLatitude = data['latitude'] as double?;
      final existingLongitude = data['longitude'] as double?;

      if (existingLatitude != null && existingLongitude != null) {
        final distance = _calculateDistance(
          latitude,
          longitude,
          existingLatitude,
          existingLongitude,
        );

        if (distance <= 50) {
          isWithinRange = true;
          parentDocId = doc.id;
          break;
        }
      }
    }

    if (isWithinRange && parentDocId != null) {
      final docSnapshot = await denunciasCollection.doc(parentDocId).get();

      // Obtém os valores de min, max e avg
      final currentData = docSnapshot.data() ?? {};
      double currentMin = currentData['min'] ?? 0;
      double currentMax = currentData['max'] ?? 0;
      double currentAvg = currentData['avg'] ?? 0;

      final currentAmount = docSnapshot.data()?['amount'] ?? {};
      int currentLow = currentAmount['low'] ?? 0;
      int currentMedium = currentAmount['medium'] ?? 0;
      int currentHigh = currentAmount['high'] ?? 0;

      int total =
          currentLow + low + currentMedium + medium + currentHigh + high;

      double newMin = (currentMin + minDb.value) / total;
      double newMax = (currentMax + maxDb.value) / total;
      double newAvg = (currentAvg + avgDb.value) / total;

      //Guarda a nova denuncia na sub_denuncia
      await denunciasCollection
          .doc(parentDocId)
          .collection('sub_denuncias')
          .add({
            'min': minDb.value,
            'max': maxDb.value,
            'avg': avgDb.value,
            'latitude': latitude,
            'longitude': longitude,
            'timestamp': DateTime.now(),
            'createdAt': '',
          });

      //Atualiza a denuncia principal
      await denunciasCollection.doc(parentDocId).update({
        'min': newMin,
        'max': newMax,
        'avg': newAvg,
        'timestamp': DateTime.now(),
        'amount': {
          'low': currentLow + low,
          'medium': currentMedium + medium,
          'high': currentHigh + high,
        },
      });
    } else {
      // Se não houver denúncia dentro do raio, cria uma nova
      await denunciasCollection.add({
        'min': minDb.value,
        'max': maxDb.value,
        'avg': avgDb.value,
        'latitude': latitude,
        'longitude': longitude,
        'timestamp': DateTime.now(),
        'createdAt': '',
        'amount': {'low': low, 'medium': medium, 'high': high},
      });

      // Adiciona a sub_denuncia na nova denúncia
      await denunciasCollection
          .doc(parentDocId)
          .collection('sub_denuncias')
          .add({
            'min': minDb.value,
            'max': maxDb.value,
            'avg': avgDb.value,
            'latitude': latitude,
            'longitude': longitude,
            'timestamp': DateTime.now(),
            'createdAt': '',
          });
    }
  }

  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadius = 6371e3;
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);

    final a =
        (sin(dLat / 2) * sin(dLat / 2)) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            (sin(dLon / 2) * sin(dLon / 2));
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) => degrees * (pi / 180);
}
