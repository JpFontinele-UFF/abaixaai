import 'dart:math';

import 'package:abaixaai/app/controller/measurement_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:location/location.dart';
import 'package:permission_handler/permission_handler.dart';

class MeasurementPage extends StatefulWidget {
  @override
  State<MeasurementPage> createState() => _MeasurementPageState();
}

class _MeasurementPageState extends State<MeasurementPage> {
  final MeasurementController controller = Get.put(MeasurementController());
  final Location _location = Location();
  double? latitude;
  double? longitude;

  @override
  void initState() {
    super.initState();
    _requestAudioPermission();
    _getLocation();
  }

  Future<void> _requestAudioPermission() async {
    await Permission.microphone.request();
  }

  Future<void> _getLocation() async {
    final loc = await _location.getLocation();
    setState(() {
      latitude = loc.latitude;
      longitude = loc.longitude;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final gaugeSize = screenWidth < 350 ? screenWidth * 0.7 : 300.0;

    return Scaffold(
      backgroundColor: const Color(0xFF15182B),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Local da Denúncia', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Obx(() {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Medidor
                Container(
                  width: gaugeSize,
                  margin: EdgeInsets.symmetric(horizontal: (screenWidth - gaugeSize) / 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1D38),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16), // Adicione padding interno
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Simulação do velocímetro
                      Obx(() => CustomPaint(
                            size: Size(gaugeSize * 0.66, gaugeSize * 0.4),
                            painter: _GaugePainter(controller.currentDb.value),
                          )),
                      const SizedBox(height: 8),
                      Obx(() => Text(
                            controller.currentDb.value.toInt().toString(),
                            style: TextStyle(
                                fontSize: gaugeSize * 0.21,
                                color: Colors.blue,
                                fontWeight: FontWeight.bold),
                          )),
                      const Text('dB', style: TextStyle(fontSize: 18, color: Colors.blue)),
                      const SizedBox(height: 12),
                      // Simulação do gráfico de linha
                      Obx(() => SizedBox(
                            height: gaugeSize * 0.13,
                            width: gaugeSize * 0.66,
                            child: CustomPaint(
                              painter: _LineChartPainter(controller.dbValues.toList()),
                            ),
                          )),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Column(
                            children: [
                              const Text('min', style: TextStyle(color: Colors.blue)),
                              Obx(() => Text(controller.minDb.value.toInt().toString(), style: const TextStyle(color: Colors.white))),
                            ],
                          ),
                          Column(
                            children: [
                              const Text('avg', style: TextStyle(color: Colors.blue)),
                              Obx(() => Text(controller.avgDb.value.toInt().toString(), style: const TextStyle(color: Colors.white))),
                            ],
                          ),
                          Column(
                            children: [
                              const Text('max', style: TextStyle(color: Colors.blue)),
                              Obx(() => Text(controller.maxDb.value.toInt().toString(), style: const TextStyle(color: Colors.white))),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    minimumSize: const Size(220, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () async {
                    if (!controller.isRecording.value) {
                      if (await Permission.microphone.isGranted) {
                        controller.startRecording();
                      } else {
                        await Permission.microphone.request();
                        if (await Permission.microphone.isGranted) {
                          controller.startRecording();
                        } else {
                          Get.snackbar("Permissão", "Permissão de microfone negada!", backgroundColor: Colors.red, colorText: Colors.white);
                        }
                      }
                    } else {
                      controller.stopRecording();
                      if (latitude != null && longitude != null) {
                        await controller.saveMeasurement(latitude: latitude!, longitude: longitude!);
                        Get.snackbar("Denúncia", "Denúncia salva com sucesso!", backgroundColor: Colors.green, colorText: Colors.white);
                      }
                    }
                  },
                  child: Text(
                    controller.isRecording.value ? "Salvar denúncia" : "Gravar ruído",
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

// Gauge painter (velocímetro)
class _GaugePainter extends CustomPainter {
  final double value;
  _GaugePainter(this.value);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke;
    final center = Offset(size.width / 2, size.height);
    final radius = size.width / 2;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), 3.14, 3.14, false, paint);

    // Ponteiro
    final angle = pi + (1 - value.clamp(0, 100) / 100) * pi;
    final pointerLength = radius - 20;
    final pointerEnd = Offset(
    center.dx - pointerLength * cos(angle),
    center.dy + pointerLength * sin(angle),
    );
    final pointerPaint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 8;
    canvas.drawLine(center, pointerEnd, pointerPaint);
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) => oldDelegate.value != value;
}

// Linha do gráfico
class _LineChartPainter extends CustomPainter {
  final List<double> values;
  _LineChartPainter(this.values);

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final Paint paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2;
    final double maxValue = values.reduce((a, b) => a > b ? a : b);
    final double minValue = values.reduce((a, b) => a < b ? a : b);
    final double range = (maxValue - minValue).abs() < 1 ? 1 : (maxValue - minValue);

    for (int i = 0; i < values.length - 1; i++) {
      final x1 = i * size.width / (values.length - 1);
      final y1 = size.height - ((values[i] - minValue) / range) * size.height;
      final x2 = (i + 1) * size.width / (values.length - 1);
      final y2 = size.height - ((values[i + 1] - minValue) / range) * size.height;
      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) => oldDelegate.values != values;
}
