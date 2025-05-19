import 'dart:async';
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

  Future<bool> _checkPermission() async => await Permission.microphone.isGranted;
  Future<void> _requestPermission() async => await Permission.microphone.request();

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

  Future<void> saveMeasurement({required double latitude, required double longitude}) async {
    await FirebaseFirestore.instance.collection('denuncias').add({
      'min': minDb.value,
      'max': maxDb.value,
      'avg': avgDb.value,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': DateTime.now(),
    });
  }
}