import 'dart:async';
import 'dart:math';
import 'package:abaixaai/app/controller/measurement_controller.dart';
import 'package:abaixaai/app/data/service/global_variables.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:location/location.dart';
import 'package:permission_handler/permission_handler.dart';

class MeasurementPage extends StatefulWidget {
  const MeasurementPage({super.key});

  @override
  State<MeasurementPage> createState() => _MeasurementPageState();
}

class _MeasurementPageState extends State<MeasurementPage> {
  final MeasurementController controller = Get.put(MeasurementController());
  final Location _location = Location();
  double? latitude;
  double? longitude;
  bool isAnonymous = false;
  int countdown = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _getLocation();
  }

  @override
  void dispose() {
    _resetState();
    super.dispose();
  }

  void _resetState() {
    countdown = 0;
    _timer?.cancel();
    controller.isRecording.value = false;
    controller.currentDb.value = 0;
    controller.dbValues.clear();
    controller.minDb.value = 0;
    controller.maxDb.value = 0;
    controller.avgDb.value = 0;
  }

  Future<void> _getLocation() async {
    final loc = await _location.getLocation();
    setState(() {
      latitude = loc.latitude;
      longitude = loc.longitude;
    });
  }

  Future<void> _showMicrophoneInfoDialog() async {
    await Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF1A1D38),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          "Por que precisamos do microfone?",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "Precisamos de acesso ao microfone para medir os níveis de ruído (decibéis) na sua área e assim contribuir com o combate à poluição sonora.",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            child: const Text("Entendi", style: TextStyle(color: Colors.blue)),
            onPressed: () => Get.back(),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  void _startCountdown() async {
    setState(() {
      countdown = GlobalVariables.RECORDINGTIME;
    });
    // Inicia a gravação imediatamente para feedback visual
    controller.startRecording();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (countdown > 1) {
        setState(() {
          countdown--;
        });
      } else {
        timer.cancel();
        setState(() {
          countdown = 0;
        });
        // Para a gravação ao final do contador, permitindo salvar denúncia
        controller.stopRecording();
        controller.isRecording.value = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final gaugeSize = screenWidth < 350 ? screenWidth * 0.7 : 300.0;

    return Scaffold(
      backgroundColor: const Color(0xFF15182B),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Local da Denúncia',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Obx(() {
        return SafeArea(
          child: Center(
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Medidor
                  Container(
                    width: gaugeSize,
                    margin: EdgeInsets.symmetric(
                      horizontal: (screenWidth - gaugeSize) / 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1D38),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Gauge
                        Obx(
                          () => CustomPaint(
                            size: Size(gaugeSize * 0.66, gaugeSize * 0.4),
                            painter: _GaugePainter(controller.currentDb.value),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Obx(
                          () => Text(
                            controller.currentDb.value.isFinite
                                ? controller.currentDb.value.toInt().toString()
                                : '0', // Valor padrão para casos inválidos
                            style: TextStyle(
                              fontSize: gaugeSize * 0.21,
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Text(
                          'dB',
                          style: TextStyle(fontSize: 18, color: Colors.blue),
                        ),
                        const SizedBox(height: 12),
                        Obx(
                          () => SizedBox(
                            height: gaugeSize * 0.13,
                            width: gaugeSize * 0.66,
                            child: CustomPaint(
                              painter: _LineChartPainter(
                                controller.dbValues.toList(),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Column(
                              children: [
                                const Text(
                                  'min',
                                  style: TextStyle(color: Colors.blue),
                                ),
                                Obx(
                                  () => Text(
                                    controller.minDb.value.toInt().toString(),
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              children: [
                                const Text(
                                  'avg',
                                  style: TextStyle(color: Colors.blue),
                                ),
                                Obx(
                                  () => Text(
                                    controller.avgDb.value.toInt().toString(),
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              children: [
                                const Text(
                                  'max',
                                  style: TextStyle(color: Colors.blue),
                                ),
                                Obx(
                                  () => Text(
                                    controller.maxDb.value.toInt().toString(),
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Checkbox para anonimato
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Checkbox(
                        value: isAnonymous,
                        onChanged: (value) {
                          setState(() {
                            isAnonymous = value ?? false;
                          });
                        },
                      ),
                      const Text(
                        "Anônimo?",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          (countdown > 0) ? Colors.grey : Colors.blue,
                      minimumSize: const Size(220, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed:
                        (countdown > 0)
                            ? null
                            : () async {
                              if (!controller.isRecording.value) {
                                await _showMicrophoneInfoDialog();

                                if (await Permission.microphone.isGranted) {
                                  _startCountdown();
                                } else {
                                  await Permission.microphone.request();
                                  if (await Permission.microphone.isGranted) {
                                    _startCountdown();
                                  } else {
                                    Get.snackbar(
                                      "Permissão",
                                      "Permissão de microfone negada!",
                                      backgroundColor: Colors.red,
                                      colorText: Colors.white,
                                    );
                                  }
                                }
                              } else {
                                controller.stopRecording();
                                if (latitude != null && longitude != null) {
                                  final userEmail =
                                      isAnonymous
                                          ? "anonimo"
                                          : FirebaseAuth
                                              .instance
                                              .currentUser
                                              ?.email;
                                  if (userEmail != null) {
                                    await controller.saveMeasurement(
                                      latitude: latitude!,
                                      longitude: longitude!,
                                      userEmail: userEmail,
                                    );
                                    Get.snackbar(
                                      "Denúncia",
                                      "Denúncia salva com sucesso!",
                                      backgroundColor: Colors.green,
                                      colorText: Colors.white,
                                    );
                                    setState(() {
                                      _resetState();
                                    });
                                  } else {
                                    Get.snackbar(
                                      "Erro",
                                      "Usuário não está logado!",
                                      backgroundColor: Colors.red,
                                      colorText: Colors.white,
                                    );
                                  }
                                }
                              }
                            },
                    child:
                        (countdown > 0)
                            ? Text(
                              "Gravando em $countdown...",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                            : Text(
                              controller.isRecording.value
                                  ? "Salvar denúncia"
                                  : "Gravar ruído",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                  ),
                ],
              ),
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
    final Paint paint =
        Paint()
          ..color = Colors.blue
          ..strokeWidth = 6
          ..style = PaintingStyle.stroke;
    final center = Offset(size.width / 2, size.height);
    final radius = size.width / 2;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      pi,
      pi,
      false,
      paint,
    );

    final angle = pi + (1 - value.clamp(0, 100) / 100) * pi;
    final pointerLength = radius - 20;
    final pointerEnd = Offset(
      center.dx - pointerLength * cos(angle),
      center.dy + pointerLength * sin(angle),
    );
    final pointerPaint =
        Paint()
          ..color = Colors.blue
          ..strokeWidth = 8;
    canvas.drawLine(center, pointerEnd, pointerPaint);
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) =>
      oldDelegate.value != value;
}

// Linha do gráfico
class _LineChartPainter extends CustomPainter {
  final List<double> values;
  _LineChartPainter(this.values);

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty || values.any((v) => !v.isFinite))
      return; // Proteção contra valores inválidos
    final Paint paint =
        Paint()
          ..color = Colors.blue
          ..strokeWidth = 2;
    final double maxValue = values.reduce(max);
    final double minValue = values.reduce(min);
    final double range =
        (maxValue - minValue).abs() < 1 ? 1 : (maxValue - minValue);

    for (int i = 0; i < values.length - 1; i++) {
      final x1 = i * size.width / (values.length - 1);
      final y1 = size.height - ((values[i] - minValue) / range) * size.height;
      final x2 = (i + 1) * size.width / (values.length - 1);
      final y2 =
          size.height - ((values[i + 1] - minValue) / range) * size.height;
      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) =>
      oldDelegate.values != values;
}
